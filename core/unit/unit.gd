class_name Unit
extends CharacterBody3D



signal ask_player_for_target(unit: Unit, ability: UnitAbility)
signal ability_cooldown_started(ability_key: String, cooldown_duration: float)
signal queue_command

@export var unit_name: String
@export var team: StringName
@export var movement_speed:= 4.0
@export var max_health:= 100.0
@export var aggro_range:= 10.0

# I wish I could just export a dictionary, but this makes for the
# best editing experience in the inspector.
# Abilities must be local to scene!
@export_group("Abilities")
@export var ability_q: UnitAbility
@export var ability_w: UnitAbility
@export var ability_e: UnitAbility
@export var ability_r: UnitAbility
@export var ability_a: UnitAbility
@export var ability_s: UnitAbility
@export var ability_d: UnitAbility
@export var ability_f: UnitAbility
@export var ability_z: UnitAbility
@export var ability_x: UnitAbility
@export var ability_c: UnitAbility
@export var ability_v: UnitAbility

# Gets filled with the abilities, with the letter chars as keys. like {"q": ability_q}
var abilities:= {}

var health: float:
	set(new_health):
		health = clampf(new_health, 0.0, max_health)
		$HealthBar/SubViewport/HealthbarDraw.hp_fraction = health / max_health
		if is_zero_approx(health) and multiplayer.is_server():
			_die.rpc()

@onready var navigation_agent:= $NavigationAgent3D
@onready var animation_player:= $AnimationPlayer
@onready var cast_lock_timer:= $CastAnimationLockTimer

# In radians per second.
var _turn_speed:= 20

# For faster iteration.
var _valid_abilities: Array[UnitAbility] = []



func _ready() -> void:
	_fill_abilities()
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	health = max_health
	animation_player.play(&"idle")


@rpc("any_peer", "call_local", "reliable")
func command_move(target_position: Vector3) -> void:
	queue_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var result = await signals.completed
		if result["source"] == queue_command:
			return
	
	_move.rpc(target_position)


func _to_closest_unit(prev_closest_unit: Unit, curr_unit: Unit) -> Unit:
	var is_closer:= curr_unit.global_position.distance_to(global_position) < \
			prev_closest_unit.global_position.distance_to(global_position)
	return curr_unit if is_closer else prev_closest_unit


@rpc("any_peer", "call_local", "reliable")
func command_attack_move(target_position: Vector3) -> void:
	assert(aggro_range > ability_a.get_autocast_max_range(), "Case not handled in attack move.")
	
	queue_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var result = await signals.completed
		if result["source"] == queue_command:
			return
	
	var detection_area: Area3D = load("res://core/game/range_area.tscn").instantiate()
	add_child(detection_area)
	detection_area.get_node(^"CollisionShape3D").shape.radius = aggro_range
	await get_tree().physics_frame
	
	while true:
		var units_in_range: Array[Node3D] = detection_area.get_overlapping_bodies(
		).filter(func(unit: Unit) -> bool: return ability_a.data.is_valid_target(self, unit))
		var targeted_unit: Unit
		if not units_in_range.is_empty():
			targeted_unit = units_in_range.reduce(_to_closest_unit)
		else:
			_move.rpc(target_position)
			while true:
				var signals = SignalCombiner.new([detection_area.body_entered, queue_command])
				var result = await signals.completed
				if result["source"] == queue_command:
					return
				elif result["source"] == detection_area.body_entered:
					if ability_a.data.is_valid_target(self, result["data"]):
						targeted_unit = result["data"]
						break
		
		var desired_distance = ability_a.get_autocast_max_range()
		
		var is_target_reached = await _move_in_range_of_unit(targeted_unit, desired_distance,
				func(): return not ability_a.is_on_cooldown)
		if not is_target_reached:
			return
		
		activate_ability("a", targeted_unit.get_path())
		var sig = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var res = await sig.completed
		if res["source"] == queue_command:
			return


