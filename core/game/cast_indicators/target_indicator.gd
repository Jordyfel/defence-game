class_name TargetIndicator
extends Sprite3D



var unit_ability: UnitAbility



func _ready() -> void:
	$SubViewport/Node2D.unit_ability = unit_ability
	position.y += 0.002
	if unit_ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
		scale *= unit_ability.data.circle_radius
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC:
		scale *= unit_ability.data.arc_range
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
		scale *= unit_ability.cast_range


func _process(_delta: float) -> void:
	if unit_ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
		var pos = $/root/Game.mouse_position_on_floor
		pos.y += 0.002
		global_position = pos
	else:
		var mouse_pos = $/root/Game.mouse_position_on_floor
		mouse_pos.y += 0.002
		look_at(mouse_pos, Vector3.UP, true)
