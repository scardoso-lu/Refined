extends CharacterBody2D
class_name MonsterController

# --- Tiers ---
var repository: MonsterRepository
@onready var view: MonsterView = $MonsterView

# --- Nodes ---
@onready var state_machine = $StateMachine
@onready var floor_ray: RayCast2D = $FloorRay
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea

# --- Configuration ---
@export var monster_data: MonsterDef
@export var difficulty_multiplier: float = 1.0
@export_group("Loot")
@export var loot_scene: PackedScene
@export var drop_chance := 0.5
@export var gold_value := 5

var player_ref: Node2D = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	repository = MonsterRepository.new()
	add_child(repository)
	
	state_machine.init(self)
	if monster_data:
		_setup_monster(monster_data)

func _setup_monster(def: MonsterDef):
	repository.init(def, difficulty_multiplier)
	view.setup_visuals(def)
	_setup_detection(def)

func _setup_detection(def: MonsterDef):
	var shape := CircleShape2D.new()
	shape.radius = def.aggro_range
	$DetectionArea/CollisionShape2D.shape = shape

func _physics_process(delta):
	_update_sensors()
	state_machine.physics_update(delta)
	move_and_slide()

# --- SENSORS ---
func _update_sensors():
	if velocity.x > 0: floor_ray.position.x = abs(floor_ray.position.x)
	elif velocity.x < 0: floor_ray.position.x = -abs(floor_ray.position.x)

	if player_ref and player_ref.has_method("is_dead") and player_ref.is_dead():
		player_ref = null
		state_machine.change_move_state(state_machine.MoveState.IDLE)

# --- MOVEMENT API ---
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func move_towards(pos: Vector2):
	var dir = sign(pos.x - global_position.x)
	velocity.x = dir * repository.get_speed()
	view.update_flip(dir, attack_area)

func stop_moving():
	velocity.x = move_toward(velocity.x, 0, 10)

# --- COMBAT API (MIDDLEWARE) ---
func take_damage(amount: int, source_pos := Vector2.ZERO):
	var new_hp = repository.apply_damage(amount)
	view.update_health_bar(new_hp, repository.max_health)
	view.play_damage_fx(amount)

	if repository.is_dead():
		state_machine.trigger_death()
	else:
		_apply_knockback(source_pos)

func deal_damage():
	for body in attack_area.get_overlapping_bodies():
		if body == self: continue
		if body.has_method("take_damage"):
			body.take_damage(int(repository.current_damage))

func spawn_loot():
	if not loot_scene or randf() > drop_chance: return
	var loot = loot_scene.instantiate()
	loot.type = 0
	loot.value = gold_value
	get_parent().call_deferred("add_child", loot)
	loot.global_position = global_position + Vector2(randf_range(-10, 10), -10)

# --- HELPERS ---
func has_target() -> bool: return player_ref != null
func get_target_position() -> Vector2: return player_ref.global_position if player_ref else global_position
func is_at_ledge() -> bool: return is_on_floor() and not floor_ray.is_colliding()
func get_xp_reward() -> int: return repository.xp_reward

func _apply_knockback(source_pos: Vector2):
	if source_pos == Vector2.ZERO: return
	var dir := (global_position - source_pos).normalized()
	state_machine.apply_knockback(Vector2(dir.x * 200, -150))

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"): player_ref = body

func _on_detection_area_body_exited(body):
	if body == player_ref: player_ref = null
