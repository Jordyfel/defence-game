class_name Unit
extends CharacterBody3D



signal ask_player_for_target(unit: Unit, ability: UnitAbility)
signal activate_keyframe_reached

@export var unit_name: String
@export var team: StringName
@export var movement_speed:= 4.0
@export var max_health:= 100.0

# I wish I could just export a dictionary, but this makes for the
# best editing experience in the inspector.
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



func _ready() -> void:
	_fill_ability_dict()
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	health = max_health
	animation_player.play(&"idle")


@rpc("call_local", "reliable")
func command_move(target_position: Vector3) -> void:
	look_at(target_position + Vector3(0, position.y, 0), Vector3.UP, true)
	navigation_agent.set_target_position(target_position)
	animation_player.play(&"run")


func _physics_process(_delta) -> void:
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
	
	ask_player_for_target.emit(self, ability)


func activate_ability(ability: UnitAbility, target) -> void:
	assert(ability in abilities.values())
	animation_player.play(ability.animation_name)
	await activate_keyframe_reached
	var ability_scene: AbilityScene = ability.ability_scene.instantiate()
	ability_scene.position = target # temp, only to demonstrate logic
	ability_scene.effect_time_reached.connect(_on_ability_effect_time_to_activate.bind(ability))
	$/root/Game.add_child(ability_scene, true)


func activate_keyframe() -> void:
	activate_keyframe_reached.emit()


func _on_ability_effect_time_to_activate(unit_in_area: Unit, ability: UnitAbility) -> void:
	if ability.effect.is_valid_target(self, unit_in_area):
		ability.effect.activate_effect(self, unit_in_area)


func _fill_ability_dict() -> void:
	var is_ability = func(property_data: Dictionary) -> bool:
		return property_data["name"].begins_with("ability")
	
	for property_data in get_property_list().filter(is_ability):
		abilities[property_data["name"].right(1)] = get(property_data["name"])
