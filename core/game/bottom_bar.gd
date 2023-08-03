extends HBoxContainer



var connected_unit: Unit
var ability_buttons:= {}



func _ready() -> void:
	_fill_ability_button_dict()
	for ability_key in ability_buttons:
		var button = ability_buttons[ability_key]
		button.pressed.connect(_on_ability_button_pressed.bind(button, ability_key))


func connect_to_unit(unit: Unit) -> void:
	if connected_unit:
		# Disconnect signals of previous unit.
		connected_unit.ability_cooldown_started.disconnect(_on_ability_cooldown_started)
	
	connected_unit = unit
	for ability_key in unit.abilities:
		ability_buttons[ability_key].display_ability(unit.abilities[ability_key])
	
	# Connect signals on new unit.
	unit.ability_cooldown_started.connect(_on_ability_cooldown_started)


func _on_ability_button_pressed(_ability_button: Control, ability_key: String) -> void:
	connected_unit.request_target(ability_key)


func _on_ability_cooldown_started(ability_key: String, cooldown_duration: float) -> void:
	ability_buttons[ability_key].start_cooldown(cooldown_duration)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click_temp"):
		if not $/root/Game.targeting: # hopefully temp...
			connected_unit.request_target("a")
	
	if not event is InputEventKey:
		return
	
	for ability_key in ability_buttons.keys():
		if event.is_action_pressed("ability_" + ability_key):
			connected_unit.request_target(ability_key) # can call _on_ability... too


func _fill_ability_button_dict() -> void:
	for ability_button in %AbilityGrid.get_children():
		var button_index: String = ability_button.name.right(1).to_lower()
		ability_buttons[button_index] = ability_button
