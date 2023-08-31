extends Node3D



signal floor_clicked(click_position: Vector3)
signal unit_clicked(unit: Unit)
signal cancel

var targeting:= false
var mouse_position_on_floor: Vector3

var enemy_controller: EnemyController



func _ready() -> void:
	$Floor.input_event.connect(_on_floor_input)
	
	if multiplayer.is_server():
		enemy_controller = EnemyController.new()
	
	Lobby.player_loaded.rpc_id(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"unit_move"):
		cancel.emit()


# Called only on the server.
func start_game() -> void:
	for i in 1:
		var new_unit: Unit = load("res://design/units/kitty.tscn").instantiate()
		new_unit.team = &"player"
		new_unit.position = $UnitSpawn.position
		new_unit.ask_player_for_target.connect(_on_ask_player_for_target)
		new_unit.input_event.connect(_on_unit_input.bind(new_unit)) # to remove
		$Barbarian.input_event.connect(_on_unit_input.bind($Barbarian)) # to remove
		add_child(new_unit, true)
		%BottomBar.connect_to_unit(new_unit)
	
	spawn_enemy("res://design/units/kitty.tscn")


#probably temp
func spawn_enemy(scene_path: String) -> void:
	var new_unit: Unit = load(scene_path).instantiate()
	new_unit.position = $EnemySpawn.position
	new_unit.input_event.connect(_on_unit_input.bind(new_unit)) #to remove
	add_child(new_unit, true)
	await get_tree().physics_frame
	#new_unit.command_attack_move($EnemyDestination.position)


func _on_ask_player_for_target(source_unit: Unit, ability_index: String, show_indicators: bool) -> void:
	var ability: UnitAbility = source_unit.abilities[ability_index]
	var range_indicator: Sprite3D
	var target_indicator: TargetIndicator
	var target
	
	if ability.data.target_mode == AbilityData.TargetMode.NONE:
		source_unit.activate_ability.rpc_id(1, ability_index, null)
		return
	
	targeting = true
	
	if show_indicators:
		if ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE or \
				ability.data.target_mode == AbilityData.TargetMode.POSITION or \
				ability.data.target_mode == AbilityData.TargetMode.UNIT:
			range_indicator = load("res://core/game/cast_indicators/range_indicator.tscn").instantiate()
			range_indicator.position.y += 0.001
			range_indicator.scale *= ability.cast_range
			source_unit.add_child(range_indicator)
		
		if ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE or \
				ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC or \
				ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
			target_indicator = load("res://core/game/cast_indicators/target_indicator.tscn").instantiate()
			target_indicator.unit_ability = ability
			source_unit.add_child(target_indicator)
	
	if ability.data.target_mode == AbilityData.TargetMode.UNIT:
		var signals = SignalCombiner.new([floor_clicked, unit_clicked, cancel])
		var result = await signals.completed_any
		if result["source"] == unit_clicked:
			if ability.data.is_valid_target(source_unit, result["data"]):
				target = result["data"].get_path()
	else:
		var signals = SignalCombiner.new([floor_clicked, unit_clicked, cancel])
		var result = await signals.completed_any
		match result["source"]:
			floor_clicked:
				target = result["data"]
			unit_clicked:
				target = result["data"].global_position
	
	if range_indicator:
		range_indicator.queue_free()
	if target_indicator:
		target_indicator.queue_free()
	
	targeting = false
	if target:
		source_unit.activate_ability.rpc_id(1, ability_index, target)


func _on_floor_input(_camera: Node, event: InputEvent, event_position: Vector3,_normal: Vector3,
			_shape_idx: int):
	
	if event is InputEventMouseMotion:
		mouse_position_on_floor = event_position
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, event_position)
	
	if event.is_action_pressed(&"left_click_temp"):
		floor_clicked.emit(event_position)
	
	if event.is_action_pressed(&"attack_move_temp"):
		attack_move_unit.rpc_id(1, event_position)


func _on_unit_input(_camera: Node, event: InputEvent, _event_position: Vector3,_normal: Vector3,
			_shape_idx: int, unit: Unit):
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, unit.position)
	
	if event.is_action_pressed(&"left_click_temp"):
		unit_clicked.emit(unit)


@rpc("any_peer", "call_local", "reliable")
func move_unit(target_position: Vector3) -> void:
	for unit in get_children().filter(func(node): return node is Unit):
		if unit.team == &"player":
			unit.command_move.rpc_id(1, target_position)


@rpc("any_peer", "call_local", "reliable")
func attack_move_unit(target_position: Vector3) -> void:
	for unit in get_children().filter(func(node): return node is Unit):
		if unit.team == &"player":
			unit.command_attack_move.rpc_id(1, target_position)
