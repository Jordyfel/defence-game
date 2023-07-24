class_name TestAbilityArc
extends AbilityData



@export var damage: float



func is_valid_target(source_unit: Unit, target_unit: Unit) -> bool:
	return target_unit.team != source_unit.team


func activate_effect(_source_unit: Unit, target_unit: Unit) -> void:
	target_unit.health -= damage
