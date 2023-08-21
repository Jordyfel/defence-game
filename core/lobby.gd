extends Node



signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected

const PORT = 6969
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 8

var players:= {}
var player_info:= {"name": "Name"}
var players_loaded:= 0



func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address: String = "") -> void:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer:= ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		printerr(error_string(error))
	multiplayer.multiplayer_peer = peer


func create_game() -> void:
	var peer:= ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		printerr(error_string(error))
	multiplayer.multiplayer_peer = peer
	
	players[1] = player_info
	player_connected.emit(1, player_info)


func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null


@rpc("call_local", "reliable")
func load_game() -> void:
	get_tree().change_scene_to_file("res://core/game/game.tscn")


@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			players_loaded = 0
			$/root/Game.start_game()


# Called on the newly connected peer for each other peer, and on each other peer for the newly
# connected peer.
func _on_player_connected(id) -> void:
	_register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	var new_player_id:= multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


func _on_player_disconnected(id) -> void:
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok() -> void:
	var peer_id:= multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
