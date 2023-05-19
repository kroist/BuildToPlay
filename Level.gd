extends Node2D

var editing_started = false

@export var BACKGROUND_LAYER = 0
@export var BLOCK_LAYER = 1
@export var INTERSECTION_LAYER = 2
var chosen_pattern = 6
var pattern_rotation = 0
var floating_block: Node2D
var floating_block_scenes: Array[PackedScene]
var chosen_floating_block_scene: PackedScene
var floating_block_pos: Vector2

var placed_scenes: Array[Node2D]

signal player_death
signal block_placed

var min_bound = Vector2i(100000, 100000)
var max_bound = Vector2i(-100000, -100000)

# Called when the node enters the scene tree for the first time.
func _ready():
	for node in $TileMap.get_used_cells(BACKGROUND_LAYER):
		if min_bound > node:
			min_bound = node
		if max_bound < node:
			max_bound = node
	$CanvasLayer/RotateButtonControl.visible = false
	$CanvasLayer/RotateButtonControl.set_process(false)
	$CanvasLayer/PlaceButtonControl.visible = false
	$CanvasLayer/PlaceButtonControl.set_process(false)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if editing_started:
			var pos = get_local_mouse_position()
			var tile = $TileMap.local_to_map(pos)
			var inter_cells = intersecting_cells(tile)
			#if inter_cells.is_empty():
			#	_on_game_place_block(tile)

var is_dragging = false
var drag_index = -1
var drag_start_pos: Vector2
var drag_cur_pos: Vector2

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		_begin_drag(event)
	if event is InputEventScreenTouch and !event.pressed:
		_end_drag(event)
	if event is InputEventScreenDrag:
		_process_drag(event)

func _begin_drag(event):
	if is_dragging or not editing_started:
		return
	is_dragging = true
	drag_index = event.index
	drag_start_pos = event.position
	drag_cur_pos = event.position
	
func _end_drag(event):
	if event.index != drag_index or not is_dragging or not editing_started:
		return
	is_dragging = false
	drag_index = -1
	drag_cur_pos = event.position
	var draw_pos = (drag_cur_pos-drag_start_pos)+floating_block_pos
	floating_block_pos = draw_pos.clamp(
		$TileMap.map_to_local(min_bound-min_floating_pos()), 
		$TileMap.map_to_local(max_bound-max_floating_pos())
	)

func _process_drag(event):
	if event.index != drag_index or !is_dragging or not editing_started:
		return
	drag_cur_pos = event.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if editing_started:
		
		var draw_pos = floating_block_pos
		if is_dragging:
			draw_pos = (drag_cur_pos-drag_start_pos)+floating_block_pos
		draw_pos = draw_pos.clamp(
			$TileMap.map_to_local(min_bound-min_floating_pos()), 
			$TileMap.map_to_local(max_bound-max_floating_pos())
		)
		#var pos = get_local_mouse_position()
		var tile = $TileMap.local_to_map(draw_pos)
		var inter_cells = intersecting_cells(tile)
		if inter_cells.is_empty():
			$CanvasLayer/PlaceButtonControl.modulate = Color("ffffff")
		else:
			$CanvasLayer/PlaceButtonControl.modulate = Color("646464")
		draw_floating(tile)
		draw_intersection(inter_cells)

func intersecting_cells(place_tile: Vector2i) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	for tile in get_floating_positions():
		var tile_pos = place_tile + tile
		if $TileMap.get_cell_source_id(BLOCK_LAYER, tile_pos) != -1:
			res.push_back(tile_pos)
	return res


func draw_floating(tile: Vector2i):
	floating_block.position = $TileMap.map_to_local(tile)
	pass


func draw_intersection(tiles: Array[Vector2i]):
	$TileMap.clear_layer(INTERSECTION_LAYER)
	for tile in tiles:
		$TileMap.set_cell(INTERSECTION_LAYER, tile, 2, Vector2i(5, 1), 1)

func _on_game_place_block(place_tile: Vector2i):
	var floating_positions = get_floating_positions()
	for tile in floating_positions:
		var tile_pos = place_tile + tile
		$TileMap.set_cell(BLOCK_LAYER, tile_pos, 1, Vector2i(15, 5), 5)
	var placed_block = chosen_floating_block_scene.instantiate()
	placed_block.position = $TileMap.map_to_local(place_tile)
	placed_block.z_index = -99
	placed_scenes.append(placed_block)
	placed_block.set_rotation_degrees(pattern_rotation*90)
	add_child(placed_block)
	if placed_block.has_signal("player_death"):
		placed_block.player_death.connect(emit_player_death)
	rpc("place_block", place_tile, floating_positions, pattern_rotation, chosen_floating_block_scene.resource_path)
	block_placed.emit()
	
