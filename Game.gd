extends Node2D

@export var Block: PackedScene
signal editing_started(avail_blocks)
signal editing_ended
signal clear_level

var block_scenes: Array[PackedScene] = [
	preload("res://blocks/Crate3Block.tscn"),
	preload("res://blocks/CrateBlock.tscn"),
	preload("res://blocks/PipeBlock.tscn"),
	preload("res://blocks/Spikes3Block.tscn"),
	preload("res://blocks/MovingCrate2Block.tscn")
]

var player_spawn_pos: Vector2

var EDIT_PHASE = 1
var PLAY_PHASE = 2

var current_phase = 0 

func _ready():
	#print(multiplayer.is_server())
	#print(multiplayer.multiplayer_peer.get_connection_status())
	#$Player.visible = false
	$PlacementGrid.visible = false
	$zindenode/HUDLayer/Toolbox.visible = false
	$MobileControls.visible = false
	$MobileControls.set_process(false)
	player_spawn_pos = $Player.position
	#stop_editing_phase()
	_on_host_button_pressed()
	start_play_phase()


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
	$zindenode/HUDLayer/EditLevelButton.visible = false
	#$Player.position = player_spawn_pos
	#$Player.visible = true
	#$Player.set_process(true)
	$MobileControls.visible = true
	$MobileControls.set_process(true)

func stop_play_phase():
	#$Player.visible = false
	#$Player.set_process(false)
	$MobileControls.visible = false
	$MobileControls.set_process(false)
	$zindenode/HUDLayer/EditLevelButton.visible = true
	start_play_phase()#TODO

func _on_player_death():
	stop_play_phase()


func _on_level_player_death():
	_on_player_death()


func _on_level_block_placed():
	editing_phase_finish()


func _on_win_polygon_body_entered(body):
	_restart()


var connected_peer_ids = []
var port = 9999
var multiplayer_peer = ENetMultiplayerPeer.new()

func _on_host_button_pressed():
	print('kek')
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	add_player_character(multiplayer.get_unique_id())
	
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_new_connected_player", new_peer_id)
			rpc_id(new_peer_id, "add_prev_connected_players", connected_peer_ids)
			add_player_character(new_peer_id)
	)
	
func _on_join_button_pressed():
	multiplayer_peer.create_client("127.0.0.1", port)
	multiplayer.multiplayer_peer = multiplayer_peer

func add_player_character(peer_id):
	connected_peer_ids.append(peer_id)
	if peer_id == multiplayer.get_unique_id():
		$Player.set_multiplayer_authority(peer_id)
		$Player.name = "player_" + str(peer_id)
		return
	var player = preload("res://Player.tscn").instantiate()
	player.name = "player_" + str(peer_id)
	player.position = player_spawn_pos
	player.set_multiplayer_authority(peer_id)
	add_child(player)
	
@rpc
func add_new_connected_player(peer_id):
	add_player_character(peer_id)
	
@rpc
func add_prev_connected_players(peer_ids):
	for id in peer_ids:
		add_player_character(id)


