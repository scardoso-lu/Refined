# level.gd
extends Node2D

# Assign your generic "player.tscn" here in the Inspector
@export var player_scene: PackedScene 
@onready var hud = $UserInterface
@export var boss: MonsterController

# Make sure you have a Marker2D in your scene named "StartPos"
@onready var start_pos = $PlayerSpawnPoint

func _ready():
	# 1. Instantiate the Puppet (The generic player)
	var player = player_scene.instantiate()
	
	# 2. Get the specific Data (Mage? Warrior?) from Global
	var character_data = GameState.get_selected_character_data()
	print("LEVEL READY!")
	
	if character_data:
		# 3. Add to Scene
		add_child(player)
		player.global_position = start_pos.global_position
		
		# 1. Initialize Player first
	if player.has_method("setup_character"):
		player.setup_character(character_data)
	
	# 2. Initialize HUD second (so it reads correct Player stats)
	if hud.has_method("setup_hud"):
		# pass the player reference AND the data
		hud.setup_hud(player, character_data)
	else:
		print("Critical Error: No character data loaded.")
	
	# 2. Setup Boss UI
	if boss and hud:
		# Initialize the bar
		hud.setup_boss_hud(boss)
		
		# Auto-hide bar when boss dies
		boss.tree_exiting.connect(hud.hide_boss_hud)
