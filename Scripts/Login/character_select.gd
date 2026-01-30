extends Control

# --- Settings ---
const PAGE_SIZE: int = 4

# --- State ---
var current_page_index: int = 0
var all_character_ids: Array = [] # Holds ["mage_01", "warrior_01", etc.]
var current_slots_data: Array = [null, null, null, null] # Tracks IDs currently on screen

# --- Node References ---
# Get the 4 slot containers as an array for easy looping
@onready var slots: Array[VBoxContainer] = [
	$HeroSlots/Slot0,
	$HeroSlots/Slot1,
	$HeroSlots/Slot2,
	$HeroSlots/Slot3
]
@onready var prev_btn = $Navigation/PrevButton
@onready var next_btn = $Navigation/NextButton

func _ready():
	# 1. Initialize Data
	# Convert the dictionary keys into a simple array we can sort and slice
	all_character_ids = GameState.CHARACTER_DB.keys()
	
	# 2. Connect Signals
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	
	# Connect the 4 select buttons dynamically
	for i in range(slots.size()):
		var btn = slots[i].get_node("SelectButton")
		# We bind 'i' so the function knows WHICH slot was clicked
		btn.pressed.connect(_on_slot_button_pressed.bind(i))
		
	# 3. Initial Display
	update_display()

# --- The Core Logic ---
func update_display():
	# Calculate start index for the current page
	var start_index = current_page_index * PAGE_SIZE
	
	# Reset current data tracker
	current_slots_data = [null, null, null, null]
	
	# Loop through the 4 available UI slots
	for i in range(PAGE_SIZE):
		var actual_data_index = start_index + i
		var slot_node = slots[i]
		
		# Check if we have a character for this slot (handles partial last pages)
		if actual_data_index < all_character_ids.size():
			# Get ID and Load Data
			var char_id = all_character_ids[actual_data_index]
			var data = load(GameState.CHARACTER_DB[char_id]) as CharacterDef
			
			# Fill UI
			slot_node.show()
			slot_node.get_node("NameLabel").text = char_id.capitalize()
			_set_portrait(slot_node.get_node("Portrait"), data)
			
			# Track which ID is in this slot
			current_slots_data[i] = char_id
		else:
			# No character for this slot, hide it
			slot_node.hide()

	# Update Navigation Button States (Disable if at start or end)
	prev_btn.disabled = current_page_index == 0
	next_btn.disabled = (start_index + PAGE_SIZE) >= all_character_ids.size()

# Helper to handle portrait vs sprite fallback
func _set_portrait(target_rect: TextureRect, data: CharacterDef):
	if data.portrait:
		target_rect.texture = data.portrait
	elif data.sprite_frames and data.sprite_frames.has_animation("attack"):
		target_rect.texture = data.sprite_frames.get_frame_texture("attack", 0)

# --- Signal Handlers ---
func _on_prev_pressed():
	if current_page_index > 0:
		current_page_index -= 1
		update_display()

func _on_next_pressed():
	# Safety check, though button disabled state should handle it
	if (current_page_index + 1) * PAGE_SIZE < all_character_ids.size():
		current_page_index += 1
		update_display()

func _on_slot_button_pressed(slot_index: int):
	var selected_id = current_slots_data[slot_index]
	
	if selected_id:
		print("Selected Hero: ", selected_id)
		# Ask GameState to load the data from disk
		var saved_scene = GameState.load_game()		
		GameState.selected_character_id = selected_id
		print(saved_scene)
		if saved_scene:
			# If a file existed, jump straight to Level 50
			get_tree().change_scene_to_file(saved_scene)
		else:
			# No file? Start fresh at Level 1
			get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")
