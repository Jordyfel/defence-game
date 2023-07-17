extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Floor.input_event.connect(_on_floor_clicked)
	
	Lobby.player_loaded.rpc_id(1)


# Called only on the server.
func start_game() -> void:
	for i in 1:
		var new_unit = load("res://source/units/kitty.tscn").instantiate()
		new_unit.position.x += i
		$UnitSpawn.add_child(new_unit, true)
		%BottomBar.connect_to_unit(new_unit)


func _on_ask_player_for_target(source_unit: Unit, ability: UnitAbility) -> void:
	var target
	# respond to floor clicked, unit clicked, or ui cancel
	if target:
		source_unit.activate_ability(ability, target)


func _on_floor_clicked(_camera: Node, event: InputEvent, event_position: Vector3,_normal: Vector3,
			_shape_idx: int):
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, event_position)
	
	if event.is_action_pressed(&"left_click_temp"):
		$UnitSpawn/Unit.activate_ability($UnitSpawn/Unit.ability_q, event_position)


@rpc("any_peer", "call_local", "reliable")
func move_unit(target_position: Vector3) -> void:
	for unit in $UnitSpawn.get_children():
		unit.command_move.rpc(target_position)
	
	#$Unit.command_move.rpc(target_position)
	#$Unit.command_move(target_position)
