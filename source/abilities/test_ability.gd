class_name TestAbility
extends AbilityData



@export var damage: float



func validate_target(source_unit: Unit, target_unit: Unit) -> bool:
	return target_unit.team != source_unit.team


func effect(source_unit: Unit, target_unit: Unit) -> void:
	target_unit.health -= damage
