extends Control

var server_listener_scene = preload('res://multiplayer/ServerListener.gd')
var lobby_scene = preload('res://gui/Lobby.tscn')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_host_button_pressed():
	for child in get_tree().get_root().get_children():
		child.queue_free()
	var lobby = lobby_scene.instantiate()
	lobby.is_admin = true
	get_tree().get_root().add_child(lobby)
	pass # Replace with function body.


func _on_server_listener_new_server(serverInfo):
	var serverNode := Label.new()
	serverNode.text = "%s - %s" % [serverInfo.ip, serverInfo.name]
	$ServerList.add_child(serverNode)
	pass # Replace with function body.


func _on_server_listener_remove_server(serverIp):
	for serverNode in $ServerList.get_children():
		# Just a hacky way to identify the Node and remove it
		if serverNode.text.find(serverIp) > -1:
			$ServerList.remove_child(serverNode)
			break
	pass # Replace with function body.
