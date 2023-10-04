class_name EnemySpawner
extends Node



func _ready() -> void:
	if not multiplayer.is_server():
		return
	
	for i in 6:
		await get_tree().create_timer(0.2).timeout
		spawn_enemy("res://design/units/kitty.tscn")


func spawn_enemy(scene_path: String) -> void:
	var new_unit: Unit = load(scene_path).instantiate()
	new_unit.position = $EnemySpawnPosition.position
	$/root/Game.add_child(new_unit, true)
	await get_tree().physics_frame
	new_unit.command_attack_move($EnemyDestination.position)
