extends CanvasLayer

# --- 1. EXPORTED REFERENCES ---
# Instead of assuming the path with $, we let the Inspector tell us where they are.
@export var health_widget: HealthWidget
@export var currency_widget: CurrencyWidget # <--- Ensure this is assigned in Inspector!

# --- 2. BOSS SYSTEMS ---
@export var boss_health_widget: BossHealthWidget

# Add the reference
@onready var game_over_widget = $GameOverWidget 

func setup_hud(player_ref: CharacterBody2D, char_data: CharacterDef):
	# 1. Initialize Widgets
	if health_widget:
		health_widget.init_widget(char_data, player_ref.current_health)
		_safe_connect(player_ref.health_changed, health_widget._on_player_health_changed)
		print("✅ HUD: Connected Player Health Signal to Widget")
	else:
		print("❌ HUD Error: Health Widget is not assigned in the Inspector!")
	if currency_widget:
		# Initialize Currency
		currency_widget.update_ui(player_ref.gold, player_ref.experience, player_ref.xp_next_level)
		_safe_connect(player_ref.currency_updated, currency_widget.update_ui)
		print("✅ HUD: Connected Player Currency Signal to Widget")
	else:
		print("❌ HUD Error: Currency Widget is not assigned in the Inspector!")
	

# --- SETUP BOSS (Independent) ---
func setup_boss_hud(boss_ref: MonsterController):
	if not boss_health_widget: 
		print("❌ HUD Error: Boss Health Widget is not assigned in the Inspector!")
		return
	
	# 1. Init with Monster Data
	boss_health_widget.init_boss(boss_ref.monster_data, boss_ref.current_health)
	
	# 2. Connect Signal
	# Note: We connect to the specific BOSS function in the widget
	_safe_connect(boss_ref.health_changed, boss_health_widget._on_boss_health_changed)

func hide_boss_hud():
	if boss_health_widget:
		boss_health_widget.visible = false

# Add a helper function for the Level Manager to call
func show_game_over_screen():
	if game_over_widget:
		game_over_widget.show_game_over()

# Helper
func _safe_connect(sig: Signal, method: Callable):
	if sig.is_connected(method):
		sig.disconnect(method)
	sig.connect(method)
