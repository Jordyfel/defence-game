class_name Unit
extends CharacterBody3D



signal activate_keyframe_reached

@export var unit_name: String
@export var team: StringName
@export var movement_speed:= 4.0
@export var max_health:= 100.0

@export_group("Abilities")
@export var ability_q: UnitAbility

var health: float:
	set(new_health):
		health = clampf(new_health, 0.0, max_health)
		health_bar.region_rect.position.x = (1 - health/max_health) * 200

@onready var health_bar:= $ScuffedHealthBar
@onready var navigation_agent:= $NavigationAgent3D
@onready var animation_player:= $AnimationPlayer



func _ready():
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	health = max_health
	animation_player.play(&"idle")


@rpc("call_local", "reliable")
func command_move(target_position: Vector3) -> void:
	look_at(target_position + Vector3(0, position.y, 0), Vector3.UP, true)
	navigation_agent.set_target_position(target_position)
	animation_player.play(&"run")


func _physics_process(_delta):
	if navigation_agent.is_navigation_finished():
		return
	
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity:= (next_path_position - global_position).normalized() * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()


func _on_navigation_agent_3d_navigation_finished() -> void:
	animation_player.play(&"idle")


func activate_ability(ability: UnitAbility, target) -> void:
	animation_player.play("ability_q")
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
