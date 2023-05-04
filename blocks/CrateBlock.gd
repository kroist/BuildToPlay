extends Node2D


var dim: Vector2i
var positions: Array[Vector2i]

# Called when the node enters the scene tree for the first time.
func _ready():
	dim = Vector2i(1, 1)
	positions = [Vector2i(0, 0)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