@rpc("any_peer", "reliable")
func place_block(
	place_tile: Vector2i,
	floating_block_positions: Array,
	pattern_rotation: int,
	floating_block_scene_path: String
):
	var floating_block_scene = load(floating_block_scene_path)
	for tile in floating_block_positions:
		var tile_pos = place_tile + tile
		$TileMap.set_cell(BLOCK_LAYER, tile_pos, 1, Vector2i(15, 5), 5)
	var placed_block = floating_block_scene.instantiate()
	placed_block.position = $TileMap.map_to_local(place_tile)
	placed_block.z_index = -99
	placed_scenes.append(placed_block)
	placed_block.set_rotation_degrees(pattern_rotation*90)
	add_child(placed_block)
	if placed_block.has_signal("player_death"):
		print('kek')
		placed_block.player_death.connect(emit_player_death)

func _on_game_editing_started(chosen_blocks):
	editing_started = true
	floating_block_scenes = chosen_blocks
	floating_block_pos = $TileMap.map_to_local(Vector2i(20, 5))
	floating_block = floating_block_scenes[0].instantiate()
	chosen_floating_block_scene = floating_block_scenes[0]
	floating_block.visible = true
	floating_block.z_index = -10
	$CanvasLayer/RotateButtonControl.visible = true
	$CanvasLayer/RotateButtonControl.set_process(true)
	$CanvasLayer/PlaceButtonControl.visible = true
	$CanvasLayer/PlaceButtonControl.set_process(true)
	add_child(floating_block)

func emit_player_death(name):
	player_death.emit(name)

func _on_game_editing_ended():
	editing_started = false
	if floating_block != null:
		floating_block.queue_free()
	pattern_rotation = 0
	$CanvasLayer/RotateButtonControl.visible = false
	$CanvasLayer/RotateButtonControl.set_process(false)
	$CanvasLayer/PlaceButtonControl.visible = false
	$CanvasLayer/PlaceButtonControl.set_process(false)
		
func clear_blocks():
	for scene in placed_scenes:
		if scene != null:
			scene.queue_free()
	for node_coords in $TileMap.get_used_cells(BLOCK_LAYER):
		var atlas_coords = $TileMap.get_cell_atlas_coords(BLOCK_LAYER, node_coords)
		var alternative_tile = $TileMap.get_cell_alternative_tile(BLOCK_LAYER, node_coords)
		if atlas_coords == Vector2i(15, 5) and alternative_tile == 5:
			$TileMap.erase_cell(BLOCK_LAYER, node_coords)
	for node_coords in $TileMap.get_used_cells(INTERSECTION_LAYER):
		$TileMap.erase_cell(INTERSECTION_LAYER, node_coords)

func get_floating_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = floating_block.get("positions")
	for i in pattern_rotation:
		positions = rotate_positions(positions)
	return positions

func min_floating_pos() -> Vector2i:
	var float_poses = get_floating_positions()
	var res = float_poses[0]
	for pos in float_poses:
		if res.x > pos.x:
			res.x = pos.x
		if res.y > pos.y:
			res.y = pos.y
	return res

func max_floating_pos() -> Vector2i:
	var float_poses = get_floating_positions()
	var res = float_poses[0]
	for pos in float_poses:
		if res.x < pos.x:
			res.x = pos.x
		if res.y < pos.y:
			res.y = pos.y
	return res

func rotate_positions(orig_cells: Array[Vector2i]) -> Array[Vector2i]:
	
	var res: Array[Vector2i] = []
	var flag = false
	var mnY = 0
	var mnX = 0
	for tile in orig_cells:
		res.push_back(Vector2i(-tile.y, tile.x))
		if !flag:
			flag = true
			mnY = res.back().y
			mnX = res.back().x
		mnY = min(mnY, res.back().y)
		mnX = min(mnX, res.back().x)
	var new_pattern = TileMapPattern.new()
	for i in range(res.size()):
		res[i].x
		res[i].y
	return res


func _on_toolbox_select_block(block):
	if floating_block != null:
		floating_block.queue_free()
	chosen_floating_block_scene = block
	floating_block = block.instantiate()
	floating_block.visible = true
	floating_block.z_index = -10
	pattern_rotation = 0
	add_child(floating_block)



func _on_game_clear_level():
	clear_blocks()


func _on_place_button_pressed():
	var tile = $TileMap.local_to_map(floating_block_pos)
	var inter_cells = intersecting_cells(tile)
	if inter_cells.is_empty():
		_on_game_place_block(tile)


func _on_rotate_button_pressed():
	pattern_rotation = (pattern_rotation+1)%4
	floating_block.set_rotation_degrees(pattern_rotation*90)
