class_name UnitAbility
extends Resource



@export var base_cooldown:= 6.0
@export var resource_cost: float
@export var cast_range:= 10
# cast time?
@export var data: AbilityData
@export var ability_scene: PackedScene

var cooldown_remaining: float
var is_on_cooldown:= false
