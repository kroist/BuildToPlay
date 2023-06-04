extends Node2D

@export var Block: PackedScene
signal editing_started(avail_blocks)
signal editing_ended
signal clear_level
signal end_level

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
	
	players_ids = multiplayer.get_peers()
	players_ids.append(multiplayer.get_unique_id())
	get_tree().set_pause(true)
	#$Player.visible = false
	$PlacementGrid.visible = false
	$zindenode/HUDLayer/Toolbox.visible = false
	$MobileControls.visible = false
	$MobileControls.set_process(false)
	player_spawn_pos = $Player.position
	#stop_editing_phase()
	init_characters()
	#start_play_phase()
	start_editing_phase()
	rpc("done_configuring")
	toggle_players_visibility(false)

var players_ids
var players_configured = []

@rpc("any_peer", "call_local")
func done_configuring():
	if not multiplayer.is_server():
		return
	var who = multiplayer.get_remote_sender_id()
	assert(multiplayer.is_server())
	assert(who in players_ids)
	assert(not who in players_configured)
	
	players_configured.append(who)
	if players_ids.size() == players_configured.size():
		rpc("unpause_game")

@rpc("any_peer", "call_local")
func unpause_game():
	if multiplayer.get_remote_sender_id() == 1:
		get_tree().set_pause(false)
		
var players_finished = []

func _process(delta):
	if Input.is_action_pressed("end_game"):
		rpc("finish_level")
	$zindenode/HUDLayer/EditCountdown.text = str("%.2f" % $EditTimer.time_left)
	pass
	
func _restart():
	play_phase_finish()
	#clear_level.emit()


func editing_phase_finish():
	stop_editing_phase()
	rpc("wait_for_editing")
	
@rpc("any_peer", "call_local", "reliable")
func wait_for_editing():
	if not multiplayer.is_server():
		return
	var who = multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	assert(multiplayer.is_server())
	assert(who in players_ids)
	assert(not who in players_finished)
	
	players_finished.append(who)
	if players_ids.size() == players_finished.size():
		rpc("editing_phase_finish_confirm")
	pass
	
@rpc("any_peer", "call_local", "reliable")
func editing_phase_finish_confirm():
	start_play_phase()

func start_editing_phase():
	$EditTimer.start()
	$zindenode/HUDLayer/EditCountdown.visible = true
	players_finished = []
	$zindenode/HUDLayer/Toolbox.visible = true
	$PlacementGrid.visible = true
	var chosen_blocks = block_scenes
	chosen_blocks.shuffle()
	chosen_blocks = chosen_blocks.slice(0, 3)
	editing_started.emit(chosen_blocks)

func stop_editing_phase():
	$EditTimer.stop()
	$zindenode/HUDLayer/EditCountdown.visible = false
	if $zindenode/HUDLayer/Toolbox.popped_up:
		$zindenode/HUDLayer/Toolbox._on_texture_button_pressed()
	$zindenode/HUDLayer/Toolbox.visible = false
	$PlacementGrid.visible = false
	editing_ended.emit()



func play_phase_finish():
	rpc("wait_for_play")
	
@rpc("any_peer", "call_local", "reliable")
func wait_for_play():
	if not multiplayer.is_server():
		return
	var who = multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	assert(multiplayer.is_server())
	assert(who in players_ids)
	assert(not who in players_finished)
	
	players_finished.append(who)
	if players_ids.size() == players_finished.size():
		rpc("play_phase_finish_confirm")
	pass
	
@rpc("any_peer", "call_local", "reliable")
func play_phase_finish_confirm():
	stop_play_phase()
	start_editing_phase()

func start_play_phase():
	players_finished = []
	toggle_players_visibility(true)
	var player = get_node("player_" + str(multiplayer.get_unique_id()))
	player.position = player_spawn_pos
	$MobileControls.visible = true
	$MobileControls.set_process(true)

func stop_play_phase():
	toggle_players_visibility(false)
	$MobileControls.visible = false
	$MobileControls.set_process(false)


func _on_player_death(name):
	for child in get_children():
		if child.name == name:
			child.position = player_spawn_pos
			child.visible = false
			child.set_process(false)
			
	if name == "player_" + str(multiplayer.get_unique_id()):
		play_phase_finish()


func _on_level_player_death(name):
	_on_player_death(name)


func _on_level_block_placed():
	editing_phase_finish()


func _on_win_polygon_body_entered(body):
	rpc("finish_level")
	
@rpc("any_peer", "call_local", "reliable")
func finish_level():
	end_level.emit()

func init_characters():
	for id in players_ids:
		add_player_character(id)
	#add_player_character(multiplayer.get_unique_id())
	#rpc("rpc_add_player_character", multiplayer.get_unique_id())
	
var player_characters = []

func add_player_character(peer_id):
	if peer_id == multiplayer.get_unique_id():
		$Player.set_multiplayer_authority(peer_id)
		$Player.recolor()
		$Player.name = "player_" + str(peer_id)
		return
	var player = preload("res://Player.tscn").instantiate()
	player.name = "player_" + str(peer_id)
	player.position = player_spawn_pos
	player.recolor()
	player.set_multiplayer_authority(peer_id)
	#player.collision_layer = (1<<2) #3d bit
	add_child(player)
	player_characters.append(player)
	
func toggle_players_visibility(visible):
	for player in player_characters:
		player.visible = visible
	var player = get_node("player_" + str(multiplayer.get_unique_id()))
	player.visible = visible
	player.set_process(visible)
	
@rpc("reliable")
func rpc_add_player_character(peer_id):
	add_player_character(peer_id)
	


func _on_edit_timer_timeout():
	editing_phase_finish()
