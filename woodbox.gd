extends Node3D
class_name Woodbox

@export var amount := 0
@export var type:String = ""


func _process(delta: float) -> void:
	$ItemName.text = type
	$ItemAmount.text = "%d" % amount

func remove(remove_amount:int) -> bool:
	if amount < remove_amount: return false
	amount -= remove_amount
	if amount == 0:
		type = ""
	return true

func add(add_amount:int, add_type:String) -> bool:
	if (add_type != type and amount > 0): return false
	type = add_type
	amount += add_amount
	return true
