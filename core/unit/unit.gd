class_name Unit
extends CharacterBody3D



signal ask_player_for_target(unit: Unit, ability: UnitAbility)
signal ability_cooldown_started(ability_key: String, cooldown_duration: float)
signal queue_command

@export var unit_name: String
@export var team: StringName
@export var movement_speed:= 4.0
@export var max_health:= 100.0

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
		var result = await signals.completed_any
		if result["source"] == queue_command:
			return
	
	_move.rpc(target_position)


@rpc("call_local", "reliable")
func _move(target_position: Vector3) -> void:
	look_at(target_position + Vector3(0, position.y, 0), Vector3.UP, true)
	navigation_agent.set_target_position(target_position)
	animation_player.play(&"run")


@rpc("any_peer", "call_local", "reliable")
func command_stop() -> void:
	queue_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, queue_command])
		var result = await signals.completed_any
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
			if ability.cooldown_remaining < 0:
				ability.is_on_cooldown = false


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
	velocity = safe_velocity
	move_and_slide()


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
		var result = await signals.completed_any
		if result["source"] == queue_command:
			return
	
	var prevent_movement:= not is_zero_approx(ability.cast_time)
	var look_at_target:= target != null
	_start_casting_ability.rpc(ability_index, prevent_movement, look_at_target, target)
	
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
	
	var animation_name = "ability_" + ability_index
	if stop_moving:
		navigation_agent.set_target_position(global_position)
		cast_lock_timer.start(animation_player.get_animation(animation_name).length)
		if look_at_target:
			assert(target != null)
			var target_position = target if target is Vector3 else target.global_position
			look_at(target_position, Vector3.UP, true)
	
	var ability = abilities[ability_index]
	ability_cooldown_started.emit(abilities.find_key(ability), ability.base_cooldown)
	ability.cooldown_remaining = ability.base_cooldown
	ability.is_on_cooldown = true
	
	assert(animation_player.has_animation(animation_name))
	animation_player.play(animation_name)


func _move_in_range_of_position(target_position: Vector3, distance: float) -> bool:
	_move.rpc(target_position)
	while global_position.distance_to(target_position) > distance:
		var signals = SignalCombiner.new([get_tree().physics_frame, queue_command])
		var result = await signals.completed_any
		if result["source"] == queue_command:
			return false
	
	return true


func _move_in_range_of_unit(target_unit: Unit, distance: float) -> bool:
	var range_area:= Area3D.new()
	range_area.input_ray_pickable = false
	range_area.collision_layer = 0b1000
	range_area.collision_mask = 0b10
	range_area.name = "RangeArea"
	var collision_shape:= CollisionShape3D.new()
	var sphere_shape:= SphereShape3D.new()
	sphere_shape.radius = distance
	collision_shape.shape = sphere_shape
	add_child(range_area)
	range_area.add_child(collision_shape)
	
	var last_unit_to_enter_range: Unit
	_move.rpc(target_unit.global_position)
	var last_target_position:= target_unit.global_position
	
	while last_unit_to_enter_range != target_unit:
		if not target_unit.global_position.is_equal_approx(last_target_position):
			_move.rpc(target_unit.global_position)
		
		var signals = SignalCombiner.new(
				[range_area.body_entered, get_tree().physics_frame, queue_command])
		var result = await signals.completed_any
		if result["source"] == queue_command:
			range_area.queue_free()
			return false
		elif result["source"] == range_area.body_entered:
			last_unit_to_enter_range = result["data"]
	
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
