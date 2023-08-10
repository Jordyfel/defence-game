class_name AbilityScene
extends Node3D



signal effect_time_reached(unit_in_area: Unit)

var data: AbilityData
var projectile_target_path: NodePath
var projectile_target: Unit
var distance_traveled:= 0.0

@onready var area:= $Area3D



func _ready() -> void:
	assert($Area3D/CollisionShape3D.shape != null)
	data = load(scene_file_path.replace("tscn", "tres"))
	$Area3D.body_entered.connect(_on_body_entered)
	if not data.is_projectile:
		$AnimationPlayer.animation_finished.connect(_on_animation_finished)
		$AnimationPlayer.play(&"effect")
	if data.is_projectile and data.target_mode == AbilityData.TargetMode.UNIT:
		projectile_target = get_node(projectile_target_path)
		assert(projectile_target != null)


func _physics_process(delta: float) -> void:
	if data.is_projectile:
		if data.target_mode == AbilityData.TargetMode.UNIT:
			look_at(projectile_target.global_position, Vector3.UP, true)
			global_position = global_position + global_transform.basis.z * data.projectile_speed * delta
		else:
			global_position = global_position + global_transform.basis.z * data.projectile_speed * delta
			distance_traveled += (global_transform.basis.z * data.projectile_speed * delta).length()
			if distance_traveled > data.max_travel_distance and multiplayer.is_server():
				queue_free()


func activate_effect() -> void:
	if not multiplayer.is_server():
		return
	
	var targets = area.get_overlapping_bodies()
	for target in targets:
		assert(target is Unit, "Only units are supposed to end up here. Mind the physics layers.")
		effect_time_reached.emit(target)


func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return
	
	if data.is_projectile:
		if data.target_mode == AbilityData.TargetMode.UNIT:
			if body == projectile_target:
				effect_time_reached.emit(body)
				queue_free()
		else:
			if body is Unit:
				effect_time_reached.emit(body)


func _on_animation_finished(_anim_name: StringName) -> void:
	if not data.is_projectile and multiplayer.is_server():
		queue_free()
