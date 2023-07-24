extends Node3D



signal floor_clicked(click_position: Vector3)
signal unit_clicked(unit: Unit)
signal cancel



func _ready() -> void:
	$Floor.input_event.connect(_on_floor_clicked)
	
	Lobby.player_loaded.rpc_id(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancel.emit()


# Called only on the server.
func start_game() -> void:
	for i in 1:
		var new_unit: Unit = load("res://design/units/kitty.tscn").instantiate()
		new_unit.position.x += i
		new_unit.ask_player_for_target.connect(_on_ask_player_for_target)
		new_unit.input_event.connect(_on_unit_clicked.bind(new_unit))
		$Unit.input_event.connect(_on_unit_clicked.bind($Unit))
		$UnitSpawn.add_child(new_unit, true)
		%BottomBar.connect_to_unit(new_unit)


func _on_ask_player_for_target(source_unit: Unit, ability: UnitAbility) -> void:
	var target
	
	match ability.effect.target_mode:
		AbilityData.TargetMode.POSITION:
			var signals = SignalCombiner.new([floor_clicked, unit_clicked, cancel])
			var result = await signals.completed_any
			match result["source"]:
				floor_clicked:
					target = result["data"]
				unit_clicked:
					target = result["data"].position
				cancel:
					pass
		
		AbilityData.TargetMode.UNIT:
			var signals = SignalCombiner.new([floor_clicked, unit_clicked, cancel])
			var result = await signals.completed_any
			match result["source"]:
				unit_clicked:
					target = result["data"]
				_:
					pass
	
	if target:
		source_unit.activate_ability(ability, target)


func _on_floor_clicked(_camera: Node, event: InputEvent, event_position: Vector3,_normal: Vector3,
			_shape_idx: int):
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, event_position)
	
	if event.is_action_pressed(&"left_click_temp"):
		floor_clicked.emit(event_position)


func _on_unit_clicked(_camera: Node, event: InputEvent, _event_position: Vector3,_normal: Vector3,
			_shape_idx: int, unit: Unit):
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, unit.position)
	
	if event.is_action_pressed(&"left_click_temp"):
		unit_clicked.emit(unit)


@rpc("any_peer", "call_local", "reliable")
func move_unit(target_position: Vector3) -> void:
	for unit in $UnitSpawn.get_children():
		unit.command_move.rpc(target_position)
	
	#$Unit.command_move.rpc(target_position)
	#$Unit.command_move(target_position)
