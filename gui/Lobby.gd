extends Control

var is_admin = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_admin:
		$TextureRect/StartButton.visible = true
	else:
		$ServerAdvertiser.set_process(false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


var game_scene = preload("res://Game.tscn")

func _on_start_button_pressed():
	var game = game_scene.instantiate()
	for child in get_tree().get_root().get_children():
		child.queue_free()
	get_tree().get_root().add_child(game)
	pass # Replace with function body.
