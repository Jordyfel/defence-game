extends HBoxContainer



var connected_unit: Unit



func connect_to_unit(unit: Unit) -> void:
	if connected_unit:
		pass #disconnect from prev connected unit
	connected_unit = unit
	#connect to new units
