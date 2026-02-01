extends Area2D
class_name Merchant

@export var shop_id: String = "village_blacksmith"
var player_ref = null # Removed type hint to prevent cyclic errors

func _ready():
	# Ensure monitoring is on
	monitoring = true
	
	# Connect signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _input(event):
	if event.is_action_pressed("interact"):
		if player_ref != null:
			print("💰 SUCCESS: Opening Shop!")
			WorldManager.shop_opened.emit(shop_id)
		else:
			print("❌ FAILED: Player pressed E, but merchant thinks player is missing.")

func _on_body_entered(body):
	print("👀 PHYSICS DETECTED: ", body.name)
	
	# METHOD 1: Group Check (Safest)
	if body.is_in_group("Player"):
		print("✅ It is the Player! Ref Assigned.")
		player_ref = body
		return

	# METHOD 2: Class Check (Fallback)
	if body is PlayerController:
		print("✅ It is the Player (via Class)!")
		player_ref = body
	else:
		print("⚠️ Object is not a Player. It is: ", body.get_class())

func _on_body_exited(body):
	if body == player_ref:
		print("👋 Player walked away.")
		player_ref = null
