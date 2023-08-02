class_name AbilityScene
extends Node3D



signal effect_time_reached(unit_in_area: Unit)

var data: AbilityData
var projectile_target: Unit
var distance_traveled:= 0.0

@onready var area:= $Area3D



func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	if data.projectile_mode == AbilityData.ProjectileMode.NONE:
		$AnimationPlayer.animation_finished.connect(_on_animation_finished)
		$AnimationPlayer.play(&"effect")
	if data.projectile_mode == AbilityData.ProjectileMode.HOMING:
		assert(projectile_target != null)


func _physics_process(delta: float) -> void:
	if data.projectile_mode == AbilityData.ProjectileMode.LINEAR:
		global_position = global_position + global_transform.basis.z * data.projectile_speed * delta
		distance_traveled += (global_transform.basis.z * data.projectile_speed * delta).length()
		if distance_traveled > data.max_travel_distance:
			queue_free()
	elif data.projectile_mode == AbilityData.ProjectileMode.HOMING:
		look_at(projectile_target.global_position, Vector3.UP, true)
		global_position = global_position + global_transform.basis.z * data.projectile_speed * delta


func activate_effect() -> void:
	# Maybe remove the filter if everything in unit layer keeps being only units.
	var targets = area.get_overlapping_bodies().filter(func(node): return node is Unit)
	if not is_zero_approx(data.arc_width):
		targets =  targets.filter(_is_in_arc)
	for target in targets:
		effect_time_reached.emit(target)


func _is_in_arc(unit: Unit) -> bool:
	var position2 = Vector2(global_position.x, global_position.z)
	var unit_position2 = Vector2(unit.position.x, unit.position.z)
	var forward2 = Vector2(global_transform.basis.z.x, global_transform.basis.z.z)
	var dot = position2.direction_to(unit_position2).dot(forward2)
	return dot > cos(deg_to_rad(data.arc_width) / 2)


func _on_body_entered(body: Node3D) -> void:
	if data.projectile_mode == AbilityData.ProjectileMode.LINEAR:
		if body is Unit:
			effect_time_reached.emit(body)
	elif data.projectile_mode == AbilityData.ProjectileMode.HOMING:
		if body == projectile_target:
			effect_time_reached.emit(body)
			queue_free()


func _on_animation_finished(_anim_name: StringName) -> void:
	if data.projectile_mode == AbilityData.ProjectileMode.NONE:
		queue_free()
