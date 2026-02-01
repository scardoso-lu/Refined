class_name MonsterSpawner
extends Marker2D

# 1. Which monster goes here? (Type the key from MONSTER_TEXTURE_DB)
@export var monster_id: String = "rock_golem"

# 2. Reference to the Generic Body Scene
var base_enemy_scene = preload("res://Scenes/Monsters/BaseEnemy.tscn")

func _ready():
	# Using call_deferred here as well is safer to ensure WorldManager Autoload is fully ready
	spawn_monster.call_deferred()

func spawn_monster():
	# A. Check if ID exists
	if not MonsterDB.MONSTER_TEXTURE_DB.has(monster_id):
		printerr("Error: Monster ID '", monster_id, "' not found in DB!")
		return
		
	# B. Load Data
	var resource_path = MonsterDB.MONSTER_TEXTURE_DB[monster_id]
	var monster_def = load(resource_path) as MonsterDef
	
	if not monster_def:
		printerr("Error: Could not load Resource at ", resource_path)
		return

	# C. Create the Body
	var enemy_instance = base_enemy_scene.instantiate() as MonsterController
	
	# === FIX: ASSIGN THE DATA ===
	# This triggers the _setup_monster logic inside the Controller
	enemy_instance.monster_data = monster_def
	
	# D. Inject Scaling from Global Observer
	enemy_instance.difficulty_multiplier = WorldManager.get_difficulty_multiplier()
	
	# E. Set Transform
	enemy_instance.global_position = global_position
	
	# F. REWARD OBSERVER (Consolidated)
	# We use the Global WorldManager to process the reward when the monster dies
	enemy_instance.tree_exiting.connect(func():
		# Check if repository exists and if it actually died
		if enemy_instance.repository and enemy_instance.repository.is_dead():
			WorldManager.process_reward(enemy_instance.get_xp_reward())
	)
	
	# G. Add to World
	get_parent().add_child(enemy_instance)	

	# H. Cleanup Spawner
	queue_free()
