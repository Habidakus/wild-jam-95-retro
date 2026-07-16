extends Node


#class BuffTupple:
	#var buff_type: PlayerBuff.BuffType
	#var buff_strength: float
	#func _init(bt: PlayerBuff.BuffType, bs: float) -> void:
		#buff_type = bt
		#buff_strength = bs


const STAT_FILE: String = "user://save_game.json"


var _minor_currency: int = 0
var _major_currency: int = 0
var _purchased_buffs: Array[PlayerBuff] = []


func _ready() -> void:
	load_game()
	print("Current player stats minor=%d major=%d" % [_minor_currency, _major_currency])


func reset() -> void:
	_minor_currency = 0
	_major_currency = 0
	_purchased_buffs = []


func buy_buff(buff: PlayerBuff) -> void:
	assert(not _purchased_buffs.has(buff))
	assert(buff.can_be_bought())
	_minor_currency -= buff.cost_minor
	_major_currency -= buff.cost_major
	_purchased_buffs.append(buff)


func get_max_strength_acquired(buff_type: PlayerBuff.BuffType) -> float:
	var ret_val: float = 0.0
	for buff: PlayerBuff in _purchased_buffs:
		if buff.buff_type == buff_type:
			if buff.strength > ret_val:
				ret_val = buff.strength
	return ret_val


func can_afford(minor: int, major: int) -> bool:
	return _minor_currency >= minor && _major_currency >= major


func has_buff(buff: PlayerBuff) -> bool:
	return _purchased_buffs.has(buff)


func add_currency(minor: int, major: int) -> void:
	_minor_currency += minor
	_major_currency += major
	save_game()
	print("Current player stats minor=%d major=%d" % [_minor_currency, _major_currency])


func load_game() -> void:
	if not FileAccess.file_exists(STAT_FILE):
		reset()
		return
	var file: FileAccess = FileAccess.open(STAT_FILE, FileAccess.READ)
	var path: String = ProjectSettings.globalize_path(STAT_FILE)
	if not file:
		var file_error: Error = FileAccess.get_open_error()
		print("LOAD ERROR accessing %s: %s" % [path, file_error])
		reset()
		return
	var file_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var error: Error = json.parse(file_text)
	if error != OK:
		print("JSON parse error on %s: %s" % [path, error])
		reset()
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		print("JSON content error on %s: not a dictionary" % [path])
		reset()
		return
	var player_stats: Dictionary = json.data
	_minor_currency = player_stats["minor"]
	_major_currency = player_stats["major"]
	_purchased_buffs = []


func save_game() -> void:
	var minor: int = _minor_currency
	var major: int = _major_currency
	for buff: PlayerBuff in _purchased_buffs:
		minor += buff.cost_minor
		major += buff.cost_major
	var player_stats: Dictionary = {
		"minor": minor,
		"major": major,
	}
	var path: String = ProjectSettings.globalize_path(STAT_FILE)
	var file: FileAccess = FileAccess.open(STAT_FILE, FileAccess.WRITE)
	if not file:
		var error: Error = FileAccess.get_open_error()
		print("Failed to open %s for saving: %s" % [path, error])
		return
	var file_text: String = JSON.stringify(player_stats)
	file.store_line(file_text)
	file.close()
