extends CharacterBody2D
class_name PlayerController

signal health_changed(new_amount)

# --- Configuration ---
@export_group("Debugging")
@export var debug_character: CharacterDef

# --- Nodes ---
# We assume the State Machine is a child node named "StateMachine"
@onready var state_machine = $StateMachine 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var weapon_area = $WeaponArea

# --- Variables ---
var _stats: CharacterDef 
@export var damage: int = 20
@export var max_health: int = 100
var current_health: int

# Physics constants
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Initialize the brain
	state_machine.init(self)

func setup_character(def: CharacterDef) -> void:
	print("✅ setup_character called with: ", def)
	_stats = def
	max_health = _stats.max_health
	current_health = _stats.current_health
	
	if _stats.sprite_frames:
		sprite.sprite_frames = _stats.sprite_frames
		sprite.play("idle")
		
	# Apply Hitbox Size
	if collider.shape is RectangleShape2D:
		collider.shape.size = def.collider_size
	elif collider.shape is CapsuleShape2D:
		collider.shape.radius = def.collider_size.x / 2.0
		collider.shape.height = def.collider_size.y

# --- THE GAME LOOP ---
func _physics_process(delta: float) -> void:
	# 1. Ask the Brain to calculate velocity
	state_machine.physics_update(delta)
	
	# 2. Move the Body
	move_and_slide()

func _input(event):
	# Forward inputs to the Brain
	state_machine.input_update(event)

# --- PUBLIC ACTIONS (The API) ---
# The State Machine calls these functions.

func apply_gravity(delta: float) -> void:
	# We don't check is_on_floor() here because the State Machine 
	# decides when gravity applies (e.g., usually always, unless climbing/dashing)
	velocity.y += gravity * delta

func get_move_speed() -> float:
	return _stats.speed if _stats else 300.0

func get_jump_force() -> float:
	return _stats.jump_velocity if _stats else -400.0

func handle_movement_input(speed: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		
		# Sprite Flipping
		sprite.flip_h = direction < 0
		# Hitbox Flipping
		if direction < 0:
			weapon_area.position.x = -abs(weapon_area.position.x)
		else:
			weapon_area.position.x = abs(weapon_area.position.x)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

func _on_weapon_area_body_entered(body):
	if body == self: return
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
