class_name AbilityScene
extends Node3D



signal effect_time_reached(unit_in_area: Unit)

@export var is_projectile:= false
@export var is_homing:= false
@export var projectile_speed: float
@export var max_travel_distance: float

var arc_width_deg: float

@onready var area:= $Area3D



func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$AnimationPlayer.play(&"effect")


func activate_effect() -> void:
	# Maybe remove the filter if everything in unit layer keeps being only units.
	var targets = area.get_overlapping_bodies().filter(func(node): return node is Unit)
	if not is_zero_approx(arc_width_deg):
		targets =  targets.filter(_is_in_arc)
	for target in targets:
		effect_time_reached.emit(target)


func _is_in_arc(unit: Unit) -> bool:
	var position2 = Vector2(global_position.x, global_position.z)
	var unit_position2 = Vector2(unit.position.x, unit.position.z)
	var forward2 = Vector2(global_transform.basis.z.x, global_transform.basis.z.z)
	var dot = position2.direction_to(unit_position2).dot(forward2)
	return dot > cos(deg_to_rad(arc_width_deg) / 2)


func _on_animation_finished(_anim_name: StringName) -> void:
	queue_free()
