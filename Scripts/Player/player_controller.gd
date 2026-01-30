extends CharacterBody2D
class_name PlayerController

signal health_changed(new_amount)
signal currency_updated(new_gold, xp, xp_next_max) # Must have 3 arguments!
signal level_up(new_level)
signal player_died

# --- Configuration ---
@export_group("Debugging")
@export var debug_character: CharacterDef
@export_group("Physics")
@export var acceleration: float = 1200.0
@export var friction: float = 1600.0

# --- Nodes ---
@onready var state_machine = $StateMachine 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var weapon_area = $WeaponArea

# --- Variables ---
var _stats: CharacterDef 
var current_health: int
var max_health: int
var damage: int = 20 # Default, overwritten by stats

# Loot variables
var gold: int = 0
var experience: int = 0
var xp_next_level: int = 100
var current_level: int = 1
var current_scene: String = "level_01.tscn"

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	state_machine.init(self)
	add_to_group("Player")
	
	# Fix: Actually use the debug stats on startup
	if debug_character:
		setup_character(debug_character)

func setup_character(def: CharacterDef) -> void:
	_stats = def
	current_health = _stats.current_health
	max_health = _stats.max_health
	# Assuming CharacterDef has a damage value, otherwise keep default
	# damage = _stats.damage 
	
	if _stats.sprite_frames:
		sprite.sprite_frames = _stats.sprite_frames
		sprite.play("idle")
		
	# Apply Hitbox Size
	if collider.shape is RectangleShape2D:
		collider.shape.size = def.collider_size
	elif collider.shape is CapsuleShape2D:
		collider.shape.radius = def.collider_size.x / 2.0
		collider.shape.height = def.collider_size.y

# --- PHYSICS ---
func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)
	move_and_slide()

func _input(event):
	state_machine.input_update(event)

# --- PUBLIC API ---

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func get_move_speed() -> float:
	return _stats.speed if _stats else 300.0

func get_jump_force() -> float:
	return _stats.jump_velocity if _stats else -400.0

func handle_movement_input(max_speed: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var delta = get_physics_process_delta_time()
	
	if direction:
		# Smooth Acceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		
		# Visual Flipping
		sprite.flip_h = direction < 0
		# Flip weapon area using Scale (handles children/offsets automatically)
		weapon_area.scale.x = -1 if direction < 0 else 1
	else:
		# Smooth Friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)

# --- COMBAT ---

# Called by State Machine on specific animation frame
func deal_damage_in_hitbox():
	var bodies = weapon_area.get_overlapping_bodies()
	for body in bodies:
		if body == self: continue
		if body.has_method("take_damage"):
			# Pass self.global_position so enemy knows where knockback comes from
			body.take_damage(damage, global_position)

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die():
	print("Player Died! Transitioning to Death State...")
	# Reloading scene is fine for now
	state_machine.change_move_state(state_machine.MoveState.DEATH)

		
func collect_loot(type_id: int, amount: int):
	match type_id:
		0: # COIN
			gold += amount
		1: # GEM
			experience += amount
			_check_level_up()
	print("updating player loot")
	# Update UI immediately
	currency_updated.emit(gold, experience, xp_next_level)

func _check_level_up():
	# While loop allows multiple level ups at once (big XP drops)
	while experience >= xp_next_level:
		experience -= xp_next_level
		current_level += 1
		
		# Curve: Increases by 50% each level
		xp_next_level = int(xp_next_level * 1.5)
		
		# Full Heal on Level Up
		current_health = _stats.max_health # Assuming you use _stats from CharacterDef
		health_changed.emit(current_health)
		
		# Visual/Audio feedback
		level_up.emit(current_level)
		_play_level_up_effect()

func _play_level_up_effect():
	# Simple flash green
	var tween = create_tween()
	sprite.modulate = Color.GREEN
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func is_dead() -> bool:
	return current_health <= 0
