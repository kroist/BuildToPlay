extends Control

signal back_to_menu
signal start_game_sig

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func create_lobby():
	$TextureRect/StartButton.visible = true
	start_server()

func connect_to_lobby(ip):
	$TextureRect/StartButton.visible = false
	call_deferred("connect_to_server", ip)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
var multiplayer_peer = ENetMultiplayerPeer.new()
var port = 9968
var connected_players_list = []

func start_server():
	connected_players_list = []
	var children = $TextureRect/VBoxContainer.get_children()
	for child in children:
		$TextureRect/VBoxContainer.remove_child(child)
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	add_player(multiplayer.get_unique_id())
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			add_player(new_peer_id)
			rpc_id(new_peer_id, "add_prev_connected_players", connected_players_list)
	)
	
func connect_to_server(serverIp):
	connected_players_list = []
	var children = $TextureRect/VBoxContainer.get_children()
	for child in children:
		$TextureRect/VBoxContainer.remove_child(child)
	var err = multiplayer_peer.create_client(serverIp, port)
	print(err)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func add_player(playerId):
	connected_players_list.append(playerId)
	var label = Label.new()
	label.text = "Player " + str(playerId)
	label.add_theme_font_size_override("font_size", 30)
	if playerId == multiplayer.get_unique_id():
		label.text += " (You)"
	$TextureRect/VBoxContainer.add_child(label)

@rpc("reliable")
func add_prev_connected_players(playerIds):
	for id in playerIds:
		add_player(id)

func _on_start_button_pressed():
	rpc("start_game")
	start_game()

@rpc("reliable")
func start_game():
	start_game_sig.emit()


func _on_close_button_pressed():
	back_to_menu.emit()
