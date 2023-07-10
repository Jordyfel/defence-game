extends Camera3D



@export var camera_speed = 20
@export var zoom_speed = 150

var camera_range_max:= Vector3(15, 15, 15)
var camera_range_min:= Vector3(-15, 5, -15)

const INITIAL_POSITION:= Vector3(0, 15, 3)



func _ready() -> void:
	position = INITIAL_POSITION


func _process(delta: float) -> void:
	var direction:= Vector3()
	var scroll_direction:=Vector3()
	var screen_size = get_tree().get_root().get_visible_rect()
	var cursor_position = get_tree().get_root().get_mouse_position()
	
	if Input.is_action_pressed("move_camera_up") or cursor_position.y == 0:
		direction.z = -1
	if Input.is_action_pressed("move_camera_down") or cursor_position.y == screen_size.size.y-1:
		direction.z = 1
	if Input.is_action_pressed("move_camera_left") or cursor_position.x == 0:
		direction.x = -1
	if Input.is_action_pressed("move_camera_right") or cursor_position.x == screen_size.size.x-1:
		direction.x = 1
	if Input.is_action_just_pressed("zoom_camera_in"):
		scroll_direction.y = -1
	if Input.is_action_just_pressed("zoom_camera_out"):
		scroll_direction.y = 1
	
	position += direction.normalized() * camera_speed * delta
	position += scroll_direction.normalized() * zoom_speed * delta
	position = position.clamp(camera_range_min, camera_range_max)

