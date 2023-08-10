extends Node2D



const COLOR = Color(Color.GREEN, .4)
const TEX_CENTER = Vector2(256, 256)
const RADIUS = 256

var unit_ability: UnitAbility



func _draw() -> void:
	if unit_ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
		draw_circle(TEX_CENTER, RADIUS, COLOR)
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC:
		draw_colored_polygon(ArcShapeGenerator.create_arc_polygon(
				TEX_CENTER, RADIUS, unit_ability.data.arc_width, 90, 16), COLOR)
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
		var line_width = unit_ability.data.line_width / unit_ability.cast_range * RADIUS
		var rect_pos = TEX_CENTER
		rect_pos.y -= line_width / 2
		draw_rect(Rect2(rect_pos, Vector2(line_width, RADIUS)), COLOR)
