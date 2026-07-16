class_name Upgrades extends StateMachineState


const BUFF_DIR: String = "res://Resources/PlayerBuffs/"


var _all_upgrades: Array[PlayerBuff] = []
@onready var _dummy_button: Button = %DummyButton


func _ready() -> void:
	Input.use_accumulated_input = false
	%Description.text = ""
	var dir: DirAccess = DirAccess.open(BUFF_DIR)
	if not dir:
		print("Failed to open resource path: %s" % [BUFF_DIR])
		return
	for file: String in dir.get_files():
		var file_path = BUFF_DIR.path_join(file)
		if file_path.ends_with(".remap"):
			file_path = file_path.remap(".remap", "")
		elif file_path.ends_with(".import"):
			file_path = file_path.replace(".import", "")
		if not file_path.ends_with(".tres") and not file_path.ends_with(".res"):
			continue
		var resource: Resource = ResourceLoader.load(file_path)
		if resource and resource is PlayerBuff:
			_all_upgrades.append(resource as PlayerBuff)
	call_deferred("_set_up_buttons")


func update_buttons() -> void:
	var parent: Node = _dummy_button.get_parent()
	var parent_children: Array[Node] = parent.get_children().duplicate()
	for child: Node in parent_children:
		if child == _dummy_button:
			continue
		parent.remove_child(child)
		child.queue_free()
	_set_up_buttons()


func _set_up_buttons() -> void:
	_dummy_button.show()
	var parent: Node = _dummy_button.get_parent()
	for buff: PlayerBuff in _all_upgrades:
		if buff.has():
			continue
		var can_see: PlayerBuff.HowVisible = buff.can_see()
		if can_see == PlayerBuff.HowVisible.INVISIBLE:
			continue
		var button: Button = _dummy_button.duplicate()
		var description: String = "???"
		button.set_meta("buff", buff)
		button.disabled = true
		if can_see == PlayerBuff.HowVisible.SHROUDED:
			button.text = "???"
		else:
			button.text = buff.button_name
			description = buff.description
		if buff.can_be_bought():
			button.disabled = false
		parent.add_child(button)
		button.button_up.connect(Callable(self, "_on_button_up").bind(buff))
		button.mouse_exited.connect(Callable(self, "_on_mouse_exited").bind(buff))
		button.mouse_entered.connect(Callable(self, "_on_mouse_entered").bind(buff, description))
	_dummy_button.hide()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		our_state_machine.switch_state("MainMenu")


func has_upgrades_to_buy() -> bool:
	for buff: PlayerBuff in _all_upgrades:
		if buff.can_be_bought():
			return true
	return false


func _on_button_up(_buff: PlayerBuff) -> void:
	update_buttons()
	pass # Replace with function body.


var _current_hover_buff: PlayerBuff = null
func _on_mouse_entered(buff: PlayerBuff, description: String) -> void:
	_current_hover_buff = buff
	$AudioStreamPlayer2D.play()
	%Description.text = description


func _on_mouse_exited(buff: PlayerBuff) -> void:
	if _current_hover_buff == buff:
		_current_hover_buff = null
		%Description.text = ""
