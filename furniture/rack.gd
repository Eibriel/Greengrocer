extends Node3D
class_name Rack

var current_woodbox:Woodbox
var has_box:bool = false

func get_rack_transform() -> Transform3D:
	return $RackTransform.global_transform

func set_current_woodbox(current_woodbox_:Woodbox) -> void:
	current_woodbox = current_woodbox_
	current_woodbox.get_parent_node_3d().remove_child(current_woodbox)
	add_child(current_woodbox)
	current_woodbox.global_transform = $RackTransform.global_transform
	has_box = true

func free_rack() -> void:
	has_box = false
