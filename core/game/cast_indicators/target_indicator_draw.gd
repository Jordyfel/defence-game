extends Node2D



const COLOR = Color(Color.GREEN, .4)
const TEX_CENTER = Vector2(256, 256)
const RADIUS = 256

var unit_ability: UnitAbility



func _draw() -> void:
	if unit_ability.data.target_mode == AbilityData.TargetMode.DETACHED_CIRCLE:
		draw_circle(TEX_CENTER, RADIUS, COLOR)
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_ARC:
		draw_colored_polygon(
				create_arc_polygon(TEX_CENTER, RADIUS, unit_ability.data.arc_width, 90, 32), COLOR)
	elif unit_ability.data.target_mode == AbilityData.TargetMode.ATTACHED_LINE:
		var line_width = unit_ability.data.line_width / unit_ability.cast_range * RADIUS
		var rect_pos = TEX_CENTER
		rect_pos.y -= line_width / 2
		draw_rect(Rect2(rect_pos, Vector2(line_width, RADIUS)), COLOR)


func create_arc_polygon(center: Vector2, radius: float, width_deg: float, face_angle_deg: float,
						point_count: int) -> PackedVector2Array:
	var face_angle:= deg_to_rad(face_angle_deg)
	var arc_width:= deg_to_rad(width_deg)
	
	var points:= PackedVector2Array()
	points.resize(point_count + 2)
	points[-1] = center
	
	var start_angle:= face_angle - arc_width / 2
	for point_index in point_count + 1:
		var point_angle = start_angle + (point_index as float / point_count) * arc_width
		points[point_index] = center + Vector2.from_angle(point_angle) * radius
	
	return points
