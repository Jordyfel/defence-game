class_name AbilityButton
extends CenterContainer



signal pressed

var cooldown_remaining: float
var is_cooldown_ticking: bool



func _physics_process(delta: float) -> void:
	if is_cooldown_ticking:
		cooldown_remaining -= delta
		$CooldownIndicator/Label.text = String.num(cooldown_remaining, 1)
		if cooldown_remaining < 0:
			is_cooldown_ticking = false
			$CooldownIndicator.hide()


func display_ability(ability: UnitAbility) -> void:
	if not ability:
		%HotkeyLabel.hide()
		%CostLabel.hide()
		$TextureButton.texture_normal = null
	else:
		%HotkeyLabel.show()
		if ability.resource_cost > 0:
			%CostLabel.text = str(ability.resource_cost)
			%CostLabel.show()
		$TextureButton.texture_normal = ability.effect.icon


func start_cooldown(duration: float) -> void:
	cooldown_remaining = duration
	is_cooldown_ticking = true
	$CooldownIndicator.show()


func _on_texture_button_pressed() -> void:
	pressed.emit()
