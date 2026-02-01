extends CanvasLayer

# --- 1. EXPORTED REFERENCES ---
@export var health_widget: HealthWidget
@export var currency_widget: CurrencyWidget 

@onready var game_over_widget = $GameOverWidget 

func _ready():
	# Observe the scene for the player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		_initialize_with_player(player)
	else:
		# If player isn't spawned yet, wait for them
		get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	if node is PlayerController:
		_initialize_with_player(node)
		get_tree().node_added.disconnect(_on_node_added)

func _initialize_with_player(player_ref: PlayerController):
	var char_data = GameState.get_selected_character_data()
	
	if health_widget:
		health_widget.init_widget(char_data, player_ref.get_current_health())
		_safe_connect(player_ref.health_changed, health_widget._on_player_health_changed)
		print("✅ HUD: Connected Player Health Signal")
	else:
		print("❌ HUD Error: Health Widget is not assigned!")


	if currency_widget:
		currency_widget.update_ui(player_ref.get_gold(), player_ref.get_level(), player_ref.get_xp(), player_ref.get_xp_next())
		_safe_connect(player_ref.currency_updated, currency_widget.update_ui)
		print("✅ HUD: Connected Player Currency Signal")
	else:
		print("❌ HUD Error: Currency Widget is not assigned!")
	
	# NEW: Observe the death signal
	if not player_ref.player_died.is_connected(show_game_over_screen):
		player_ref.player_died.connect(show_game_over_screen)
		print("✅ HUD: Observing Player Death Signal")
	else:
		print("❌ HUD Error: Gameover Widget is not assigned!")

func show_game_over_screen():
	if game_over_widget:
		game_over_widget.show_game_over()
	else:
		# Fallback if you haven't assigned the widget in the inspector
		print("💀 Game Over! (HUD widget missing, check Inspector)")

# Helper
func _safe_connect(sig: Signal, method: Callable):
	if sig.is_connected(method):
		sig.disconnect(method)
	sig.connect(method)
