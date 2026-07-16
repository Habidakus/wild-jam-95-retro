class_name MainMenu extends StateMachineState


@onready var _all_buttons: Array[Button] = [
	$VBoxContainer/PlayButton,
	$VBoxContainer/UpgradeButton,
	$VBoxContainer/CreditsButton,
	$VBoxContainer/SettingsButton,
	$VBoxContainer/ExitButton,
	]
var _time: float = 0


func _init_button_juice(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(Callable($AudioStreamPlayer2D, "play"))


func _work_button_juice(button: Button, _delta: float, has_upgrades_to_buy: bool) -> void:
	var is_eager: bool = false
	if has_upgrades_to_buy:
		is_eager = button == $VBoxContainer/UpgradeButton
	else:
		is_eager = button == $VBoxContainer/PlayButton
	
	if is_eager:
		button.rotation = PI * sin(_time * 12.0) / 96.0


func _ready() -> void:
	for button: Button in _all_buttons:
		_init_button_juice(button)


func _process(delta: float) -> void:
	_time += delta
	var has_upgrades_to_buy: bool = %Upgrades.has_upgrades_to_buy()
	for button: Button in _all_buttons:
		_work_button_juice(button, delta, has_upgrades_to_buy)


func _on_play_button_button_up() -> void:
	our_state_machine.switch_state("Play")


func _on_upgrade_button_button_up() -> void:
	our_state_machine.switch_state("Upgrades")


func _on_credits_button_button_up() -> void:
	our_state_machine.switch_state("Credits")


func _on_settings_button_button_up() -> void:
	our_state_machine.switch_state("Settings")


func _on_exit_button_button_up() -> void:
	get_tree().quit()
