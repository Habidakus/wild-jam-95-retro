class_name Upgrades extends StateMachineState


const BUFF_DIR: String = "res://Resources/PlayerBuffs/"


var _all_upgrades: Array[PlayerBuff] = []
@onready var _dummy_button: Button = %DummyButton


func _ready() -> void:
	Input.use_accumulated_input = false
	%Description.text = ""
	%MinorLabel.hide()
	%MinorValue.text = ""
	%MajorLabel.hide()
	%MajorValue.text = ""
	_load_buffs_from_file()
	_proc_gen_other_buffs()
	call_deferred("_set_up_buttons")


func _proc_gen_other_buffs() -> void:
	var previous_buff: PlayerBuff = null
	for i: int in range(2,21):
		var skip_level_buff: PlayerBuff = PlayerBuff.new()
		skip_level_buff.strength = i - 1
		skip_level_buff.buff_type = PlayerBuff.BuffType.SKIP_TO_LEVEL
		skip_level_buff.button_name = str("Skip Wave %d" % [i - 1])
		skip_level_buff.description = str("Don't waste time on waves 1 to %d, skip right to wave %d" % [i - 1, i])
		skip_level_buff.cost_major = 0
		skip_level_buff.cost_minor = 40 + 5 * i
		skip_level_buff.diff_completed = i - 2
		if previous_buff != null:
			skip_level_buff.prereq_buffs.append(previous_buff)
		previous_buff = skip_level_buff
		_all_upgrades.append(skip_level_buff)


func _load_buffs_from_file() -> void:
	var dir: DirAccess = DirAccess.open(BUFF_DIR)
	if not dir:
		print("Failed to open resource path: %s" % [BUFF_DIR])
		return
	for file: String in dir.get_files():
		var file_path = BUFF_DIR.path_join(file)
		if file_path.ends_with(".remap"):
			file_path = file_path.replace(".remap", "")
		elif file_path.ends_with(".import"):
			file_path = file_path.replace(".import", "")
		if not file_path.ends_with(".tres") and not file_path.ends_with(".res"):
			continue
		var resource: Resource = ResourceLoader.load(file_path)
		if resource and resource is PlayerBuff:
			_all_upgrades.append(resource as PlayerBuff)


func update_buttons() -> void:
	var parent: Node = _dummy_button.get_parent()
	var parent_children: Array[Node] = parent.get_children().duplicate()
	for child: Node in parent_children:
		if child == _dummy_button:
			continue
		parent.remove_child(child)
		child.queue_free()
	_set_up_buttons()
	%OwnedMinor.text = str(PlayerStats.get_minor_currency())
	var major_currency: int = PlayerStats.get_major_currency()
	if major_currency > 0 or PlayerStats.has_completed_any():
		%OwnedMajorLabel.show()
		%OwnedMajor.text = str(major_currency)
	else:
		%OwnedMajorLabel.hide()
		%OwnedMajor.text = ""


func _set_up_buttons() -> void:
	_dummy_button.show()
	var parent: Node = _dummy_button.get_parent()
	var any_button_present: bool = false
	var has_one_shrouded: bool = false
	for buff: PlayerBuff in _all_upgrades:
		if buff.has():
			continue
		var can_see: PlayerBuff.HowVisible = buff.can_see()
		if can_see == PlayerBuff.HowVisible.INVISIBLE:
			continue
		if can_see == PlayerBuff.HowVisible.SHROUDED:
			if has_one_shrouded:
				continue
			has_one_shrouded = true
		var button: Button = _dummy_button.duplicate()
		var description: String = "???"
		var minor_cost: int = 0
		var major_cost: int = 0
		button.set_meta("buff", buff)
		button.disabled = true
		if can_see == PlayerBuff.HowVisible.SHROUDED:
			button.text = "???"
		else:
			button.text = buff.button_name
			description = buff.description
			minor_cost = buff.cost_minor
			major_cost = buff.cost_major
			if major_cost > 0:
				button.add_theme_color_override("font_color", Color(0xc87850ff))
				button.add_theme_color_override("font_hover_color", Color(0xc87850ff))
				button.add_theme_color_override("font_pressed_color", Color(0xc87850ff))
		if buff.can_be_bought():
			button.disabled = false
		parent.add_child(button)
		button.button_up.connect(Callable(self, "_on_button_up").bind(buff))
		button.mouse_exited.connect(Callable(self, "_on_mouse_exited").bind(buff))
		button.mouse_entered.connect(Callable(self, "_on_mouse_entered").bind(buff, description, minor_cost, major_cost))
		any_button_present = true
	_dummy_button.hide()
	if not any_button_present:
		%Description.text = "-+-  You've bought out the store.  -+-"
		%MinorLabel.hide()
		%MinorValue.text = ""
		%MajorLabel.hide()
		%MajorValue.text = ""


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		our_state_machine.switch_state("MainMenu")


func has_upgrades_to_buy() -> bool:
	for buff: PlayerBuff in _all_upgrades:
		if buff.can_be_bought():
			return true
	return false


func enter_state() -> void:
	super.enter_state()
	update_buttons()


func _on_button_up(buff: PlayerBuff) -> void:
	PlayerStats.buy_buff(buff)
	update_buttons()


var _current_hover_buff: PlayerBuff = null
func _on_mouse_entered(buff: PlayerBuff, description: String, cost_minor: int, cost_major: int) -> void:
	_current_hover_buff = buff
	$AudioStreamPlayer2D.play()
	%Description.text = description
	%MinorLabel.show()
	if cost_minor > 0:
		%MinorLabel.show()
		%MinorValue.text = str(cost_minor)
	else:
		%MinorLabel.hide()
		%MinorValue.text = ""
	if cost_major > 0:
		%MajorValue.text = str(cost_major)
		%MajorLabel.show()
	else:
		%MajorValue.text = ""
		%MajorLabel.hide()


func _on_mouse_exited(buff: PlayerBuff) -> void:
	if _current_hover_buff == buff:
		_current_hover_buff = null
		%Description.text = ""
		%MinorLabel.hide()
		%MinorValue.text = ""
		%MajorLabel.hide()
		%MajorValue.text = ""
