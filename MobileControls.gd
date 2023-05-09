extends CanvasLayer

var centeredJoystickPos: Vector2
var minJoystickPosX: float
var maxJoystickPosX: float

signal jump
signal move(delta: float)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _input(event):
	pass
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $LeftRightButton.is_dragging:
		_move($LeftRightButton.movement_delta)
	pass
	
func _jump():
	#print('JUMP')
	jump.emit()
	pass
	
func _move(delta):
	#print(delta)
	move.emit(delta)
	pass


func _on_left_right_button_move(delta):
	_move(delta)


func _on_jump_button_jump():
	_jump()
