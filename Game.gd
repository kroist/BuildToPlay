extends Node2D

@export var Block: PackedScene
signal editing_started(avail_blocks)
signal editing_ended
signal clear_level

var block_scenes: Array[PackedScene] = [
	preload("res://blocks/Crate3Block.tscn"),
	preload("res://blocks/CrateBlock.tscn"),
	preload("res://blocks/PipeBlock.tscn"),
	preload("res://blocks/Spikes3Block.tscn")
]

var player_spawn_pos: Vector2

var EDIT_PHASE = 1
var PLAY_PHASE = 2

var current_phase = 0 

func _ready():
	$Player.visible = false
	$PlacementGrid.visible = false
	$zindenode/HUDLayer/Toolbox.visible = false
	player_spawn_pos = $Player.position


func _on_edit_button_pressed():
	start_editing_phase()


func _process(delta):
	pass
	
func _restart():
	stop_play_phase()
	clear_level.emit()
	
	
func editing_phase_finish():
	stop_editing_phase()
	start_play_phase()

func start_editing_phase():
	$zindenode/HUDLayer/Toolbox.visible = true
	$PlacementGrid.visible = true
	$zindenode/HUDLayer/EditLevelButton.visible = false
	var chosen_blocks = block_scenes
	chosen_blocks.shuffle()
	chosen_blocks = chosen_blocks.slice(0, 3)
	editing_started.emit(chosen_blocks)

func stop_editing_phase():
	if $zindenode/HUDLayer/Toolbox.popped_up:
		$zindenode/HUDLayer/Toolbox._on_texture_button_pressed()
	$zindenode/HUDLayer/Toolbox.visible = false
	$PlacementGrid.visible = false
	editing_ended.emit()

func start_play_phase():
	$Player.position = player_spawn_pos
	$Player.visible = true
	$Player.set_process(true)

func stop_play_phase():
	$Player.visible = false
	$Player.set_process(false)
	$zindenode/HUDLayer/EditLevelButton.visible = true

func _on_player_death():
	stop_play_phase()


func _on_level_player_death():
	_on_player_death()


func _on_level_block_placed():
	editing_phase_finish()


func _on_win_polygon_body_entered(body):
	_restart()
