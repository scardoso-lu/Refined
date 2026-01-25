extends CharacterBody2D

signal health_changed(new_amount)


# 1. Add this EXPORT variable. It appears in the Editor Inspector.
@export_group("Debugging")
@export var debug_character: CharacterDef

# --- Configuration ---
# The data container. If null, we use defaults.
var _stats: CharacterDef 

# --- Nodes ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var weapon_area = $WeaponArea

# --- PLAYER VARIABLES that changes the UI---
var is_attacking: bool = false
@export var damage: int = 20
@export var max_health: int = 100
var current_health: int

# --- Physics State ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _jump_buffer_timer: float = 0.0

func _ready():
	pass

# --- 1. SETUP: The Data Injection ---
func setup_character(def: CharacterDef) -> void:
	print("✅ setup_character called with: ", def) # <--- Add this
	_stats = def
	
	max_health = _stats.max_health
	current_health = _stats.current_health
	
	print("--- PLAYER DEBUG ---")
	print("Player Layer Value: ", collision_layer)
	
	# THIS is where the real initialization happens
	if _stats.sprite_frames:
		sprite.sprite_frames = _stats.sprite_frames
		# Now it is safe to play, because we know the resource is loaded
		sprite.play("idle")
	
	# Apply Hitbox Size (Optional)
	# This ensures a big Golem has a bigger box than a small Thief
	if collider.shape is RectangleShape2D:
		collider.shape.size = def.collider_size
	elif collider.shape is CapsuleShape2D:
		# If using Capsule, we split the Vector2 into Radius (X) and Height (Y)
		collider.shape.radius = def.collider_size.x / 2.0
		collider.shape.height = def.collider_size.y


# --- 2. LOOP: The Game Logic ---
func _physics_process(delta: float) -> void:
	# 1. Block movement if attacking (optional style choice)
	_handle_gravity(delta)
	_handle_jump(delta)
	_handle_movement(delta)
	if not is_attacking:
		_update_animations()
	
	move_and_slide()

# --- 3. LOGIC: Broken down into small functions ---

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		# Apply gravity
		velocity.y += gravity * delta

func _handle_jump(delta: float) -> void:
	# Get stats or defaults
	var jump_force = _stats.jump_velocity if _stats else -400.0
	
	# Buffer Input
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = 0.1
	
	if _jump_buffer_timer > 0:
		_jump_buffer_timer -= delta
	
	# Check for Jump (Floor OR Coyote Time)
	if _jump_buffer_timer > 0 and (is_on_floor() or not coyote_timer.is_stopped()):
		velocity.y = jump_force
		_jump_buffer_timer = 0.0
		coyote_timer.stop()

	# Variable Jump Height (Short hop vs High jump)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func _handle_movement(_delta: float) -> void:
	var speed = _stats.speed if _stats else 300.0
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Handle Coyote Time start
	var was_on_floor = is_on_floor()
	# (Logic continues after move_and_slide, but for simple scripts 
	#  we often handle the trigger check here or in the main process loop)
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		coyote_timer.start()
	
	# ------------- FLIP ATTACK -----------
	# if your Player turns Left, the WeaponArea needs to flip too.
	if direction < 0:
		sprite.flip_h = true
		# Flip Hitbox to Left
		weapon_area.position.x = -abs(weapon_area.position.x)
	elif direction > 0:
		sprite.flip_h = false
		# Flip Hitbox to Right
		weapon_area.position.x = abs(weapon_area.position.x)

# --- 4. VISUALS: The Smart Animation Handler ---
func _update_animations() -> void:
	# SAFETY CHECK:
	# If setup_character() hasn't run yet, stop here.
	# This prevents "Animation not found" errors during the first split-second of loading.
	if not _stats or not sprite.sprite_frames:
		return
	var direction := Input.get_axis("move_left", "move_right")
	
	if is_on_floor():
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")
	else:
		if velocity.y < 0:
			sprite.play("jump")
		else:
			# SAFE CHECK:
			# If the loaded character has a "fall" animation, use it.
			# If not (e.g. you only have jump.png), keep playing "jump".
			if sprite.sprite_frames.has_animation("fall"):
				sprite.play("fall")
			else:
				sprite.play("jump")


# Add this new function
func take_damage(amount: int):
	current_health -= amount
	print("Ouch! Player took ", amount, " damage. HP Left: ", current_health)
	
	# Optional: Play a "Hurt" animation, add knock back
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	# EMIT THE SIGNAL!
	health_changed.emit(current_health)
	
	if current_health <= 0:
		die()

func die():
	print("Player Died!")
	weapon_area.monitoring = false
	is_attacking = false
	# Reload scene or show Game Over screen
	get_tree().reload_current_scene()

func _input(event):
	# Check for "base_attack" (1, 2 ,3 your choice) or a custom "attack" action
	if event.is_action_pressed("base_attack") and not is_attacking:
		attack()

func attack():
	is_attacking = true
	sprite.play("attack")
	
	# Turn on hitbox
	weapon_area.monitoring = true
	
	# WAIT for the animation
	# We use a manual signal connection which is safer than 'await' for logic flow
	await sprite.animation_finished
	
	_end_attack()
	
func _end_attack():
	# Reset everything
	weapon_area.monitoring = false
	is_attacking = false
	sprite.play("idle")
	
# --- DEALING DAMAGE ---
# Connect the "body_entered" signal of WeaponArea to the Player Script!
func _on_weapon_area_body_entered(body):
	if body == self:
			return # Don't hit yourself!
	if body.has_method("take_damage"):
		# Confirm it's an enemy
		print("Hit enemy: ", body.name)
		body.take_damage(damage)
