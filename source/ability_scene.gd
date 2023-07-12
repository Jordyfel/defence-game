extends Node3D



signal effect_time_reached(unit_in_area: Unit)

@onready var area:= $Area3D



func is_unit(node: Node3D) -> bool:
	return node is Unit


func activate_effect() -> void:
	for target in area.get_overlapping_bodies().filter(is_unit):
		effect_time_reached.emit(target)
