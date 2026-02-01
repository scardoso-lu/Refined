extends Control
class_name ShopWidget

# --- 1. STATE VARIABLES ---
var current_player: PlayerController

# --- 2. CONFIGURATION ---
# Drag your 'ShopItemButton.tscn' here in the Inspector!
@export var item_button_scene: PackedScene 

# --- 3. SCENE REFERENCES ---
# We use export for nodes too, just in case structure changes
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var close_btn = $Panel/VBoxContainer/CloseButton
@onready var item_grid =  $Panel/VBoxContainer/ItemGrid

# --- 4. DATA (Ideally this moves to a Resource/DB later) ---
var shop_inventories = {
	"village_blacksmith": [
		{"id": "potion_heal", "name": "Health Potion", "cost": 50},
		{"id": "upgrade_sword", "name": "Sharpen Sword (+5 Dmg)", "cost": 150}
	],
	"wandering_trader": [
		{"id": "potion_max", "name": "Full Restore", "cost": 200},
		{"id": "mega_bomb", "name": "Mega Bomb", "cost": 500}
	]
}

# --- 5. INITIALIZATION ---
func _ready() -> void:
	hide()
	
	# Verify connections
	if not item_button_scene or not item_grid:
		printerr("❌ CRITICAL: Assign 'Item Button Scene' and 'Item Grid' in Inspector!")
		return
	else:
		print("✅ Item grid setupe.")

	WorldManager.shop_opened.connect(_on_shop_opened)
	close_btn.pressed.connect(_close_shop)

# --- 6. OPEN LOGIC ---
func _on_shop_opened(shop_id: String) -> void:
	current_player = get_tree().get_first_node_in_group("Player")
	print(current_player)
	if not current_player: return

	# A. Set Title
	match shop_id:
		"village_blacksmith": title_label.text = "Village Blacksmith"
		"wandering_trader": title_label.text = "Mysterious Trader"
		_: title_label.text = "Shop"

	# B. Fill the Grid dynamically
	_populate_grid(shop_id)

	# C. Show and Pause
	show()
	
	# D. Focus the first item so keyboard works immediately
	if item_grid.get_child_count() > 0:
		item_grid.get_child(0).grab_focus()
	else:
		close_btn.grab_focus()

	print("🛒 Shop Opened: ", shop_id)

# --- 7. DYNAMIC POPULATION ---
func _populate_grid(shop_id: String):
	# A. Clear existing buttons (from previous opens)
	for child in item_grid.get_children():
		child.queue_free()
	
	# B. Get the list for this specific shop
	var items = shop_inventories.get(shop_id, [])
	
	# C. Create a button for each item
	for item in items:
		var btn = item_button_scene.instantiate() as Button
		
		# Set Visuals
		btn.text = "%s\n%dg" % [item.name, item.cost]
		
		# Connect Signal (Using Bind/Lambda to pass data)
		btn.pressed.connect(func(): _attempt_purchase(item.cost, item.id))
		
		# Add to Scene
		item_grid.add_child(btn)

# --- 8. TRANSACTION LOGIC ---
func _attempt_purchase(cost: int, item_id: String) -> void:
	if not current_player: return
	
	var success = current_player.try_purchase(cost, item_id)
	
	if success:
		print("💰 Bought: ", item_id)
		# Optional: Play sound
	else:
		print("❌ Too expensive!")
		# Optional: Shake screen or flash red

func _close_shop() -> void:
	hide()
