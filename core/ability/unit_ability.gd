class_name UnitAbility
extends Resource



@export var base_cooldown:= 6.0
@export var resource_cost: float
@export var cast_range:= 10
@export var cast_time: float
@export var animation_lock_after_cast: float
@export var is_castable_while_moving: bool # Not implemented yet...
@export var data: AbilityData
@export var ability_scene: PackedScene

var cooldown_remaining: float:
	set(value):
		cooldown_remaining = value
		if value < 0:
			is_on_cooldown = false
		else:
			is_on_cooldown = true

var is_on_cooldown:= false



func get_autocast_max_range() -> float:
	match data.target_mode:
		AbilityData.TargetMode.ATTACHED_ARC:
			# Casting melee attack from max range would be too easy to dodge.
			return data.arc_range - 0.5
		AbilityData.TargetMode.NONE:
			assert(false, "?")
			return cast_range
		_:
			return cast_range
