extends Node2D

@onready var label = $Label
# 1. Variables to hold the data temporarily
var value_to_show: int = 0
var color_to_show: Color = Color.WHITE

func _ready():
	# 2. Now that we are in the tree, the Label exists.
	# We apply the stored values to the visual label here.
	label.text = str(value_to_show)
	label.modulate = color_to_show
	
	_animate()

# 3. Rename this function to be clear it just sets data
func set_values(value: int, color: Color):
	value_to_show = value
	color_to_show = color

func _animate():
	# (Your existing Tween code goes here)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()
