extends CanvasLayer

func _ready():
	# check_device_type()
	# For testing on PC, you might want to comment out the check
	if DisplayServer.is_touchscreen_available() or OS.get_name() in ["Android", "iOS"]:
		show()
	else:
		hide()
