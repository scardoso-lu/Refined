# level.gd
extends Node2D

# Assign your generic "player.tscn" here in the Inspector
@export var player_scene: PackedScene 
@onready var hud = $PlayerHealthBar

# Make sure you have a Marker2D in your scene named "StartPos"
@onready var start_pos = $PlayerSpawnPoint

func _ready():
	# 1. Instantiate the Puppet (The generic player)
	var player = player_scene.instantiate()
	
	# 2. Get the specific Data (Mage? Warrior?) from Global
	var data = GameState.get_selected_character_data()
	print("LEVEL READY!")
	
	if data:
		# 3. Add to Scene
		add_child(player)
		hud.setup_hud(player, data)
		player.global_position = start_pos.global_position
		
		# 4. Inject the Brain (The critical step)
		player.setup_character(data)
	else:
		print("Critical Error: No character data loaded.")
