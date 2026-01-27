extends Control
class_name BossHealthWidget

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var name_label = $MarginContainer/VBoxContainer/NameLabel

func init_boss(monster_def: MonsterDef, current_health: int):
	# 1. Setup Data
	if monster_def:
		health_bar.max_value = monster_def.max_health
		# Assuming your MonsterDef has a 'name' field. 
		# If not, just set it manually or add 'export var monster_name' to MonsterDef
		name_label.text = monster_def.resource_name 
	
	# 2. Setup Health
	health_bar.value = current_health
	
	# 3. Visibility (Show the bar when initialized)
	visible = true

func _on_boss_health_changed(new_health: int):
	# Smooth animation only for the boss
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.3).set_trans(Tween.TRANS_SINE)
