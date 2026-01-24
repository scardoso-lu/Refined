class_name MonsterSpawner
extends Marker2D

# 1. Which monster goes here? (Type the key from MONSTER_TEXTURE_DB)
@export var monster_id: String = "rock_golem"

# 2. Reference to the Generic Body Scene
# (You can hardcode this path since it's always the same puppet)
var base_enemy_scene = preload("res://Scenes/Monsters/BaseEnemy.tscn")


func _ready():
	spawn_monster()

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
	var enemy_instance = base_enemy_scene.instantiate()
	
	# D. Inject Data (Crucial Step!)
	# We manually assign the data before adding it to the scene
	enemy_instance.monster_data = monster_def
	enemy_instance.global_position = global_position
	
	# E. Add to Game World
	# We add it to the PARENT of the spawner (the Level), not the spawner itself
	get_parent().call_deferred("add_child", enemy_instance)
	
	# F. Cleanup
	# Optional: Delete the spawner marker to keep scene tree clean
	queue_free()
