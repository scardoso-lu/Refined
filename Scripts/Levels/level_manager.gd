extends Node2D

@export var player_scene: PackedScene 
@onready var hud = $UserInterface
@export var boss: MonsterController
@onready var start_pos = $PlayerSpawnPoint

func _ready():
	# 1. Instantiate Controller
	var player = player_scene.instantiate()
	var character_data = GameState.get_selected_character_data()
	print("LEVEL READY!")
	
	if character_data:
		add_child(player)
		player.global_position = start_pos.global_position
		
		# 2. Initialize (Creates Repository & View)
		if player.has_method("setup_character"):
			player.setup_character(character_data)
		
		# 3. --- PERSISTENCE (VIA CONTROLLER) ---
		# We talk strictly to the Controller. No repository access.
		if GameState.current_hp != -1:
			player.restore_saved_state(
				GameState.current_hp,
				GameState.current_gold,
				GameState.current_xp,
				GameState.current_level
			)
	
	# 4. Initialize HUD
	if hud and hud.has_method("setup_hud"):
		hud.setup_hud(player, character_data)
		
		# 5. Force Initial UI Update (VIA CONTROLLER GETTERS)
		if hud.currency_widget:
			hud.currency_widget.update_ui(
				player.get_gold(), 
				player.get_xp(), 
				player.get_xp_next()
			)
		if hud.health_widget:
			hud.health_widget._on_player_health_changed(player.get_current_health())
	else:
		print("Critical Error: No character data loaded or HUD missing.")
	
	# 6. Boss & Death Signals
	if boss and hud:
		hud.setup_boss_hud(boss)
		boss.tree_exiting.connect(hud.hide_boss_hud)
	
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

func _on_player_died():
	if hud and hud.has_method("show_game_over_screen"):
		hud.show_game_over_screen()
