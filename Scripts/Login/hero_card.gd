extends Control

signal card_selected(id)

var my_id: String = ""

@onready var art = $CharacterArt
@onready var lbl = $NameLabel
@onready var btn = $SelectButton

func setup(id: String, def: CharacterDef):
	my_id = id
	lbl.text = id.capitalize() # Or add a 'display_name' to your Resource later
	
	# Assuming your CharacterDef has a 'portrait' or 'menu_image' texture
	if def.portrait:
		art.texture = def.portrait
	# Fallback for older characters without a portrait
	elif def.sprite_frames and def.sprite_frames.has_animation("idle"):
		art.texture = def.sprite_frames.get_frame_texture("idle", 0)

# Connect the button locally
	if not btn.pressed.is_connected(_on_btn_pressed):
		btn.pressed.connect(_on_btn_pressed)

func _on_btn_pressed():
	card_selected.emit(my_id)
