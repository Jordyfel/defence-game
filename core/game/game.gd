extends Node3D



signal floor_clicked(click_position: Vector3)
signal cancel

@export var test_unit_temp: PackedScene

const UNIT_SELECTION_RANGE = 1.0

var targeting:= false
var mouse_position_on_floor: Vector3



func _ready() -> void:
	$Floor.input_event.connect(_on_floor_input)
	
	Lobby.player_loaded.rpc_id(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"unit_move"):
		cancel.emit()


# Called only on the server.
func start_game() -> void:
	var i = 0
	for player_id in Lobby.players:
		var new_unit: Unit = test_unit_temp.instantiate()
		new_unit.position = $PlayerSpawnPosition.position + Vector3(i * 2, 0, 0)
		add_child(new_unit, true)
		setup_unit.rpc_id(player_id, new_unit.get_path())
		i += 1


@rpc("call_local", "reliable")
func setup_unit(unit_path: NodePath):
	var unit = get_node(unit_path)
	unit.team = &"player"
	unit.ask_player_for_target.connect(_on_ask_player_for_target)
	%BottomBar.connect_to_unit(unit)


func _to_closest_unit(prev_closest_unit: Unit, curr_unit: Unit, area: Area3D) -> Unit:
	var is_closer:= curr_unit.global_position.distance_to(area.global_position) < \
			prev_closest_unit.global_position.distance_to(area.global_position)
	return curr_unit if is_closer else prev_closest_unit


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
		var result = await signals.completed
		if result["source"] == floor_clicked:
			var detection_area: Area3D = load("res://core/game/range_area.tscn").instantiate()
			detection_area.position = result["data"]
			add_child(detection_area)
			detection_area.get_node(^"CollisionShape3D").shape.radius = UNIT_SELECTION_RANGE
			await get_tree().physics_frame
			
			var targeted_unit: Unit = detection_area.get_overlapping_bodies(
				).filter(func(unit: Unit) -> bool: return ability.data.is_valid_target(source_unit, unit)
				).reduce(_to_closest_unit.bind(detection_area))
			
			if targeted_unit:
				target = targeted_unit.get_path()
			detection_area.queue_free()
	else:
		var signals = SignalCombiner.new([floor_clicked, cancel])
		var result = await signals.completed
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
		move_unit.rpc_id(1, event_position, %BottomBar.connected_unit.get_path())
	
	if event.is_action_pressed(&"left_click_temp"):
		floor_clicked.emit(event_position)
	
	if event.is_action_pressed(&"attack_move_temp"):
		attack_move_unit.rpc_id(1, event_position, %BottomBar.connected_unit.get_path())


@rpc("any_peer", "call_local", "reliable")
func move_unit(target_position: Vector3, unit_path: NodePath) -> void:
	get_node(unit_path).command_move.rpc_id(1, target_position)


@rpc("any_peer", "call_local", "reliable")
func attack_move_unit(target_position: Vector3, unit_path: NodePath) -> void:
	get_node(unit_path).command_attack_move.rpc_id(1, target_position)
