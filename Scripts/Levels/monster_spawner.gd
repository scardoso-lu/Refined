class_name MonsterSpawner
extends Marker2D

# 1. Level Configuration
@export var level_name: String = "level_01"

# Distance in pixels between each monster. 
# Make sure this is wider than your monster's sprite (e.g., 60.0 or 80.0)
@export var spawn_spacing: float = 80.0 

# 2. Reference to the Generic Body Scene
var base_enemy_scene = preload("res://Scenes/Monsters/BaseEnemy.tscn")

func _ready():
	spawn_monster.call_deferred()

func add_monster(monster_path: String, index: int, total_count: int):
	var monster_def = load(monster_path) as MonsterDef
	
	if not monster_def:
		printerr("Error: Could not load Resource at ", monster_path)
		return

	# C. Create the Body
	var enemy_instance = base_enemy_scene.instantiate() as MonsterController
	
	# === ASSIGN THE DATA ===
	enemy_instance.monster_data = monster_def
	enemy_instance.difficulty_multiplier = WorldManager.get_difficulty_multiplier()
	
	# === E. SIDE-BY-SIDE POSITIONING MATH ===
	# Formula: Centers the whole group on the Marker2D
	var horizontal_offset = (index - (total_count - 1) / 2.0) * spawn_spacing
	
	# Tiny random Y jitter is fine, but X is now strictly calculated
	var random_y_jitter = randf_range(-5, 5)
	
	enemy_instance.global_position = global_position + Vector2(horizontal_offset, random_y_jitter)
	
	# F. REWARD OBSERVER
	enemy_instance.tree_exiting.connect(func():
		if enemy_instance.repository and enemy_instance.repository.is_dead():
			WorldManager.process_reward(enemy_instance.get_xp_reward())
	)
	
	# G. Add to World
	get_parent().add_child(enemy_instance)	

func spawn_monster():
	# A. Get the Normal Wave
	var wave_list = MonsterDB.generate_wave_data(level_name, self.name)
	
	# B. Check for Sin (50% Chance)
	# We ADD the Sin to the array instead of spawning it immediately.
	# This ensures it gets included in the spacing calculation.
	if randf() < 0.5:
		var sin_monster = MonsterDB.SIN_POOL[randi() % MonsterDB.SIN_POOL.size()]
		# You can use .append() to put it at the end
		# Or .push_front() to put it at the start
		wave_list.append(sin_monster)
	
	# C. Recalculate Total Count
	# Now this count includes the Sin if it was added
	var total_count = wave_list.size()
	
	# D. Iterate the Unified List
	for i in range(total_count):
		var monster_path = wave_list[i]
		# Pass 'i' as the unique offset for this monster
		add_monster(monster_path, i, total_count)
		
	# H. Cleanup Spawner
	queue_free()
