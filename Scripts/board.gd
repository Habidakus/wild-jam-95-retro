class_name Board extends Control

const BUNKER_SCENE = preload("res://Scenes/bunker_wide.tscn")
const ALIEN_BULLET = preload("res://Scenes/alien_bullet.tscn")
const ALIEN_SHIP = preload("res://Scenes/alien_ship.tscn")
const ALIEN_SPEED: float = 40
const ALIEN_DROP_DISTANCE: float = 40


enum AlienMovement { RIGHT, DOWN, LEFT }


var _bunker_count: int = 7
var _rnd: RandomNumberGenerator = RandomNumberGenerator.new()
#var _wait: float = 1
var _time_dilation: float = 1.0
var _time_dilation_array: Array[Array] = []
var _alien_rows: int = 5
var _alien_cols: int = 11
var _aliens: Array[AlienShip] = []
var _alien_dir: AlienMovement = AlienMovement.RIGHT
var _bottom_alien_in_each_column: Array[AlienShip] = []
var _alien_downward_goal: float = 0


func _ready() -> void:
	var placement_width: int = int(size.x / float(_bunker_count))
	for i: int in range(_bunker_count):
		var bunker: Bunker = BUNKER_SCENE.instantiate()
		add_child(bunker)
		bunker.position = Vector2((i + 0.5) * placement_width, 4 * size.y / 5)
	placement_width = int(size.x / float(_alien_cols + 5))
	var placement_height = int(size.y / float(_alien_rows + 5))
	for x: int in range(_alien_cols):
		for y: int in range(_alien_rows):
			_create_alien((x + 0.5) * placement_width, (y + 0.5) * placement_height, x)
	for alien: AlienShip in _bottom_alien_in_each_column:
		alien.power_up_weapon(_rnd.randf())
	var starfield_image: Image = Image.create_empty(size.x * 2, size.y, false, Image.FORMAT_RGB8)
	starfield_image.fill(Color.BLACK)
	for i: int in range(7):
		_add_stars(starfield_image, 100 * i, _rnd.randf() * starfield_image.get_size().x, _rnd.randf() * starfield_image.get_size().y, true)
	_add_stars(starfield_image, 1000, 0, 0, false)
	var starfield_texture: Texture = ImageTexture.create_from_image(starfield_image)
	%StarfieldImage.texture = starfield_texture
	%Parallax2D.repeat_size = starfield_image.get_size()


func _add_stars(image: Image, count: int, center_x: float, center_y: float, force: bool) -> void:
	var isize: Vector2 = image.get_size()
	var center_point: Vector2 = isize / 2.0
	for i: int in range(count):
		var sx: float = -1
		var sy: float = -1
		if force:
			for j: int in range(15):
				var sx_a: float = _rnd.randf() * isize.x
				var sy_a: float = _rnd.randf() * isize.y
				if sx < 0 or Vector2(sx_a, sy_a).distance_squared_to(center_point) < Vector2(sx, sy).distance_squared_to(center_point):
					sx = sx_a
					sy = sy_a
		else:
			sx = _rnd.randf() * isize.x
			sy = _rnd.randf() * isize.y
		sx += center_x - center_point.x
		sy += center_y - center_point.y
		if sx > isize.x:
			sx -= isize.x
		elif sx < 0:
			sx += isize.x
		if sy > isize.y:
			sy -= isize.y
		elif sy < 0:
			sy += isize.y
		var lx: int = int(sx)
		var ly: int = int(sy)
		var hx: int = (lx + 1) % int(isize.x)
		var hy: int = (ly + 1) % int(isize.y)
		var ax: float = (sx - float(lx))
		var ay: float = (sy - float(ly))
		var ll: float = max((1.0 - ax) * (1.0 - ay), image.get_pixel(lx, ly).get_luminance())
		var lh: float = max((1.0 - ax) * ay, image.get_pixel(lx, hy).get_luminance())
		var hl: float = max(ax * (1.0 - ay), image.get_pixel(hx, ly).get_luminance())
		var hh: float = max(ax * ay, image.get_pixel(hx, hy).get_luminance())
		image.set_pixel(lx, ly, Color(ll, ll, ll))
		image.set_pixel(lx, hy, Color(lh, lh, lh))
		image.set_pixel(hx, ly, Color(hl, hl, hl))
		image.set_pixel(hx, hy, Color(hh, hh, hh))


func _create_alien(x: float, y: float, row: int) -> void:
	var alien: AlienShip = ALIEN_SHIP.instantiate()
	alien.position = Vector2(x, y)
	add_child(alien)
	_aliens.append(alien)
	alien.initialize(self)
	if _bottom_alien_in_each_column.size() <= row:
		_bottom_alien_in_each_column.append(alien)
	else:
		_bottom_alien_in_each_column[row] = alien


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
	%Parallax2D.scroll_scale = Vector2(0.03 * _time_dilation, 0.0)
	$Background.rotation += delta * _time_dilation / 70.0

func _physics_process(delta: float) -> void:
	var tdd: float = delta * _time_dilation
	var min_x: float = 27 #* 3 / 4.0
	var max_x: float = size.x - min_x
	var max_alien_y: float = 0
	var min_d: float = size.x * 2
	var max_d: float = size.x * 2
	for alien: AlienShip in _aliens:
		min_d = min(min_d, alien.position.x - min_x)
		max_d = min(max_d, max_x - alien.position.x)
		max_alien_y = max(max_alien_y, alien.position.y)
	if _alien_dir == AlienMovement.DOWN:
		if max_alien_y < _alien_downward_goal:
			_move_all_aliens(tdd * Vector2.DOWN, false, min_x, max_x, max_alien_y)
			return
		if min_d < max_d:
			_alien_dir = AlienMovement.RIGHT
		else:
			_alien_dir = AlienMovement.LEFT
	
	if _alien_dir == AlienMovement.RIGHT:
		_move_all_aliens(tdd * Vector2.RIGHT, true, min_x, max_x, max_alien_y)
	elif _alien_dir == AlienMovement.LEFT:
		_move_all_aliens(tdd * Vector2.LEFT, true, min_x, max_x, max_alien_y)


func _move_all_aliens(velocity: Vector2, watch_margin: bool, min_x: float, max_x: float, max_alien_y: float) -> void:
	for alien: AlienShip in _aliens:
		alien.position += velocity * ALIEN_SPEED
		if watch_margin:
			if alien.position.x < min_x:
				_alien_dir = AlienMovement.DOWN
				_alien_downward_goal = max_alien_y + ALIEN_DROP_DISTANCE
				watch_margin = false
			elif alien.position.x > max_x:
				_alien_dir = AlienMovement.DOWN
				_alien_downward_goal = max_alien_y + ALIEN_DROP_DISTANCE
				watch_margin = false


func spawn_alien_bullet(pos: Vector2) -> void:
	var bullet: AlienBullet = ALIEN_BULLET.instantiate()
	bullet.position = pos
	bullet.initialize(size.y + 30, self, _rnd)
	add_child(bullet)
