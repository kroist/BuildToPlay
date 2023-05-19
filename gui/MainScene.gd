extends Control

var game_scene = preload("res://Game.tscn")
var game

# Called when the node enters the scene tree for the first time.
func _ready():
	
	multiplayer.connection_failed.connect(
		func():
			print('kek')
			internet_problems()
	)
	multiplayer.server_disconnected.connect(
		func():
			internet_problems()
	)
	disable_lobby()
	server_listener.new_server.connect(_on_server_listener_new_server)
	server_listener.remove_server.connect(_on_server_listener_remove_server)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_host_button_pressed():
	server_advertiser.start()
	disable_menu()
	enable_lobby()
	$Lobby.call("create_lobby")


func _on_server_listener_new_server(serverInfo):
	var serverNode := Button.new()
	serverNode.add_theme_font_size_override("font_size", 30)
	serverNode.text = "%s - %s" % [serverInfo.ip, serverInfo.name]
	serverNode.pressed.connect(_connect_to_lobby.bind(serverInfo.ip))
	$MainMenu/ScrollContainer/ServerList.add_child(serverNode)


func _on_server_listener_remove_server(serverIp):
	for serverNode in $MainMenu/ScrollContainer/ServerList.get_children():
		if serverNode.text.find(serverIp) > -1:
			$MainMenu/ScrollContainer/ServerList.remove_child(serverNode)
			break

func _connect_to_lobby(lobbyIp):	
	disable_menu()
	enable_lobby()
	$Lobby.call("connect_to_lobby", lobbyIp)


func _on_lobby_back_to_menu():
	$MainMenu.visible = true
	disable_lobby()
	
func enable_lobby():
	$Lobby.visible = true

func disable_lobby():
	server_advertiser.stop()
	$Lobby.visible = false
	
func enable_menu():
	$MainMenu.visible = true
	
func disable_menu():
	$MainMenu.visible = false

func enable_game():
	game = game_scene.instantiate()
	add_child(game)
	game.end_level.connect(end_level)
	
func disable_game():
	if game:
		remove_child(game)
		game.queue_free()
	pass


func _on_lobby_start_game_sig():
	disable_lobby()
	enable_game()

func internet_problems():
	disable_game()
	disable_lobby()
	enable_menu()
	
func end_level():
	internet_problems()
