class_name AbilityData
extends Resource



enum TargetMode {NONE, POSITION, ATTACHED_ARC, DETACHED_CIRCLE, ATTACHED_LINE, UNIT}

@export var name: String
@export var icon: Texture2D

@export var target_mode: TargetMode
@export var circle_radius: float
@export var arc_range: float
@export_range(0, 360) var arc_width: float
@export var line_width: float

@export var is_projectile: bool

@export_group("Projectile")
@export var projectile_speed: float
@export var max_travel_distance: float
@export var piercing: bool



func is_valid_target(_source_unit: Unit, _target_unit: Unit) -> bool:
	assert(false, "You failed to override the function :(")
	return true


func activate_effect(_source_unit: Unit, _target_unit: Unit) -> void:
	assert(false, "You failed to override the function :(")
	pass
