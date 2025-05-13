extends Node3D
class_name OpenSign

func change_state() -> void:
	Global.is_open = !Global.is_open

func _process(delta: float) -> void:
	if Global.is_open:
		$Label3D.text = "Open"
	else:
		$Label3D.text = "Closed"
