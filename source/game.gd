extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_loaded.rpc_id(1)

# Called only on the server.
func start_game() -> void:
	pass 
