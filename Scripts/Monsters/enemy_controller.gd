extends CharacterBody2D

@export var monster_data: MonsterDef

@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar

# We need a timer to prevent the monster from hitting 60 times per second
@onready var attack_timer = Timer.new() 

# We need to give it "Ledge Detection"
@onready var floor_ray = $FloorRay

# State Variables
var player_ref: Node2D = null
var is_attacking: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var floating_text_scene = preload("res://Scenes/Components/DamageNumbers.tscn")

var current_health: int = 100

var has_dealt_damage: bool = false # NEW FLAG

func _ready():
	# Setup the generic timer
	add_child(attack_timer)
	attack_timer.one_shot = true
	
	if monster_data:
		setup_monster(monster_data)

func setup_monster(def: MonsterDef):
	# Setup Health
	current_health = def.max_health # Load health from data!
	health_bar.max_value = def.max_health
	health_bar.value = def.max_health
	# Optional: Hide bar if full? (Uncomment to enable)
	# health_bar.visible = false
	
	# 1. Visuals & Stats 
	if def.sprite_frames:
		sprite.sprite_frames = def.sprite_frames
		sprite.play("idle")
	sprite.scale = Vector2(def.scale, def.scale)
	$DetectionArea/CollisionShape2D.shape.radius = def.aggro_range
	
	# 2. Attack Setup
	# Let's say every monster attacks once per second (1.0s)
	# You can add 'attack_speed' to your MonsterDef later!
	attack_timer.wait_time = 1.0 

func _physics_process(delta):
	# Update RayCast Direction
	# If moving Right, put ray on Right. If Left, put ray on Left.
	if velocity.x > 0:
		floor_ray.position.x = abs(floor_ray.position.x)
	elif velocity.x < 0:
		floor_ray.position.x = -abs(floor_ray.position.x)
	
	if not is_on_floor():
		velocity.y += gravity * delta

	# 1. PRIORITY: Handling the Attack
	if is_attacking:
		# --- NEW: INTERRUPT LOGIC ---
		if player_ref:
			var dist = global_position.distance_to(player_ref.global_position)
			# If player moves just slightly out of range (Range + 20px buffer)
			# We cancel the attack immediately.
			if dist > monster_data.attack_range + 50:
				_abort_attack()
				return
		# ---------------------------
		# 2. DAMAGE LOGIC (The New Part)
		# Check if we are on the "Impact Frame" (e.g., Frame 1 or 2)
		# Adjust the number '1' to match whichever frame looks like the "Hit" in your animation
		if sprite.frame >= 10 and not has_dealt_damage:
			_deal_damage_to_player()
			has_dealt_damage = true # Lock it so we don't hit 60 times a second

		# 3. Animation Finish Check
		if not sprite.is_playing(): 
			is_attacking = false
			attack_timer.start() # Start cooldown only after attack finishes
		else:
			return

	# 2. AI Decision (Same as before)
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		
		if distance <= monster_data.attack_range and attack_timer.is_stopped():
			_start_attack()
		else:
			_chase_state()
	else:
		_idle_state()
	
	move_and_slide()

func take_damage(amount: int):
	current_health -= amount
	print("Monster hit! HP: ", current_health)
	
	# --- NEW: SPAWN FLOATING TEXT ---
	var text_instance = floating_text_scene.instantiate()	
	# 1. Set the Data (Safe to do before adding child)
	text_instance.set_values(amount, Color.YELLOW)	
	# 2. Set Position
	var random_x = randf_range(-80, -60)
	var random_y = randf_range(-100, -50)
	text_instance.global_position = global_position + Vector2(random_x, random_y)
	# 3. Add to World (This triggers _ready and starts the animation)
	get_tree().current_scene.add_child(text_instance)
	# -------------------------------
	
	# Optional: Play a "Hurt" animation or flash white
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	# UPDATE BAR
	health_bar.value = current_health
	health_bar.visible = true # Show it if it was hidden
	
	if current_health <= 0:
		die()

func die():
	print("Monster Died!")
	# Stop everything
	set_physics_process(false) 
	
	# Play death animation if you have one
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
		
	queue_free() # Delete the monster from the game

func _deal_damage_to_player():
	# We use the AttackArea (Area2D) to check for overlapping bodies
	var bodies = $AttackArea.get_overlapping_bodies()
	
	print("--- Attack Swing ---")
	print(bodies)
	for body in bodies:
		print("Touched: ", body.name)  # <--- Check this output!
		if body == self:
			continue # Don't hit yourself!
		
		if body.has_method("take_damage"):
			body.take_damage(monster_data.damage)
			print(">> Damage Dealt!")
		else:
			print(">> No 'take_damage' method found on ", body.name)

# Add this helper function to switch back cleanly
func _abort_attack():
	is_attacking = false
	# Immediately switch animation to run so it doesn't look frozen
	sprite.play("run")
	# Optional: Reset cooldown so he attacks sooner if he catches you again?
	# attack_timer.stop()

func _start_attack():
	is_attacking = true
	has_dealt_damage = false # Reset the flag for the new swing
	velocity.x = 0 # Stop moving
	
	# Play animation (Ensure your SpriteFrames has an "attack" animation!)
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	else:
		print("Error: No 'attack' animation found!")
		is_attacking = false # Abort

func _chase_state():
	var dir = (player_ref.global_position - global_position).normalized()
	# NEW: Check for Cliff
	# If we are on the ground AND the ray sees nothing -> STOP!
	if is_on_floor() and not floor_ray.is_colliding():
		velocity.x = 0
		sprite.play("idle")
		return # Don't run off the edge!
		
	# Normal Movement
	velocity.x = dir.x * monster_data.speed
	
	# --- IMPROVED FLIP LOGIC ---
	if dir.x > 0: 
		# Face Right
		sprite.flip_h = false
		# Ensure AttackArea is on the Right (Positive X)
		$AttackArea.position.x = abs($AttackArea.position.x)
		
	elif dir.x < 0: 
		# Face Left
		sprite.flip_h = true

		# Ensure AttackArea is on the Left (Negative X)
		$AttackArea.position.x = -abs($AttackArea.position.x)
	# ---------------------------
	
	sprite.play("run")

func _idle_state():
	velocity.x = move_toward(velocity.x, 0, 10)
	sprite.play("idle")

# --- SIGNALS (Keep these connected!) ---
func _on_detection_area_body_entered(body):
	if body.name == "Player": player_ref = body

func _on_detection_area_body_exited(body):
	if body.name == "Player": player_ref = null
