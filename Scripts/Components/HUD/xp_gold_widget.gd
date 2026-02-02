extends Control
class_name CurrencyWidget

# Adjust paths relative to THIS node
@onready var gold_label = $HBoxContainer/GoldLabel
@onready var xp_label = $HBoxContainer/XPLabel
@onready var level_label = $HBoxContainer/LevelLabel

func update_ui(gold: int, xp: int, level: int, max_xp: int):
	gold_label.text = str(gold)
	xp_label.text = "XP: %d / %d" % [xp, max_xp]
	level_label.text = str(level)
	print("gold_label", gold_label)
	print("XP label" ,xp_label.text )
	# Optional Pop Effect
	if is_inside_tree():
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
