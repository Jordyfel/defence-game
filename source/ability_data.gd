class_name AbilityData
extends Resource



enum TargetMode {POSITION, UNIT}
enum TargetShape {ATTACHED_ARC, DETACHED_CIRCLE}

@export var name: String
@export var icon: Texture2D

@export var target_mode: TargetMode
@export var target_shape: TargetShape
@export var target_area_radius: float



func is_valid_target(_source_unit: Unit, _target_unit: Unit) -> bool:
	assert(false, "You failed to override the function :(")
	return true


func activate_effect(_source_unit: Unit, _target_unit: Unit) -> void:
	assert(false, "You failed to override the function :(")
	pass
