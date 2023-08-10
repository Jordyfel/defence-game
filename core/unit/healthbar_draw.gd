@tool
extends Node2D



var hp_fraction:= 1.0:
	set(new_hp_fraction):
		hp_fraction = new_hp_fraction
		queue_redraw()



func _draw() -> void:
	draw_rect(Rect2(Vector2(1, 1), Vector2(202 * hp_fraction, 14)), Color.LIGHT_GREEN)
