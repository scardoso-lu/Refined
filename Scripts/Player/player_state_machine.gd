extends Node
class_name PlayerStateMachine

# --- 1. DEFINITIONS ---
# ### UPDATED: Added DEATH state
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
	# ### NEW: Connect the animation finished signal once here
	# We will check the animation name inside the function
	player.sprite.animation_finished.connect(_on_animation_finished)

# --- 3. INPUT HANDLING ---
func input_update(event: InputEvent) -> void:
	# ### NEW: Block all input if Dead
	if current_move_state == MoveState.DEATH:
		return

	if event.is_action_pressed("jump"):
		jump_buffer_timer = 0.1
	
	if event.is_action_released("jump") and player.velocity.y < 0:
		player.velocity.y *= 0.5

	if current_action_state == ActionState.NONE:
		if event.is_action_pressed("base_attack"):
			change_action_state(ActionState.ATTACK)

# --- 4. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	# Decrement Timers
	if jump_buffer_timer > 0: jump_buffer_timer -= delta

	# UPDATE LAYER 1: MOVEMENT
	match current_move_state:
		MoveState.IDLE:  _move_idle(delta)
		MoveState.RUN:   _move_run(delta)
		MoveState.AIR:   _move_air(delta)
		MoveState.DEATH: _move_death(delta) # ### NEW
		
	# UPDATE LAYER 2: ACTION
	# ### UPDATED: Don't run action logic if dead
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
		
		# ### NEW: When entering Death, force stop actions
		MoveState.DEATH:
			current_action_state = ActionState.NONE
			player.velocity.x = 0 # Stop sliding immediately (optional)

func _move_idle(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_movement_input(player.get_move_speed())
	
	if not player.is_on_floor():
		change_move_state(MoveState.AIR)
		return
	
	if Input.get_axis("move_left", "move_right") != 0:
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
		
	if Input.get_axis("move_left", "move_right") == 0:
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
		if Input.get_axis("move_left", "move_right") != 0:
			change_move_state(MoveState.RUN)
		else:
			change_move_state(MoveState.IDLE)
		return
	
	if jump_buffer_timer > 0 and not player.coyote_timer.is_stopped():
		_perform_jump()

# ### NEW FUNCTION: Handles physics while dying
func _move_death(delta: float) -> void:
	# We still apply gravity so if they die in the air, they fall to the floor
	player.apply_gravity(delta)
	
	# Apply heavy friction to stop them from sliding
	player.velocity.x = move_toward(player.velocity.x, 0, 500 * delta)
	player.move_and_slide()

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
			player.sprite.play("attack")
		ActionState.NONE:
			pass

func _action_none(_delta: float) -> void:
	pass

func _action_attack(_delta: float) -> void:
	if player.sprite.frame == 2 and not has_hit_target:
		player.deal_damage_in_hitbox()
		has_hit_target = true

	if not player.sprite.is_playing() or player.sprite.animation != "attack":
		change_action_state(ActionState.NONE)

# ==============================================================================
# VISUAL RESOLVER & EVENTS
# ==============================================================================

func _resolve_animation() -> void:
	# ### NEW: Death overrides EVERYTHING
	if current_move_state == MoveState.DEATH:
		if player.sprite.animation != "death":
			player.sprite.play("death")
		return

	# Rule 1: Attacks
	if current_action_state == ActionState.ATTACK:
		if player.sprite.animation != "attack":
			player.sprite.play("attack")
		return

	# Rule 2: Movement
	match current_move_state:
		MoveState.IDLE: player.sprite.play("idle")
		MoveState.RUN:  player.sprite.play("run")
		MoveState.AIR:
			if player.velocity.y < 0:
				player.sprite.play("jump")
			elif player.sprite.sprite_frames.has_animation("fall"):
				player.sprite.play("fall")

# ### NEW: Signal Listener
func _on_animation_finished():
	# Only care if the finished animation was DEATH
	if player.sprite.animation == "death":
		print("💀 Death Animation Complete. Emitting Signal.")
		# Tell the PlayerController we are fully dead
		player.player_died.emit()
