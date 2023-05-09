extends Control

signal jump

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if event is InputEventScreenTouch and event.is_pressed() and get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		jump.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
