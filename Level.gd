extends Node2D

var editing_started = false

@export var BLOCK_LAYER = 1
@export var INTERSECTION_LAYER = 2
var chosen_pattern = 6
var pattern_rotation = 0
var floating_block: Node2D
var floating_block_scenes: Array[PackedScene]

var placed_scenes: Array[Node2D]

signal player_death
signal block_placed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if editing_started:
			var pos = get_local_mouse_position()
			var tile = $TileMap.local_to_map(pos)
			var inter_cells = intersecting_cells(tile)
			if inter_cells.is_empty():
				_on_game_place_block(tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if editing_started:
		var pos = get_local_mouse_position()
		var tile = $TileMap.local_to_map(pos)
		var inter_cells = intersecting_cells(tile)
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
	for tile in get_floating_positions():
		var tile_pos = place_tile + tile
		$TileMap.set_cell(BLOCK_LAYER, tile_pos, 1, Vector2i(15, 5), 5)
	var placed_block = floating_block.duplicate()
	placed_block.position = $TileMap.map_to_local(place_tile)
	placed_block.z_index = -99
	placed_scenes.append(placed_block)
	add_child(placed_block)
	if placed_block.has_signal("player_death"):
		placed_block.player_death.connect(emit_player_death)
	block_placed.emit()

func _on_game_editing_started(chosen_blocks):
	editing_started = true
	floating_block_scenes = chosen_blocks
	floating_block = floating_block_scenes[0].instantiate()
	floating_block.visible = true
	floating_block.z_index = -10
	add_child(floating_block)
	pass # Replace with function body.

func emit_player_death():
	player_death.emit()

func _on_game_editing_ended():
	editing_started = false
	if floating_block != null:
		floating_block.queue_free()
	pattern_rotation = 0
		
func clear_blocks():
	for scene in placed_scenes:
		if scene != null:
			scene.queue_free()
	# Clear placed blocks, exclude internal onces
	for node_coords in $TileMap.get_used_cells(BLOCK_LAYER):
		var atlas_coords = $TileMap.get_cell_atlas_coords(BLOCK_LAYER, node_coords)
		var alternative_tile = $TileMap.get_cell_alternative_tile(BLOCK_LAYER, node_coords)
		if atlas_coords == Vector2i(15, 5) and alternative_tile == 5:
			$TileMap.erase_cell(BLOCK_LAYER, node_coords)
	# Clear intersections
	for node_coords in $TileMap.get_used_cells(INTERSECTION_LAYER):
		$TileMap.erase_cell(INTERSECTION_LAYER, node_coords)

func _on_button_pressed():
	pattern_rotation = (pattern_rotation+1)%4
	floating_block.set_rotation_degrees(pattern_rotation*90)

func get_floating_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = floating_block.get("positions")
	for i in pattern_rotation:
		positions = rotate_positions(positions)
	return positions

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
	floating_block = block.instantiate()
	floating_block.visible = true
	floating_block.z_index = -10
	add_child(floating_block)



func _on_game_clear_level():
	clear_blocks()
