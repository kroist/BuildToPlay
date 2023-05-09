extends Node2D

var dim: Vector2i
var positions: Array[Vector2i]

var slide_len: float
var direction = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	dim = Vector2i(3, 3)
	positions = [
		Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), 
		Vector2i(1, 0), Vector2i(2, 0)
	]
	slide_len = $Slider.get_rect().size.x - $Crate.get_rect().size.x
	$Timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var delta_x = sin($Timer.time_left/4.0*2*PI)*slide_len/2.0
	$Crate.position.x = delta_x
	$CharacterBody2D/CollisionPolygon2D.position.x = delta_x
	pass


