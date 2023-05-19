extends Node
class_name ServerAdvertiser

const DEFAULT_PORT := 9967

# How often to broadcast out to the network that this host is active
@export var broadcast_interval: float = 0.1
var serverInfo := {"name": "LAN Game"}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT

func start():
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.autostart = true
	
	if get_tree().get_multiplayer().is_server():
		add_child(broadcastTimer)
		broadcastTimer.connect("timeout", broadcast) 
		
		socketUDP = PacketPeerUDP.new()
		socketUDP.set_broadcast_enabled(true)
		socketUDP.set_dest_address('255.255.255.255', broadcastPort)
		print("Broadcast started successfully.")
	else:
		print("Broadcast error: Current network peer is not in server mode.")

func broadcast():
	#print('Broadcasting game...')
	var packetMessage: String = JSON.stringify(serverInfo)
	var packet := packetMessage.to_ascii_buffer()
	for address in IP.get_local_addresses():
		var parts = address.split('.')
		if (parts.size() == 4):
			parts[3] = '255'
			socketUDP.set_dest_address(parts[0]+'.'+parts[1]+'.'+parts[2]+'.'+parts[3], broadcastPort)
			socketUDP.put_packet(packet)


func stop():
	broadcastTimer.stop()
	#if socketUDP != null:
	#	socketUDP.close()
