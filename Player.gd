extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -450.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

signal death

var jump_pressed = false
var move_pressed = false
var move_dir: float

func _physics_process(delta):
	if not is_multiplayer_authority():
		proc_animations()
		return
	if Input.is_action_pressed("up"):
		jump_pressed = true
	if Input.is_action_pressed("left"):
		move_pressed = true
		move_dir = -1.0
	if Input.is_action_pressed("right"):
		move_pressed = true
		move_dir = 1.0
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if jump_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = (1 if move_pressed else 0) * move_dir
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	proc_animations()

	move_and_slide()

	jump_pressed = false
	move_pressed = false
	rpc("remote_set_pos", global_position, velocity)

var to_add = 123456789

func recolor(peer_id):
	var rh = (peer_id+to_add)%360
	var rs = (peer_id+to_add)%(98-42)+42
	var rl = (peer_id+to_add)%(90-40)+40
	var h = (rh+0.0)/360.0
	var s = (rs+0.0)/100.0
	var l = (rl+0.0)/100.0
	$Polygon2D.color = Color.from_ok_hsl(h, s, l)

func proc_animations():
	if velocity.y != 0:
		$AnimatedSprite2D.animation = "jump"
	elif velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
	else:
		$AnimatedSprite2D.animation = "stand"
	
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
		$Polygon2D.scale.x = 1
		$CollisionPolygon2D.scale.x = 0.45
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
		$Polygon2D.scale.x = -1
		$CollisionPolygon2D.scale.x = -0.45

	
	if velocity.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

@rpc("unreliable")
func remote_set_pos(_global_pos, _velocity):
	global_position = _global_pos
	velocity = _velocity

func _on_death_polygon_body_entered(body):
	death.emit(body.name)
	pass # Replace with function body.


func _on_mobile_controls_jump():
	jump_pressed = true
	pass # Replace with function body.


func _on_mobile_controls_move(delta):
	move_pressed = true
	move_dir = delta
	pass # Replace with function body.
