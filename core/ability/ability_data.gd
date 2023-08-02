class_name AbilityData
extends Resource



enum TargetMode {POSITION, UNIT}
enum TargetShape {NONE, ATTACHED_ARC, DETACHED_CIRCLE, ATTACHED_LINE}
enum ProjectileMode {NONE, LINEAR, HOMING}

@export var name: String
@export var icon: Texture2D

@export var target_mode: TargetMode
@export var target_shape: TargetShape
@export var target_area_radius: float
@export_range(0, 360) var arc_width: float

@export var projectile_mode: ProjectileMode
@export var projectile_speed: float

@export_group("Linear Projectile Properties")
@export var max_travel_distance: float
@export var piercing: bool




func is_valid_target(_source_unit: Unit, _target_unit: Unit) -> bool:
	assert(false, "You failed to override the function :(")
	return true


func activate_effect(_source_unit: Unit, _target_unit: Unit) -> void:
	assert(false, "You failed to override the function :(")
	pass
