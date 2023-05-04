extends Node2D

signal player_death

var dim: Vector2i
var positions: Array[Vector2i]

# Called when the node enters the scene tree for the first time.
func _ready():
	dim = Vector2i(3, 3)
	positions = [
		Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
	]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	player_death.emit()
	pass # Replace with function body.
