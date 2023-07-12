class_name AbilityData
extends Resource



enum TargetMode {POSITION, UNIT, AREA}

@export var name: String

@export var target_mode: TargetMode
@export var target_area_size: float



func is_valid_target(_source_unit: Unit, _target_unit: Unit) -> bool:
	return true


func activate_effect(_source_unit: Unit, _target_unit: Unit) -> void:
	pass
