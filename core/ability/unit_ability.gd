class_name UnitAbility
extends Resource



@export var base_cooldown:= 6.0
@export var resource_cost: float
@export var cast_range:= 10
# animation?
# cast time?
@export var effect: AbilityData
@export var ability_scene: PackedScene
@export var animation_name: StringName

var cooldown_remaining: float
var is_on_cooldown:= false
