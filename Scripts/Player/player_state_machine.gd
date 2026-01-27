extends Node
class_name PlayerStateMachine

# --- 1. DEFINITIONS ---
enum MoveState { IDLE, RUN, AIR }
enum ActionState { NONE, ATTACK }

var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

var player: PlayerController
var jump_buffer_timer: float = 0.0
var has_hit_target: bool = false # Ensures we only hit once per swing

# --- 2. SETUP ---
func init(parent: PlayerController) -> void:
	player = parent

# --- 3. INPUT HANDLING ---
func input_update(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer_timer = 0.1
	
	# Variable Jump Height
	if event.is_action_released("jump") and player.velocity.y < 0:
		player.velocity.y *= 0.5

	# Attack Input
	if current_action_state == ActionState.NONE:
		if event.is_action_pressed("base_attack"):
			change_action_state(ActionState.ATTACK)

# --- 4. PHYSICS LOOP ---
func physics_update(delta: float) -> void:
	# Decrement Timers
	if jump_buffer_timer > 0: jump_buffer_timer -= delta

	# UPDATE LAYER 1: MOVEMENT
	match current_move_state:
		MoveState.IDLE: _move_idle(delta)
		MoveState.RUN:  _move_run(delta)
		MoveState.AIR:  _move_air(delta)
		
	# UPDATE LAYER 2: ACTION
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
			# Coyote Time: If falling without jumping, start timer
			if player.velocity.y >= 0: 
				player.coyote_timer.start()

func _move_idle(delta: float) -> void:
	player.apply_gravity(delta)
	
	# Apply friction to stop
	player.handle_movement_input(player.get_move_speed())
	
	# Transitions
	if not player.is_on_floor():
		change_move_state(MoveState.AIR)
		return
	
	if Input.get_axis("move_left", "move_right") != 0:
		change_move_state(MoveState.RUN)
		return

	_check_jump_start()

func _move_run(delta: float) -> void:
	player.apply_gravity(delta)
	
	# Calculate Speed
	var speed = player.get_move_speed()
	
	# Slow down if attacking
	if current_action_state == ActionState.ATTACK:
		speed *= 0.5
	
	player.handle_movement_input(speed)
	
	# Transitions
	if not player.is_on_floor():
		change_move_state(MoveState.AIR)
		return
		
	if Input.get_axis("move_left", "move_right") == 0:
		change_move_state(MoveState.IDLE)
		return

	_check_jump_start()

func _move_air(delta: float) -> void:
	player.apply_gravity(delta)
	
	# Air Control
	var speed = player.get_move_speed()
	if current_action_state == ActionState.ATTACK:
		speed *= 0.8 # Less control in air while attacking
		
	player.handle_movement_input(speed)

	# Transitions
	if player.is_on_floor():
		if Input.get_axis("move_left", "move_right") != 0:
			change_move_state(MoveState.RUN)
		else:
			change_move_state(MoveState.IDLE)
		return
	
	# Coyote Jump Logic
	if jump_buffer_timer > 0 and not player.coyote_timer.is_stopped():
		_perform_jump()

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
			# We do NOT enable collision here. We wait for the frame.
		ActionState.NONE:
			pass

func _action_none(_delta: float) -> void:
	# Passive state waiting for input
	pass

func _action_attack(_delta: float) -> void:
	# 1. Damage Logic (Sync with Animation Frame)
	# Check Frame 2 (Adjust this number based on your specific animation!)
	if player.sprite.frame == 2 and not has_hit_target:
		player.deal_damage_in_hitbox()
		has_hit_target = true

	# 2. End Logic
	# If animation finished OR changed unexpectedly
	if not player.sprite.is_playing() or player.sprite.animation != "attack":
		change_action_state(ActionState.NONE)

# ==============================================================================
# VISUAL RESOLVER
# ==============================================================================

func _resolve_animation() -> void:
	# Rule 1: Attacks usually override everything
	if current_action_state == ActionState.ATTACK:
		if player.sprite.animation != "attack":
			player.sprite.play("attack")
		return

	# Rule 2: If not attacking, Movement State dictates animation
	match current_move_state:
		MoveState.IDLE:
			player.sprite.play("idle")
		
		MoveState.RUN:
			player.sprite.play("run")
		
		MoveState.AIR:
			if player.velocity.y < 0:
				player.sprite.play("jump")
			elif player.sprite.sprite_frames.has_animation("fall"):
				player.sprite.play("fall")
