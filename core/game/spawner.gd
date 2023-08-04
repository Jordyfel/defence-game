extends MultiplayerSpawner



func _ready() -> void:
	_fill_spawner()


func _fill_spawner() -> void:
	var scene_paths_for_synchronizer:= PackedStringArray()
	var unit_paths = DirAccess.get_files_at("res://design/units/")
	for unit_path in unit_paths:
		scene_paths_for_synchronizer.push_back("res://design/units/" + unit_path)
	var ability_paths = DirAccess.get_directories_at("res://design/abilities/")
	for ability_path in ability_paths:
		scene_paths_for_synchronizer.push_back(
				"res://design/abilities/" + ability_path + "/" + ability_path + ".tscn")
	for scene_path in scene_paths_for_synchronizer:
		add_spawnable_scene(scene_path)
