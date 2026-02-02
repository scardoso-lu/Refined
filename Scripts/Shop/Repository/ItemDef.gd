extends Resource
class_name ItemDef

@export var id: String = "item_id"
@export var name: String = "Item Name"
@export var cost: int = 100
@export_multiline var description: String = "What does it do?"

# We can define the "Stat Bonus" here directly!
@export_group("Effects")
@export var heal_amount: int = 0
@export var bonus_damage: int = 0
