extends Node
class_name PlayerStateMachine

# --- 1. DEFINITIONS ---
enum MoveState { IDLE, RUN, AIR, DEATH }
enum ActionState { NONE, ATTACK }

var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

var player: PlayerController
var jump_buffer_timer: float = 0.0
var has_hit_target: bool = false 

# --- 2. SETUP ---
func init(parent: PlayerController) -> void:
	player = parent
	
	# Connect to VIEW signals (Visuals & Input)
	player.view.sprite.animation_finished.connect(_on_animation_finished)
	
	# Jump Buffer Input
	player.view.jump_pressed.connect(func(): jump_buffer_timer = 0.1)
	
	# Variable Jump Height
	player.view.jump_released.connect(func(): 
		if player.velocity.y < 0: player.velocity.y *= 0.5
	)
	
	# Attack Input
	player.view.attack_requested.connect(func():
		if current_action_state == ActionState.NONE:
			change_action_state(ActionState.ATTACK)
	)

# --- 3. INPUT HANDLING ---
func input_update(_event: InputEvent) -> void:
	# Block input if Dead
	if current_move_state == MoveState.DEATH:
		return
	# Most input is now handled via signals in init(), 
	# but we keep this hook for consistency.

# --- 4. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	# Decrement Timers
	if jump_buffer_timer > 0: jump_buffer_timer -= delta

	# UPDATE LAYER 1: MOVEMENT
	match current_move_state:
		MoveState.IDLE:  _move_idle(delta)
		MoveState.RUN:   _move_run(delta)
		MoveState.AIR:   _move_air(delta)
		MoveState.DEATH: _move_death(delta)
		
	# UPDATE LAYER 2: ACTION
	if current_move_state != MoveState.DEATH:
		match current_action_state:
			ActionState.NONE:   _action_none(delta)
			ActionState.ATTACK: _action_attack(delta)
	
	# RESOLVE ANIMATIONS
	_resolve_animation()

# ==============================================================================
# LAYER 1: MOVEMENT LOGIC
# ==============================================================================

func change_move_state(new_state: MoveState) -> void:
	current_move_state = new_state
	
	match new_state:
		MoveState.AIR:
			if player.velocity.y >= 0: 
				player.coyote_timer.start()
		
		MoveState.DEATH:
			current_action_state = ActionState.NONE
			player.velocity.x = 0 

func _move_idle(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_movement_input(player.get_move_speed())
	
	if not player.is_on_floor():
		change_move_state(MoveState.AIR)
		return
	
	# Use Controller's stored input direction
	if player._current_input_dir != 0:
		change_move_state(MoveState.RUN)
		return

	_check_jump_start()

func _move_run(delta: float) -> void:
	player.apply_gravity(delta)
	var speed = player.get_move_speed()
	if current_action_state == ActionState.ATTACK:
		speed *= 0.5
	
	player.handle_movement_input(speed)
	
	if not player.is_on_floor():
		change_move_state(MoveState.AIR)
		return
		
	if player._current_input_dir == 0:
		change_move_state(MoveState.IDLE)
		return

	_check_jump_start()

func _move_air(delta: float) -> void:
	player.apply_gravity(delta)
	var speed = player.get_move_speed()
	if current_action_state == ActionState.ATTACK:
		speed *= 0.8
		
	player.handle_movement_input(speed)

	if player.is_on_floor():
		if player._current_input_dir != 0:
			change_move_state(MoveState.RUN)
		else:
			change_move_state(MoveState.IDLE)
		return
	
	if jump_buffer_timer > 0 and not player.coyote_timer.is_stopped():
		_perform_jump()

func _move_death(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0, 500 * delta)

# --- HELPERS ---

func _check_jump_start():
	if jump_buffer_timer > 0 and player.is_on_floor():
		_perform_jump()

func _perform_jump():
	player.velocity.y = player.get_jump_force()
	jump_buffer_timer = 0.0
	player.coyote_timer.stop()
	change_move_state(MoveState.AIR)

# ==============================================================================
# LAYER 2: ACTION LOGIC
# ==============================================================================

func change_action_state(new_state: ActionState) -> void:
	current_action_state = new_state
	match new_state:
		ActionState.ATTACK:
			has_hit_target = false
			player.view.play_anim("attack") # Visuals via View
		ActionState.NONE:
			pass

func _action_none(_delta: float) -> void:
	# No specific logic for idle action, but function must exist
	pass

func _action_attack(_delta: float) -> void:
	# Check frame via View's sprite
	if player.view.sprite.frame == 2 and not has_hit_target:
		player.deal_damage_in_hitbox()
		has_hit_target = true

	if not player.view.sprite.is_playing() or player.view.sprite.animation != "attack":
		change_action_state(ActionState.NONE)

# ==============================================================================
# VISUAL RESOLVER & EVENTS
# ==============================================================================

func _resolve_animation() -> void:
	# Death overrides everything
	if current_move_state == MoveState.DEATH:
		if player.view.get_current_animation() != "death":
			player.view.play_anim("death")
		return

	# Attacks override movement animations
	if current_action_state == ActionState.ATTACK:
		# Animation is started in change_action_state
		return

	# Movement animations
	match current_move_state:
		MoveState.IDLE: player.view.play_anim("idle")
		MoveState.RUN:  player.view.play_anim("run")
		MoveState.AIR:
			if player.velocity.y < 0:
				player.view.play_anim("jump")
			elif player.view.sprite.sprite_frames.has_animation("fall"):
				player.view.play_anim("fall")

func _on_animation_finished():
	if player.view.get_current_animation() == "death":
		print("💀 Death Animation Complete. Emitting Signal.")
		player.player_died.emit()