@rpc("call_local", "reliable")
func _move(target_position: Vector3) -> void:
	navigation_agent.set_target_position(target_position)
	animation_player.play(&"run")


@rpc("any_peer", "call_local", "reliable")
func command_stop() -> void:
	queue_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var result = await signals.completed
		if result["source"] == queue_command:
			return
	
	_stop.rpc()


@rpc("call_local", "reliable")
func _stop() -> void:
	navigation_agent.set_target_position(global_position)
	animation_player.play(&"idle")


func _process_cooldowns(delta: float) -> void:
	for ability in _valid_abilities:
		if ability.is_on_cooldown:
			ability.cooldown_remaining -= delta


func _physics_process(delta: float) -> void:
	_process_cooldowns(delta)
	
	if navigation_agent.is_navigation_finished():
		return
	
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity:= (next_path_position - global_position).normalized() * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if safe_velocity == Vector3.ZERO:
		return
	if not abs(Vector3.UP.dot(safe_velocity.normalized())) == 1:
		_turn(safe_velocity.normalized())
	velocity = safe_velocity
	move_and_slide()


# Should be called every physics frame when turning
func _turn(target_direction_normal: Vector3):
	var target_basis:= Basis.looking_at(target_direction_normal, Vector3.UP, true)
	var angle_to_rotate:= global_transform.basis.get_rotation_quaternion().angle_to(
			target_basis.get_rotation_quaternion())
	var interpolation_weight:= _turn_speed * get_physics_process_delta_time() / angle_to_rotate
	interpolation_weight = clampf(interpolation_weight, 0.0, 1.0)
	global_transform.basis = global_transform.basis.slerp(target_basis, interpolation_weight)
	global_transform = global_transform.orthonormalized()


func _on_navigation_agent_3d_navigation_finished() -> void:
	if cast_lock_timer.is_stopped():
		animation_player.play(&"idle")


func request_target(ability_key: String, show_indicators:= true) -> void:
	var ability: UnitAbility = abilities[ability_key]
	if not ability:
		return
	
	if ability.is_on_cooldown:
		return
	
	ask_player_for_target.emit(self, ability_key, show_indicators)


@rpc("any_peer", "call_local", "reliable")
func activate_ability(ability_index: String, target: Variant) -> void:
	var ability: UnitAbility = abilities[ability_index]
	assert(target is Vector3 or target is NodePath or target == null)
	assert(not ability.is_on_cooldown)
	
	if target is NodePath:
		target = get_node(target)
	
	if ability == ability_s:
		command_stop()
		return
	
	if ability.data.target_mode == AbilityData.TargetMode.POSITION or \
			ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
		assert(target is Vector3)
		if global_position.distance_to(target) > ability.cast_range:
			var is_target_reached = await _move_in_range_of_position(target, ability.cast_range)
			if not is_target_reached:
				return
	
	if ability.data.target_mode == AbilityData.TargetMode.UNIT:
		assert(target is Unit)
		if global_position.distance_to(target.global_position) > ability.cast_range:
			var is_target_reached = await _move_in_range_of_unit(target, ability.cast_range)
			if not is_target_reached:
				return
	
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var result = await signals.completed
		if result["source"] == queue_command:
			return
	
	var prevent_movement:= not is_zero_approx(ability.cast_time)
	var look_at_target:= target != null
	var target_for_rpc = target if not target is Unit else target.get_path()
	_start_casting_ability.rpc(ability_index, prevent_movement, look_at_target, target_for_rpc)
	
	if prevent_movement:
		await get_tree().create_timer(ability.cast_time).timeout
	
	var ability_scene: AbilityScene = ability.ability_scene.instantiate()
	ability_scene.effect_time_reached.connect(_affect_unit.bind(ability, ability_scene))
	
	if target is Vector3:
		if ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
			ability_scene.position = target
			$/root/Game.add_child(ability_scene, true)
		elif ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC:
			ability_scene.look_at_from_position(global_position, target, Vector3.UP, true)
			$/root/Game.add_child(ability_scene, true)
		elif ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
			ability_scene.look_at_from_position(global_position, target, Vector3.UP, true)
			$/root/Game.add_child(ability_scene, true)
	
	elif target is Unit:
		ability_scene.projectile_target_path = target.get_path()
		ability_scene.look_at_from_position(global_position, target.global_position, Vector3.UP, true)
		$/root/Game.add_child(ability_scene, true)


