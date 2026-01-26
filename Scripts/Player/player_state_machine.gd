extends Node
class_name PlayerStateMachine

# --- 1. DEFINITIONS ---
# Layer 1: Movement (Exclusive states for position/physics)
enum MoveState {
	IDLE,
	RUN,
	AIR
}

# Layer 2: Actions (Exclusive states for combat/interaction)
enum ActionState {
	NONE,
	ATTACK
}

var current_move_state: MoveState = MoveState.IDLE
var current_action_state: ActionState = ActionState.NONE

var player: PlayerController
var jump_buffer_timer: float = 0.0

# --- 2. SETUP ---
func init(parent: PlayerController) -> void:
	player = parent

# --- 3. INPUT HANDLING ---
func input_update(event: InputEvent) -> void:
	# -- Movement Inputs --
	if event.is_action_pressed("jump"):
		jump_buffer_timer = 0.1
	
	# Variable Jump Height (Cutting the jump short)
	if event.is_action_released("jump") and player.velocity.y < 0:
		player.velocity.y *= 0.5

	# -- Action Inputs --
	# Only allow starting an attack if we aren't already doing one
	if current_action_state == ActionState.NONE:
		if event.is_action_pressed("base_attack"):
			change_action_state(ActionState.ATTACK)

# --- 4. PHYSICS LOOP (The Heartbeat) ---
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
		ActionState.NONE:  _action_none(delta)
		ActionState.ATTACK: _action_attack(delta)
	
	# RESOLVE ANIMATIONS
	# Since two layers might want to play animations, we decide who wins here.
	_resolve_animation()

# ==============================================================================
# LAYER 1: MOVEMENT LOGIC
# ==============================================================================

func change_move_state(new_state: MoveState) -> void:
	current_move_state = new_state
	
	# Enter Logic (Optional specific setup)
	match new_state:
		MoveState.AIR:
			# If we just entered air and fell (didn't jump), start coyote time
			if player.velocity.y >= 0: 
				player.coyote_timer.start()

func _move_idle(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0, player.get_move_speed())
	
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
	
	# CROSS-LAYER INTERACTION:
	# If we are attacking, maybe we move slower? (e.g., 50% speed)
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
		speed *= 0.8 # Slightly less control in air while attacking?
		
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
			# Start Attack
			player.sprite.play("attack")
			player.weapon_area.monitoring = true
		ActionState.NONE:
			# End Attack
			player.weapon_area.monitoring = false

func _action_none(_delta: float) -> void:
	# Just waiting for input (handled in input_update)
	pass

func _action_attack(_delta: float) -> void:
	# Wait for animation to finish
	if not player.sprite.is_playing() or player.sprite.animation != "attack":
		change_action_state(ActionState.NONE)

# ==============================================================================
# VISUAL RESOLVER
# ==============================================================================

func _resolve_animation() -> void:
	# Rule 1: Attacks usually override everything
	if current_action_state == ActionState.ATTACK:
		# If the sprite is already playing "attack", don't interrupt it
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
