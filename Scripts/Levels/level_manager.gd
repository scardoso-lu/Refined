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
		# --- PERSISTENCE CHECK ---
		# If HP is valid (>-1), it means we came from another level.
		# If HP is -1, it means we just started the game (fresh spawn).
		if GameState.current_hp != -1:
			player.current_health = GameState.current_hp
			player.gold = GameState.current_gold
			player.experience = GameState.current_xp
			player.current_level = GameState.current_level
			player.current_scene = GameState.current_scene
	
	# 2. Initialize HUD second (so it reads correct Player stats)
	if hud.has_method("setup_hud"):
		# pass the player reference AND the data
		hud.setup_hud(player, character_data)
		# Important: If your UI setup happened earlier, 
		# you might need to force a UI update here to reflect the loaded stats.
		hud.currency_widget.update_ui(player.gold, player.experience, player.xp_next_level)
		hud.health_widget._on_player_health_changed(player.current_health)
	else:
		print("Critical Error: No character data loaded.")
	
	# 2. Setup Boss UI
	if boss and hud:
		# Initialize the bar
		hud.setup_boss_hud(boss)
		
		# Auto-hide bar when boss dies
		boss.tree_exiting.connect(hud.hide_boss_hud)
	
	print("Connecting Death Signal...")
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

func _on_player_died():
	print("💀 Level Manager: Player died signal received.")
	
	# Check if HUD exists and has the function we made earlier
	if hud and hud.has_method("show_game_over_screen"):
		hud.show_game_over_screen()
	else:
		print("❌ Error: HUD is missing or does not have 'show_game_over_screen()'")
