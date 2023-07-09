extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Floor.input_event.connect(_on_floor_clicked)
	
	Lobby.player_loaded.rpc_id(1)

# Called only on the server.
func start_game() -> void:
	pass


func _on_floor_clicked(_camera: Node, event: InputEvent, event_position: Vector3,_normal: Vector3,
			_shape_idx: int):
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, event_position)


@rpc("any_peer", "call_local", "reliable")
func move_unit(target_position: Vector3) -> void:
	$Unit.command_move.rpc(target_position)
	#$Unit.command_move(target_position)
