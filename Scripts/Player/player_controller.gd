extends CharacterBody2D
class_name PlayerController

# --- SIGNALS ---
signal health_changed(new_amount)
signal currency_updated(new_gold, xp, xp_next_max)
signal level_up(new_level)
signal player_died

# --- CONFIG ---
@export_group("Debugging")
@export var debug_character: CharacterDef

# --- NODES ---
@onready var state_machine = $StateMachine 
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var weapon_area = $WeaponArea

# NEW: The View Layer
@onready var view: PlayerView = $PlayerView 

# --- LAYERS ---
var repository: PlayerRepository # The Data Layer

# --- STATE ---
var _current_input_dir: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# 1. Initialize Repository (SERVER REPLACEMENT)
	repository = PlayerRepository.new()
	add_child(repository)
	
	if debug_character:
		setup_character(debug_character)
	
	state_machine.init(self)
	
	# 2. Connect View Signals (INPUT)
	view.direction_changed.connect(func(dir): _current_input_dir = dir)
	
	# 3. Add to group (Game Logic)
	add_to_group("Player")

func setup_character(def: CharacterDef) -> void:
	# Push data to layers
	repository.init(def)
	view.setup_visuals(def)
	
	# Controller handles Physics Shape
	if collider.shape is RectangleShape2D:
		collider.shape.size = def.collider_size
	elif collider.shape is CapsuleShape2D:
		collider.shape.radius = def.collider_size.x / 2.0
		collider.shape.height = def.collider_size.y

# --- PHYSICS LOOP ---
func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)
	move_and_slide()

# --- INPUT ---
# Only forwarded to State Machine for specific logic triggers
func _input(event):
	state_machine.input_update(event)

# --- PUBLIC API (For StateMachine & Game) ---

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func get_move_speed() -> float:
	return repository.get_base_move_speed()

func get_jump_force() -> float:
	return repository.get_jump_force()

func handle_movement_input(max_speed: float) -> void:
	var delta = get_physics_process_delta_time()
	# Ask Repository to calculate velocity based on input direction
	velocity.x = repository.compute_velocity_x(velocity.x, _current_input_dir, delta, max_speed)

# --- COMBAT ---

func deal_damage_in_hitbox():
	var bodies = weapon_area.get_overlapping_bodies()
	for body in bodies:
		if body == self: continue
		if body.has_method("take_damage"):
			body.take_damage(get_damage(), global_position)

func take_damage(amount: int):
	# 1. Update Data (Repository)
	var new_hp = repository.apply_damage(amount)
	
	# 2. Update Visuals (View)
	health_changed.emit(new_hp)
	view.play_damage_effect()
	
	# 3. Check Logic
	if new_hp <= 0:
		die()

func die():
	print("Player Died! Transitioning to Death State...")
	state_machine.change_move_state(state_machine.MoveState.DEATH)

func collect_loot(type_id: int, amount: int):
	# 1. Update Data
	var result = repository.add_loot(type_id, amount)
	
	# 2. Update UI
	currency_updated.emit(result.gold, result.xp, result.xp_next)
	
	if result.leveled_up:
		view.play_level_up_effect()
		level_up.emit(result.level)
		health_changed.emit(repository.current_health)

func is_dead() -> bool:
	return repository.current_health <= 0

func get_damage() -> int:	
	return repository.get_outgoing_damage()
	
func get_level() -> int:
	return repository.current_level

func get_current_scene() -> String:
	return repository.current_scene
	
# PERSISTENCE API (The Middleware)
# =============================================================================

# 1. SETTER: Restore data from GameState (Logic -> Repository)
func restore_saved_state(hp: int, saved_gold: int, saved_xp: int, saved_level: int) -> void:
	# The Controller validates/passes data to the Repository
	repository.current_health = hp
	repository.gold = saved_gold
	repository.experience = saved_xp
	repository.current_level = saved_level
	
	# Optional: Sync internal math in case level changed without "leveling up" logic
	repository._recalculate_stats() 

# 2. GETTERS: For HUD Initialization (Repository -> Logic)
func get_current_health() -> int:
	return repository.current_health

func get_gold() -> int:
	return repository.gold

func get_xp() -> int:
	return repository.experience

func get_xp_next() -> int:
	return repository.xp_next_level
