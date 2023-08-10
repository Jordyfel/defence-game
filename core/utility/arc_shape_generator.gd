@tool
class_name ArcShapeGenerator
extends Node



@export var ability_data: AbilityData
@export var collision_shape: CollisionShape3D
@export var height:= 2.0

@export var trigger:= false:
	set(value):
		if value == true:
			assert(ability_data != null and collision_shape != null)
			_generate_arc_shape()



func _generate_arc_shape() -> void:
	var polygon_2d: PackedVector2Array = ArcShapeGenerator.create_arc_polygon(
			Vector2.ZERO, ability_data.arc_range, ability_data.arc_width, 90, 16)
	
	var polygon_3d:= PackedVector3Array()
	polygon_3d.resize(polygon_2d.size() * 2)
	
	var point2: Vector2
	var point2_count: int = polygon_2d.size()
	for point2_index in point2_count:
		point2 = polygon_2d[point2_index]
		polygon_3d[point2_index] = Vector3(point2.x, 0, point2.y)
		polygon_3d[point2_index + point2_count] = Vector3(point2.x, height, point2.y)
	
	var convex_shape:= ConvexPolygonShape3D.new()
	convex_shape.points = polygon_3d
	collision_shape.shape = convex_shape


static func create_arc_polygon(
			center: Vector2, radius: float, width_deg: float,
			face_angle_deg: float, point_count: int
			) -> PackedVector2Array:
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
