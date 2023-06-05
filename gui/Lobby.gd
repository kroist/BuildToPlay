extends Control

signal back_to_menu
signal start_game_sig
signal internet_problems_sig


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var game_started = false

func create_lobby():
	game_started = false
	var children = $TextureRect/VBoxContainer.get_children()
	for child in children:
		$TextureRect/VBoxContainer.remove_child(child)
	$TextureRect/StartButton.visible = true
	start_server()

func connect_to_lobby(ip):
	var children = $TextureRect/VBoxContainer.get_children()
	for child in children:
		$TextureRect/VBoxContainer.remove_child(child)
	$TextureRect/StartButton.visible = false
	call_deferred("connect_to_server", ip)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
var multiplayer_peer
var port = 9968

func start_server():
	multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	add_player(multiplayer.get_unique_id())
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			if game_started:
				multiplayer_peer.disconnect_peer(new_peer_id, true)
				return
			add_player(new_peer_id)
	)
	multiplayer_peer.peer_disconnected.connect(
		func (rem_peer_id):
			await get_tree().create_timer(1).timeout
			if game_started:
				internet_problems_sig.emit()
				return
			rpc("remove_player", rem_peer_id)
	)
	
func connect_to_server(serverIp):
	multiplayer_peer = ENetMultiplayerPeer.new()
	var err = multiplayer_peer.create_client(serverIp, port)
	multiplayer.multiplayer_peer = multiplayer_peer
	var peers = multiplayer.get_peers()
	if !peers.has(0) and !peers.has(1):
		peers.append(1)
	peers.append(multiplayer.get_unique_id())
	add_prev_connected_players(peers)
	
func add_player(playerId):
	for btn in $TextureRect/VBoxContainer.get_children():
		if btn.name == str(playerId):
			return
	var label = Label.new()
	label.name = str(playerId)
	label.text = "Player " + str(playerId)
	label.add_theme_font_size_override("font_size", 30)
	if playerId == multiplayer.get_unique_id():
		label.text += " (You)"
	$TextureRect/VBoxContainer.add_child(label)
	
@rpc("call_local")
func remove_player(playerId):
	for btn in $TextureRect/VBoxContainer.get_children():
		if btn.name == str(playerId):
			$TextureRect/VBoxContainer.remove_child(btn)

func add_prev_connected_players(playerIds):
	for id in playerIds:
		add_player(id)

func _on_start_button_pressed():
	game_started = true
	rpc("start_game")

@rpc("reliable", "call_local")
func start_game():
	start_game_sig.emit()


func _on_close_button_pressed():
	print('closing')
	multiplayer_peer.close()
	print('closed')
	back_to_menu.emit()
