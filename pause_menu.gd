extends Control

func _ready() -> void:
	visible = false

func pause() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true
	get_tree().paused = true

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false
	get_tree().paused = false
