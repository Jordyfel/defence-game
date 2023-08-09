class_name Unit
extends CharacterBody3D



signal ask_player_for_target(unit: Unit, ability: UnitAbility)
signal ability_cooldown_started(ability_key: String, cooldown_duration: float)
signal override_queued_command

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
		health_bar.region_rect.position.x = (1 - health/max_health) * 200

@onready var health_bar:= $ScuffedHealthBar
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
	override_queued_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, override_queued_command])
		var result = await signals.completed_any
		if result["source"] == override_queued_command:
			return
	
	_move.rpc(target_position)


@rpc("call_local", "reliable")
func _move(target_position: Vector3) -> void:
	look_at(target_position + Vector3(0, position.y, 0), Vector3.UP, true)
	navigation_agent.set_target_position(target_position)
	animation_player.play(&"run")


@rpc("any_peer", "call_local", "reliable")
func command_stop() -> void:
	override_queued_command.emit()
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, override_queued_command])
		var result = await signals.completed_any
		if result["source"] == override_queued_command:
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
	animation_player.play(&"idle")


func request_target(ability_key: String) -> void:
	var ability: UnitAbility = abilities[ability_key]
	if not ability:
		return
	
	if ability.is_on_cooldown:
		return
	
	ask_player_for_target.emit(self, ability_key)


@rpc("any_peer", "call_local", "reliable")
func activate_ability(ability_index: String, target: Variant) -> void:
	var ability: UnitAbility = abilities[ability_index]
	assert(target is Vector3 or target is NodePath or target == null)
	assert(not ability.is_on_cooldown)
	if ability.is_on_cooldown:
		return # Shouldn't happen, but it does, so avoid casting twice until it's fixed.
	
	if target is NodePath:
		target = get_node(target)
	
	if ability == ability_s:
		command_stop()
		return
	
	if ability.data.target_mode == AbilityData.TargetMode.POSITION or \
			ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE or \
			ability.data.target_mode == AbilityData.TargetMode.UNIT:
		var target_position = target if target is Vector3 else target.global_position
		if global_position.distance_to(target_position) > ability.cast_range:
			return
	
	if not cast_lock_timer.is_stopped():
		var signals = SignalCombiner.new([cast_lock_timer.timeout, override_queued_command])
		var result = await signals.completed_any
		if result["source"] == override_queued_command:
			return
	
	_start_casting_ability.rpc(ability_index)
	
	if not is_zero_approx(ability.cast_time):
#		if ability.is_castable_while_moving:
#			cast_lock_timer.start(ability.cast_time)
#			await cast_lock_timer.timeout
#		else:
			var prev_move_target_position = navigation_agent.get_target_position()
			command_stop()
			cast_lock_timer.start(ability.cast_time)
			command_move(prev_move_target_position)
			await cast_lock_timer.timeout
	
	var ability_scene: AbilityScene = ability.ability_scene.instantiate()
	ability_scene.effect_time_reached.connect(_affect_unit.bind(ability, ability_scene))
	
	if target is Vector3:
		if ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
			ability_scene.position = target
			$/root/Game.add_child(ability_scene, true)
		elif ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC:
			ability_scene.look_at_from_position($AttackSource.global_position, target, Vector3.UP, true)
			$/root/Game.add_child(ability_scene, true)
		elif ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
			ability_scene.look_at_from_position(global_position, target, Vector3.UP, true)
			$/root/Game.add_child(ability_scene, true)
	
	elif target is Unit:
		ability_scene.projectile_target_path = target.get_path()
		ability_scene.look_at_from_position(global_position, target.global_position, Vector3.UP, true)
		$/root/Game.add_child(ability_scene, true)


@rpc("call_local", "reliable")
func _start_casting_ability(ability_index: String) -> void:
	var ability = abilities[ability_index]
	ability_cooldown_started.emit(abilities.find_key(ability), ability.base_cooldown)
	ability.cooldown_remaining = ability.base_cooldown
	ability.is_on_cooldown = true
	
	var animation_name = "ability_" + ability_index
	assert(animation_player.has_animation(animation_name))
	animation_player.play(animation_name)


func _affect_unit(unit: Unit, ability: UnitAbility, ability_scene: AbilityScene) -> void:
	if ability.data.is_valid_target(self, unit):
		ability.data.activate_effect(self, unit)
		if ability.data.is_projectile and not ability.data.target_mode == AbilityData.TargetMode.UNIT:
			if not ability.data.piercing:
				ability_scene.queue_free()


func _fill_abilities() -> void:
	var is_ability = func(property_data: Dictionary) -> bool:
		return property_data["name"].begins_with("ability")
	
	for property_data in get_property_list().filter(is_ability):
		abilities[property_data["name"].right(1)] = get(property_data["name"])
	
	for ability in abilities.values().filter(func(ability): return ability != null):
		_valid_abilities.push_back(ability)
