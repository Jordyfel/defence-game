class_name EnemyController
extends RefCounted



var enemy_destination:= Vector3()

var _units: Array[Unit] = []



func add_unit(unit: Unit) -> void:
	_units.push_back(unit)
	var basic_attack: UnitAbility = unit.ability_a
	var attack_range: float
	match basic_attack.data.target_mode:
		AbilityData.TargetMode.ATTACHED_ARC:
			attack_range = basic_attack.data.arc_range
			# Casting melee attack from max range would be too easy to dodge.
			attack_range *= 0.8
		AbilityData.TargetMode.ATTACHED_LINE:
			attack_range = basic_attack.cast_range
#		# TODO: Handle this case.
#		AbilityData.TargetMode.UNIT:
#			attack_range = basic_attack.cast_range
		_:
			assert(false, "?")
	
	var range_area:= Area3D.new()
	range_area.input_ray_pickable = false
	range_area.collision_layer = 0b1000
	range_area.collision_mask = 0b10
	range_area.name = "RangeArea"
	var collision_shape:= CollisionShape3D.new()
	var sphere_shape:= SphereShape3D.new()
	sphere_shape.radius = attack_range
	collision_shape.shape = sphere_shape
	unit.add_child(range_area)
	range_area.add_child(collision_shape)
	range_area.body_entered.connect(_on_unit_entered_range.bind(unit))
	
	unit.navigation_agent.avoidance_enabled = true
	unit.command_move(enemy_destination)


func _on_unit_entered_range(entered_unit: Unit, source_unit: Unit) -> void:
	if source_unit.ability_a.data.is_valid_target(source_unit, entered_unit):
		source_unit.activate_ability("a", entered_unit.global_position)
