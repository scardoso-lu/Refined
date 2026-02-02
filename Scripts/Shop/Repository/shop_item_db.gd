extends Node

# Dictionary mapping 'shop_id' -> Array of ItemDef Resources
# We use preload() to ensure these resources are loaded into memory when the game starts.
var SHOP_INVENTORIES = {
	"village_blacksmith": [
		preload("res://Data/Items/Potion.tres"),
		preload("res://Data/Items/Upgrade_Sword.tres")
	],
	"wandering_trader": [
		preload("res://Data/Items/Potion_Max.tres"),
		preload("res://Data/Items/Bomb_Mega.tres")
	]
}

# The Public API
func get_items_for_shop(shop_id: String) -> Array[ItemDef]:
	if SHOP_INVENTORIES.has(shop_id):
		# We define a typed array to prevent type errors later
		var items: Array[ItemDef] = []
		items.assign(SHOP_INVENTORIES[shop_id])
		return items
	else:
		printerr("⚠️ ItemDatabase: No inventory found for shop_id: ", shop_id)
		return []
