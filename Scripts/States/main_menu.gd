class_name MainMenu extends StateMachineState


func _on_play_button_button_up() -> void:
	our_state_machine.switch_state("Play")


func _on_upgrade_button_button_up() -> void:
	pass # Replace with function body.


func _on_credits_button_button_up() -> void:
	our_state_machine.switch_state("Credits")


func _on_settings_button_button_up() -> void:
	our_state_machine.switch_state("Settings")


func _on_exit_button_button_up() -> void:
	get_tree().quit()
