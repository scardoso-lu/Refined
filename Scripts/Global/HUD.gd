extends CanvasLayer

# --- 1. EXPORTED REFERENCES ---
@export var health_widget: HealthWidget
@export var currency_widget: CurrencyWidget 
@export var boss_health_widget: BossHealthWidget

@onready var game_over_widget = $GameOverWidget 

func setup_hud(player_ref: PlayerController, char_data: CharacterDef):
	# 1. Initialize Health Widget
	if health_widget:
		# MIDDLEWARE: Use get_current_health() instead of .current_health
		health_widget.init_widget(char_data, player_ref.get_current_health())
		
		# Signals remain the same as they are emitted by the Controller
		_safe_connect(player_ref.health_changed, health_widget._on_player_health_changed)
		print("✅ HUD: Connected Player Health Signal")
	else:
		print("❌ HUD Error: Health Widget is not assigned!")

	# 2. Initialize Currency Widget
	if currency_widget:
		# MIDDLEWARE: Use getters instead of direct property access
		currency_widget.update_ui(
			player_ref.get_gold(), 
			player_ref.get_xp(), 
			player_ref.get_xp_next()
		)
		
		# Signals remain the same
		_safe_connect(player_ref.currency_updated, currency_widget.update_ui)
		print("✅ HUD: Connected Player Currency Signal")
	else:
		print("❌ HUD Error: Currency Widget is not assigned!")
	

# --- SETUP BOSS (Independent) ---
func setup_boss_hud(boss_ref: MonsterController):
	if not boss_health_widget: 
		return
	
	# Boss logic remains direct for now as it hasn't been refactored to 3-tier yet
	boss_health_widget.init_boss(boss_ref.monster_data, boss_ref.current_health)
	_safe_connect(boss_ref.health_changed, boss_health_widget._on_boss_health_changed)

func hide_boss_hud():
	if boss_health_widget:
		boss_health_widget.visible = false

func show_game_over_screen():
	if game_over_widget:
		game_over_widget.show_game_over()

# Helper
func _safe_connect(sig: Signal, method: Callable):
	if sig.is_connected(method):
		sig.disconnect(method)
	sig.connect(method)