@rpc("call_local", "reliable")
func _start_casting_ability(ability_index: String, stop_moving: bool,
		look_at_target: bool, target) -> void:
	var animation_name: StringName = "ability_" + ability_index
	var ability: UnitAbility = abilities[ability_index]
	ability_cooldown_started.emit(abilities.find_key(ability), ability.base_cooldown)
	ability.cooldown_remaining = ability.base_cooldown
	
	assert(animation_player.has_animation(animation_name))
	animation_player.play(animation_name)
	
	if stop_moving:
		navigation_agent.set_target_position(global_position)
		cast_lock_timer.start(ability.cast_time + ability.animation_lock_after_cast)
		if look_at_target:
			assert(target != null)
			var target_position = target if target is Vector3 else get_node(target).global_position
			var target_transform = global_transform.looking_at(target_position, Vector3.UP, true)
			while not global_transform.is_equal_approx(target_transform):
				_turn(position.direction_to(target_position))
				await get_tree().physics_frame


func _move_in_range_of_position(target_position: Vector3, distance: float) -> bool:
	_move.rpc(target_position)
	var signals = SignalCombiner.new([get_tree().physics_frame, queue_command])
	while global_position.distance_to(target_position) > distance:
		var result = await signals.completed
		if result["source"] == queue_command:
			return false
	
	return true


func _move_in_range_of_unit(target_unit: Unit, distance: float,
			condition: Callable = func(): return true) -> bool:
	
	const FOLLOW_TOLERANCE = 0.1
	var range_area: Area3D = load("res://core/game/range_area.tscn").instantiate()
	add_child(range_area)
	range_area.get_node(^"CollisionShape3D").shape.radius = distance
	
	var last_target_position: Vector3 = target_unit.global_position
	var target_in_area:= false
	var signals:= SignalCombiner.new([
			range_area.body_entered,
			range_area.body_exited,
			get_tree().physics_frame,
			queue_command,
			])
	
	while not (target_in_area and condition.call()):
		var result = await signals.completed
		if result["source"] == get_tree().physics_frame:
			if target_unit.global_position.distance_to(last_target_position) > FOLLOW_TOLERANCE:
				if not target_in_area:
					_move.rpc(target_unit.global_position)
					last_target_position = target_unit.global_position
		if result["source"] == queue_command:
			range_area.queue_free()
			return false
		elif result["source"] == range_area.body_entered:
			if result["data"] == target_unit:
				target_in_area = true
				_stop.rpc()
		elif result["source"] == range_area.body_exited:
			if result["data"] == target_unit:
				target_in_area = false
	
	range_area.queue_free()
	return true


func _affect_unit(unit: Unit, ability: UnitAbility, ability_scene: AbilityScene) -> void:
	if ability.data.is_valid_target(self, unit):
		ability.data.activate_effect(self, unit)
		if ability.data.is_projectile and not ability.data.target_mode == AbilityData.TargetMode.UNIT:
			if not ability.data.piercing:
				ability_scene.queue_free()


@rpc("call_local", "reliable")
func _die():
	queue_free()


func _fill_abilities() -> void:
	var is_ability = func(property_data: Dictionary) -> bool:
		return property_data["name"].begins_with("ability")
	
	for property_data in get_property_list().filter(is_ability):
		abilities[property_data["name"].right(1)] = get(property_data["name"])
	
	for ability in abilities.values().filter(func(ability): return ability != null):
		_valid_abilities.push_back(ability)
