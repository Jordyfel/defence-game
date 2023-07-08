class_name Unit
extends CharacterBody3D



@export var unit_name: String
@export var movement_speed:= 4.0

@onready var navigation_agent:= $NavigationAgent3D
@onready var animation_player:= $Model/AnimationPlayer



func _ready():
	animation_player.play(&"idle")
	$/root/Game/Floor.input_event.connect(_on_floor_clicked)


func _on_floor_clicked(
			_camera: Node, event: InputEvent, event_position: Vector3,
			_normal: Vector3, _shape_idx: int):
	
	if event.is_action_pressed(&"unit_move"):
		look_at(event_position + Vector3(0, position.y, 0), Vector3.UP, true)
		set_movement_target(event_position)


func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	animation_player.play(&"run", -1, 1.4)


func _physics_process(_delta):
	if navigation_agent.is_navigation_finished():
		return
	
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed
	
	velocity = new_velocity
	move_and_slide()


func _on_navigation_agent_3d_navigation_finished() -> void:
	animation_player.play(&"idle")
