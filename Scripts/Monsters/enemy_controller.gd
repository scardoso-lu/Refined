extends CharacterBody2D
class_name MonsterController

# --- NODES ---
@onready var state_machine = $StateMachine
@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var floor_ray = $FloorRay
@onready var attack_area = $AttackArea
@onready var detection_area = $DetectionArea

# --- DATA ---
@export var monster_data: MonsterDef
var current_health: int
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Adjust this path to wherever your damage text scene is located
var floating_text_scene = preload("res://Scenes/Components/Effects/DamageNumbers.tscn")

# --- LOOT CONFIGURATION ---
@export_group("Loot Settings")
@export var loot_scene: PackedScene 
@export var drop_chance: float = 0.5
@export var xp_value: int = 10
@export var gold_value: int = 5

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
		
	# Apply scale from data
	# Note: Be careful scaling collision shapes directly; usually better to scale visuals
	sprite.scale = Vector2(def.scale, def.scale)
	
	# Setup aggro range safely
	var circle = CircleShape2D.new()
	circle.radius = def.aggro_range
	$DetectionArea/CollisionShape2D.shape = circle

func _physics_process(delta):
	var player = player_ref
	
	# --- ADD THIS CHECK ---
	if player and player.has_method("is_dead") and player.is_dead():
		print("Target player dead! Continue...")
		state_machine.change_move_state(state_machine.MoveState.IDLE)
		player_ref = null
		
	# 1. Update Sensors (Flip floor ray to match movement direction)
	if velocity.x > 0:
		floor_ray.position.x = abs(floor_ray.position.x)
	elif velocity.x < 0:
		floor_ray.position.x = -abs(floor_ray.position.x)
	
	# 2. Run Brain (State Machine handles Gravity, Logic, and Animation)
	state_machine.physics_update(delta)
	
	# 3. Apply Movement (Result of gravity + brain logic)
	move_and_slide()

# ==============================================================================
# PHYSICS & MOVEMENT API (Called by State Machine)
# ==============================================================================

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func move_towards_target(target_pos: Vector2):
	var dir = (target_pos - global_position).normalized()
	velocity.x = dir.x * monster_data.speed
	_flip_sprite(dir.x)

func stop_moving():
	# Apply friction to stop
	velocity.x = move_toward(velocity.x, 0, 10)

func is_at_ledge() -> bool:
	# Returns true if we are on floor BUT the raycast sees nothing
	return is_on_floor() and not floor_ray.is_colliding()

func _flip_sprite(dir_x: float):
	if dir_x > 0:
		sprite.flip_h = false
		attack_area.scale.x = 1 # Flip hitbox too
	elif dir_x < 0:
		sprite.flip_h = true
		attack_area.scale.x = -1

# ==============================================================================
# COMBAT & HEALTH
# ==============================================================================

func deal_damage_to_player():
	var bodies = attack_area.get_overlapping_bodies()
	
	for body in bodies:
		if body == self: continue
		if body.has_method("take_damage"):
			# Assuming monster_data has a 'damage' property
			body.take_damage(monster_data.damage)

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	current_health -= amount
	
	# Visual Feedback
	_spawn_damage_text(amount)
	_update_health_bar()
	_flash_sprite()
	
	if current_health <= 0:
		# DEAD: Tell the brain to trigger the death sequence
		state_machine.trigger_death()
	else:
		# HURT: Calculate knockback vector and tell brain to apply it
		if source_pos != Vector2.ZERO:
			var knock_dir = (global_position - source_pos).normalized()
			var knock_force = Vector2(knock_dir.x * 200, -150) # Kick up and back
			state_machine.apply_knockback(knock_force)

# Called BY the State Machine (inside trigger_death)
func spawn_loot():
	# 1. Validation
	if loot_scene == null: return
	
	if randf() > drop_chance: return

	# 2. Instantiate
	var loot = loot_scene.instantiate()
	
	# 3. Configure (Coin vs Gem)
	# Ensure your LootItem script uses the same Enum mapping (0=Coin, 1=Gem)
	if randf() > 0.15:
		loot.type = 0 # COIN
		loot.value = gold_value
	else:
		loot.type = 1 # GEM
		loot.value = xp_value
		
	# 4. Add to World (Critical: Do not add as child of self!)
	get_parent().call_deferred("add_child", loot)
	loot.global_position = global_position
	
	# Optional: Small random pop offset
	loot.global_position += Vector2(randf_range(-10, 10), -10)
	print(loot.value )
	print(loot.type )
# ==============================================================================
# VISUAL HELPERS
# ==============================================================================

func _spawn_damage_text(amount):
	if floating_text_scene:
		var text_instance = floating_text_scene.instantiate()
		text_instance.set_values(amount, Color.YELLOW)
		# Random offset so numbers don't stack perfectly
		text_instance.global_position = global_position + Vector2(randf_range(-20, 20), -50)
		get_tree().current_scene.add_child(text_instance)

func _update_health_bar():
	health_bar.value = current_health
	health_bar.visible = true

func _flash_sprite():
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

# ==============================================================================
# SIGNALS
# ==============================================================================

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"): # Use Groups for safer detection
		player_ref = body

func _on_detection_area_body_exited(body):
	if body == player_ref:
		player_ref = null
