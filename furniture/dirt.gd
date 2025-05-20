extends Node3D
class_name Dirt

var type:String
var amount:=0

var drop_time := 0.0

func _ready() -> void:
	drop_time = get_drop_time()

func _process(delta: float) -> void:
	if type != "":
		drop_time -= delta
		if drop_time < 0:
			amount += 1
			drop_time = get_drop_time()
	if amount == 0:
		type = ""
	$Label3D.text = "%s - %d" % [type, amount]

#func remove() -> void:
	#pass
#
#func add() -> void:
	#pass

func get_drop_time() -> float:
	return randf_range(10.0, 15.0)

#var current_woodbox:Woodbox
#var has_box:bool = false
#
#func get_rack_transform() -> Transform3D:
	#return $RackTransform.global_transform
#
#func set_current_woodbox(current_woodbox_:Woodbox) -> void:
	#current_woodbox = current_woodbox_
	#current_woodbox.get_parent_node_3d().remove_child(current_woodbox)
	#add_child(current_woodbox)
	#current_woodbox.global_transform = $RackTransform.global_transform
	#has_box = true
#
#func free_rack() -> void:
	#has_box = false
