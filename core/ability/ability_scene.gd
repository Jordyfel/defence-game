class_name AbilityScene
extends Node3D



signal effect_time_reached(unit_in_area: Unit)

@onready var area:= $Area3D



func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$AnimationPlayer.play(&"effect")


func is_unit(node: Node3D) -> bool:
	return node is Unit


func activate_effect() -> void:
	for target in area.get_overlapping_bodies().filter(is_unit):
		effect_time_reached.emit(target)


func _on_animation_finished(_anim_name: StringName) -> void:
	queue_free()
