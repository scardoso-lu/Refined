extends Control

@onready var score_label = %Score/ScoreLabel

func _process(_delta):
	pass
	# Set the score label text to the score variable in game maanger script
	#score_label.text = "x %d" % GameManager.score
