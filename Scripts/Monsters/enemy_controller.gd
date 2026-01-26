extends CharacterBody2D
class_name MonsterController

# --- NODES ---
@onready var state_machine = $StateMachine # We'll add this next
@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var floor_ray = $FloorRay
@onready var attack_area = $AttackArea
@onready var detection_area = $DetectionArea

# --- DATA ---
@export var monster_data: MonsterDef
var current_health: int = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var floating_text_scene = preload("res://Scenes/Components/DamageNumbers.tscn")

# --- AI SENSORS ---
var player_ref: Node2D = null

func _ready():
	# Initialize the Brain
	state_machine.init(self)
	
	if monster_data:
		setup_monster(monster_data)

func setup_monster(def: MonsterDef):
	current_health = def.max_health
	health_bar.max_value = def.max_health
	health_bar.value = def.max_health
	
	if def.sprite_frames:
		sprite.sprite_frames = def.sprite_frames
		sprite.play("idle")
		
	sprite.scale = Vector2(def.scale, def.scale)
	$DetectionArea/CollisionShape2D.shape.radius = def.aggro_range

func _physics_process(delta):
	# 1. Update Sensors
	# Move the Ledge Raycast to face the direction we are moving
	if velocity.x > 0:
		floor_ray.position.x = abs(floor_ray.position.x)
	elif velocity.x < 0:
		floor_ray.position.x = -abs(floor_ray.position.x)
	
	# 2. Run Brain
	state_machine.physics_update(delta)
	
	# 3. Apply Movement
	move_and_slide()

# --- PUBLIC API (Commands for the Brain) ---

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func move_towards_target(target_pos: Vector2):
	var dir = (target_pos - global_position).normalized()
	velocity.x = dir.x * monster_data.speed
	_flip_sprite(dir.x)

func stop_moving():
	velocity.x = move_toward(velocity.x, 0, 10)

func is_at_ledge() -> bool:
	# If we are on the floor, but the ray sees nothing, it's a cliff
	return is_on_floor() and not floor_ray.is_colliding()

func _flip_sprite(dir_x: float):
	if dir_x > 0:
		sprite.flip_h = false
		attack_area.position.x = abs(attack_area.position.x)
	elif dir_x < 0:
		sprite.flip_h = true
		attack_area.position.x = -abs(attack_area.position.x)

# --- COMBAT LOGIC ---

func deal_damage_to_player():
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body == self: continue
		if body.has_method("take_damage"):
			body.take_damage(monster_data.damage)

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	current_health -= amount
	
	# Spawn Text
	var text_instance = floating_text_scene.instantiate()
	text_instance.set_values(amount, Color.YELLOW)
	text_instance.global_position = global_position + Vector2(randf_range(-80, -60), randf_range(-100, -50))
	get_tree().current_scene.add_child(text_instance)
	
	# Update Bar
	health_bar.value = current_health
	health_bar.visible = true
	
	# Flash Red
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# --- FORCE STATE CHANGE: KNOCKBACK ---
	if source_pos != Vector2.ZERO:
		var knock_dir = (global_position - source_pos).normalized()
		var knock_force = Vector2(knock_dir.x * 200, -50)
		# Tell the Brain to interrupt everything and fly backward
		state_machine.apply_knockback(knock_force)

	if current_health <= 0:
		die()

func die():
	set_physics_process(false)
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()

# --- SIGNALS ---
func _on_detection_area_body_entered(body):
	if body.name == "Player": player_ref = body

func _on_detection_area_body_exited(body):
	if body.name == "Player": player_ref = null
