extends HBoxContainer



signal target_requested(ability_data: AbilityData)

var connected_unit: Unit

var ability_keys: PackedStringArray= ["q", "w", "e", "r", "a", "s", "d", "f", "z", "x", "c", "v"]



func _ready() -> void:
	for ability_button in %AbilityGrid.get_children():
		var button_index: String = ability_button.name.right(1).to_lower()
		var actual_button: TextureButton = ability_button.get_node(^"TextureButton")
		actual_button.pressed.connect(_on_ability_button_pressed.bind(ability_button, button_index))


func connect_to_unit(unit: Unit) -> void:
	if connected_unit:
		pass #disconnect from prev connected unit
	connected_unit = unit
	#connect to new units


func _on_ability_button_pressed(_ability_button: Control, ability_key: String) -> void:
	connected_unit.request_target(ability_key)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	for ability_key in ability_keys:
		if event.is_action_pressed("ability_" + ability_key):
			connected_unit.request_target(ability_key) # can call _on_ability... too
