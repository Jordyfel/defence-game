extends Camera3D
@onready var camera_3d: Camera3D = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("move_camera_up"):
		camera_3d.position.z += -1
		#fix that
		#use delta nd vectors and stuff
		#mby use other project for reference /or better just google
