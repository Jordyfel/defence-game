extends Node3D



signal floor_clicked(click_position: Vector3)
signal cancel

const UNIT_SELECTION_RANGE = 1.0

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
		add_child(new_unit, true)
		%BottomBar.connect_to_unit(new_unit)
	
	spawn_enemy("res://design/units/kitty.tscn")


#probably temp
func spawn_enemy(scene_path: String) -> void:
	var new_unit: Unit = load(scene_path).instantiate()
	new_unit.position = $EnemySpawn.position
	add_child(new_unit, true)
	await get_tree().physics_frame
	new_unit.command_attack_move($EnemyDestination.position)


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
		var signals = SignalCombiner.new([floor_clicked, cancel])
		var result = await signals.completed_any
		if result["source"] == floor_clicked:
			var detection_area: Area3D = load("res://core/game/range_area.tscn").instantiate()
			detection_area.position = result["data"]
			add_child(detection_area)
			detection_area.get_node(^"CollisionShape3D").shape.radius = UNIT_SELECTION_RANGE
			await get_tree().physics_frame
			
			var targeted_unit: Unit = detection_area.get_overlapping_bodies().filter(
					func(unit: Unit) -> bool: return ability.data.is_valid_target(source_unit, unit)
			).reduce(
					func(prev_closest_unit: Unit, curr_unit: Unit) -> Unit:
						var is_closer:= curr_unit.global_position.distance_to(global_position) < \
								prev_closest_unit.global_position.distance_to(global_position)
						return curr_unit if is_closer else prev_closest_unit)
			
			if targeted_unit:
				target = targeted_unit.get_path()
			detection_area.queue_free()
	else:
		var signals = SignalCombiner.new([floor_clicked, cancel])
		var result = await signals.completed_any
		match result["source"]:
			floor_clicked:
				target = result["data"]
	
	if range_indicator:
		range_indicator.queue_free()
	if target_indicator:
		target_indicator.queue_free()
	
	targeting = false
	if target:
		source_unit.activate_ability.rpc_id(1, ability_index, target)


func _on_floor_input(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3,
			_shape_idx: int):
	
	if event is InputEventMouseMotion:
		mouse_position_on_floor = event_position
	
	if event.is_action_pressed(&"unit_move"):
		move_unit.rpc_id(1, event_position)
	
	if event.is_action_pressed(&"left_click_temp"):
		floor_clicked.emit(event_position)
	
	if event.is_action_pressed(&"attack_move_temp"):
		attack_move_unit.rpc_id(1, event_position)


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
