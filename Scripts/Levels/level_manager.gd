extends Node2D

@export var player_scene: PackedScene 
@onready var hud = $UserInterface
@export var boss: MonsterController
@onready var start_pos = $PlayerSpawnPoint

func _ready():
	# 1. Spawn Player
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = start_pos.global_position
	player.setup_character(GameState.get_selected_character_data())
	
	# 2. Restore State
	if GameState.current_hp != -1:
		player.restore_saved_state(GameState.current_hp, GameState.current_gold, GameState.current_xp, GameState.current_level)

	# 3. Connection: Everything else (UI/Loot) is handled by 
	# the components themselves via signals or singletons.
