extends CharacterBody2D
class_name MonsterController

# =============================================================================
# NODES
# =============================================================================
@onready var state_machine = $StateMachine
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var floor_ray: RayCast2D = $FloorRay
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea

# =============================================================================
# DATA
# =============================================================================
@export var monster_data: MonsterDef
@export var difficulty_multiplier: float = 1.0

@export_group("Loot")
@export var loot_scene: PackedScene
@export var drop_chance := 0.5
@export var gold_value := 5

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var floating_text_scene := preload("res://Scenes/Components/Effects/DamageNumbers.tscn")

# =============================================================================
# STATE
# =============================================================================
var player_ref: Node2D = null

var max_health: float
var current_health: float
var current_damage: float
var xp_reward: int

# =============================================================================
# LIFECYCLE
# =============================================================================
func _ready():
	state_machine.init(self)
	if monster_data:
		_setup_monster(monster_data)

func _physics_process(delta):
	_update_sensors()
	state_machine.physics_update(delta)
	move_and_slide()

# =============================================================================
# SETUP
# =============================================================================
func _setup_monster(def: MonsterDef):
	_apply_scaling(def)
	_setup_visuals(def)
	_setup_detection(def)

func _setup_visuals(def: MonsterDef):
	if def.sprite_frames:
		sprite.sprite_frames = def.sprite_frames
		sprite.play("idle")
	sprite.scale = Vector2(def.scale, def.scale)

func _setup_detection(def: MonsterDef):
	var shape := CircleShape2D.new()
	shape.radius = def.aggro_range
	$DetectionArea/CollisionShape2D.shape = shape

# =============================================================================
# SENSORS
# =============================================================================
func _update_sensors():
	if velocity.x > 0:
		floor_ray.position.x = abs(floor_ray.position.x)
	elif velocity.x < 0:
		floor_ray.position.x = -abs(floor_ray.position.x)

	if player_ref and player_ref.has_method("is_dead") and player_ref.is_dead():
		player_ref = null
		state_machine.change_move_state(state_machine.MoveState.IDLE)

func has_target() -> bool:
	return player_ref != null

func get_target_position() -> Vector2:
	return player_ref.global_position if player_ref else global_position

func is_at_ledge() -> bool:
	return is_on_floor() and not floor_ray.is_colliding()

# =============================================================================
# MOVEMENT API (USED BY STATE MACHINE)
# =============================================================================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func move_towards(pos: Vector2):
	var dir = sign(pos.x - global_position.x)
	velocity.x = dir * monster_data.speed
	_flip(dir)

func stop_moving():
	velocity.x = move_toward(velocity.x, 0, 10)

func _flip(dir: float):
	if dir == 0: return
	sprite.flip_h = dir < 0
	attack_area.scale.x = -1 if dir < 0 else 1

# =============================================================================
# COMBAT
# =============================================================================
func deal_damage():
	for body in attack_area.get_overlapping_bodies():
		if body == self: continue
		if body.has_method("take_damage"):
			body.take_damage(int(current_damage))

func take_damage(amount: int, source_pos := Vector2.ZERO):
	current_health -= amount
	_update_health_bar()
	_flash()
	_spawn_damage_text(amount)

	if current_health <= 0:
		state_machine.trigger_death()
	else:
		_apply_knockback(source_pos)

func _apply_knockback(source_pos: Vector2):
	if source_pos == Vector2.ZERO: return
	var dir := (global_position - source_pos).normalized()
	state_machine.apply_knockback(Vector2(dir.x * 200, -150))

# =============================================================================
# DEATH & LOOT
# =============================================================================
func spawn_loot():
	if not loot_scene: return
	if randf() > drop_chance: return

	var loot = loot_scene.instantiate()
	loot.type = 0
	loot.value = gold_value

	get_parent().call_deferred("add_child", loot)
	loot.global_position = global_position + Vector2(randf_range(-10, 10), -10)

func get_xp_reward() -> int:
	return xp_reward

# =============================================================================
# VISUALS
# =============================================================================
func _update_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = true

func _flash():
	sprite.modulate = Color.RED
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _spawn_damage_text(amount: int):
	if not floating_text_scene: return
	var txt = floating_text_scene.instantiate()
	txt.set_values(amount, Color.YELLOW)
	txt.global_position = global_position + Vector2(randf_range(-20, 20), -50)
	get_tree().current_scene.add_child(txt)

# =============================================================================
# SCALING (n · log n – SAME PHILOSOPHY AS PLAYER)
# =============================================================================
func _apply_scaling(def: MonsterDef):
	var level_zone = 1
	var log_term := log(level_zone + 1)
	var growth = level_zone * log_term

	max_health = def.base_hp * pow(growth, 0.95) * difficulty_multiplier
	max_health = max(5.0, max_health)
	current_health = max_health

	current_damage = def.base_damage * pow(growth, 0.85)
	current_damage = max(1.0, current_damage)

	xp_reward = int(def.base_xp * log_term * difficulty_multiplier)
	xp_reward = max(1, xp_reward)

# =============================================================================
# SIGNALS
# =============================================================================
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player_ref = body

func _on_detection_area_body_exited(body):
	if body == player_ref:
		player_ref = null
