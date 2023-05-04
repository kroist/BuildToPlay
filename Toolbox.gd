extends Control

var menu_size = .4

@export var popped_up = false

var _down_anchor = Vector2(1-0.1, 1+menu_size-0.1)
var _up_anchor = Vector2(1-menu_size, 1)
var chosen_blocks: Array[PackedScene]

signal select_block(block)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var _target_anchor = _down_anchor
	var _is_flip = false
	if popped_up:
		_target_anchor = _up_anchor
		_is_flip = true
	else:
		_target_anchor = _down_anchor
		_is_flip = false
	
	anchor_top = _target_anchor.x
	anchor_bottom = _target_anchor.y
	$VBoxContainer/TextureButton.flip_v = _is_flip
	pass


func _on_texture_button_pressed():
	popped_up = !popped_up
	if popped_up:
		for block_scene in chosen_blocks:
			var node = TextureButton.new()
			node.set_v_size_flags(Control.SIZE_SHRINK_CENTER)
			var block = block_scene.instantiate()
			block.visible = false
			node.texture_normal = block.get_node("Sprite2D").get("texture")
			node.pressed.connect(_block_chosen.bind(block_scene))
			block.queue_free()
			$VBoxContainer/NinePatchRect/BlocksHContainer.add_child(node)
	else:
		for node in $VBoxContainer/NinePatchRect/BlocksHContainer.get_children():
			node.queue_free()

func _block_chosen(block):
	select_block.emit(block)


func _on_game_editing_started(avail_blocks):
	chosen_blocks = avail_blocks
	pass # Replace with function body.
