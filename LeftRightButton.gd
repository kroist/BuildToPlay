extends Control

signal move(delta: float)

# Called when the node enters the scene tree for the first time.
func _ready():
	origin = position+size/2
	min_x = position.x+$Joystick.get_rect().size.x/2
	max_x = position.x+size.x-$Joystick.get_rect().size.x/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dragging:
		$Joystick.global_position.x = clamp(pressed_pos.x, min_x, max_x)
		var joystickLen = (max_x-min_x)
	else:
		$Joystick.global_position = origin

var touch_index: int = -1
var is_dragging: bool = false
var origin: Vector2
var min_x: float
var max_x: float
var pressed_pos: Vector2
var movement_delta: float

func _input(event):
	if event is InputEventScreenTouch and event.is_pressed() and get_global_rect().has_point(event.position):
		_begin_drag(event)
	if event is InputEventScreenTouch and !event.is_pressed() and event.index == touch_index:
		_end_drag(event)
	if event is InputEventScreenDrag and event.index == touch_index:
		_process_drag(event)

func _begin_drag(event):
	if is_dragging:
		return
	is_dragging = true
	touch_index = event.index
	_move(event)
	
func _end_drag(event):
	is_dragging = false
	touch_index = -1
	
func _process_drag(event):
	_move(event)

func _move(event):
	if !is_dragging or event.index != touch_index:
		return
	pressed_pos = event.position
	var cur_x = clamp(event.position.x, min_x, max_x)
	movement_delta = (cur_x-origin.x)/(max_x-min_x)*2
	
