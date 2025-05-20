extends Node3D
class_name Woodbox

@export var amount := 0 :
	set(value):
		if amount != value:
			amount_dirt = true
			amount = value
@export var type:String = "" :
	set(value):
		if type != value:
			type_dirt = true
			type = value

var multimesh: MultiMesh
var amount_dirt := false
var type_dirt := false

func _ready() -> void:
	
	multimesh = MultiMesh.new()
	multimesh.mesh = preload("res://mesh/fruit/potato.res")
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 100
	multimesh.visible_instance_count = 0
	
	for n in 100:
		var trf := Transform3D()
		trf = trf.scaled(Vector3.ONE * 1.0)
		trf = trf.translated(Vector3(0, n*0.1, 0))
		multimesh.set_instance_transform(n, trf)
	
	$Vegetables.multimesh = multimesh

func _process(delta: float) -> void:
	if amount_dirt:
		amount_dirt = false
		$ItemAmount.text = "%d" % amount
		multimesh.visible_instance_count = min(100, amount)
	if type_dirt:
		type_dirt = false
		$ItemName.text = type
		var mesh:Mesh = preload("res://mesh/fruit/potato.res")
		match type:
			"APPLE_RED":
				mesh = preload("res://mesh/fruit/apple03.res")
			"POTATOE_WHITE":
				mesh = preload("res://mesh/fruit/potato.res")
			#"BANANA":
				#mesh = preload("res://mesh/vegetables/banana_01.res")
			#"LEMON":
				#mesh = preload("res://mesh/vegetables/lemon_01.res")
			#"KIWI":
				#mesh = preload("res://mesh/vegetables/kiwi.res")
			#"ORANGE":
				#mesh = preload("res://mesh/vegetables/orange_01.res")
			#"ORANGE":
				#mesh = preload("res://mesh/vegetables/orange_01.res")
		multimesh.mesh = mesh

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
