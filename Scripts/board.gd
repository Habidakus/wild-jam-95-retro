class_name Board extends Control

const BUNKER_SCENE = preload("res://Scenes/bunker_wide.tscn")
const ALIEN_BULLET = preload("res://Scenes/alien_bullet.tscn")

var _bunker_count: int = 7
var _rnd: RandomNumberGenerator = RandomNumberGenerator.new()
var _wait: float = 1
var _time_dilation: float = 1.0
var _time_dilation_array: Array[Array] = []


func _ready() -> void:
	var placement_width: int = int(size.x / float(_bunker_count))
	for i: int in range(_bunker_count):
		var bunker: Bunker = BUNKER_SCENE.instantiate()
		add_child(bunker)
		bunker.position = Vector2((i + 0.5) * placement_width, 4 * size.y / 5)


func get_time_dilation() -> float:
	return _time_dilation


func start_time_dilation(amount: float) -> void:
	_time_dilation_array.append([amount, 1.25, 1.25])


func _process(delta: float) -> void:
	_time_dilation = 1
	const FADE_IN: float = 0.1
	var new_td: Array[Array] = []
	for tuple: Array in _time_dilation_array:
		var value: float = tuple[0]
		var elapsed: float = tuple[2] - tuple[1]
		if elapsed < FADE_IN:
			value = Tween.interpolate_value(1.0, value - 1.0, elapsed, tuple[2], Tween.TRANS_QUAD, Tween.EASE_OUT)
		else:
			value = Tween.interpolate_value(value, 1.0 - value, elapsed - FADE_IN, tuple[2] - FADE_IN, Tween.TRANS_QUAD, Tween.EASE_OUT)
		assert(value >= tuple[0])
		if value < _time_dilation:
			_time_dilation = value
		var remaining: float = tuple[1] - delta
		if remaining < 0:
			continue
		new_td.append([tuple[0], remaining, tuple[2]])
	_time_dilation_array = new_td
	_wait -= delta * _time_dilation
	if _wait > 0:
		return
	
	_wait = 0.1
	var bullet: AlienBullet = ALIEN_BULLET.instantiate()
	var x: float = _rnd.randf() * (size.x - 10.0) + 5.0
	bullet.position = Vector2(x, 0)
	bullet.initialize(size.y + 30, self)
	add_child(bullet)
