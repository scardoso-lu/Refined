extends Control
class_name ShopWidget

signal shop_opened(shop_id: String)
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

@export var shop_items_village: Array[ItemDef] = []
@export var shop_items_trader: Array[ItemDef] = []

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
	# Clear old buttons...
	for child in item_grid.get_children():
		child.queue_free()
	
	# 1. Select the correct Resource List
	var items_to_show = ShopItemDb.get_items_for_shop(shop_id)

	# 2. Create Buttons from Data
	for item in items_to_show:
		var btn = item_button_scene.instantiate() as Button
		
		# Display Data
		btn.text = "%s\n%dg" % [item.name, item.cost]
		
		# Connect Signal (Pass the whole Resource object!)
		btn.pressed.connect(func(): _attempt_purchase(item))
		
		item_grid.add_child(btn)

func _attempt_purchase(item: ItemDef) -> void:
	if not current_player: return
	
	# Pass the resource to the controller
	var success = current_player.purchase_item(item)
	
	if success:
		print("💰 Bought: ", item.name)
	else:
		print("❌ Too expensive!")
func _close_shop() -> void:
	hide()
