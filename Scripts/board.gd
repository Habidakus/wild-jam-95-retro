class_name Board extends Control

const BUNKER_SCENE = preload("res://Scenes/bunker_wide.tscn")
const PLAYER_BULLET = preload("res://Scenes/player_bullet.tscn")
const ALIEN_BULLET = preload("res://Scenes/alien_bullet.tscn")
const DROP_BULLET = preload("res://Scenes/alien_flame_bullet.tscn")
const ALIEN_SHIP = preload("res://Scenes/alien_ship.tscn")
const PLAYER = preload("res://Scenes/player.tscn")
const COIN_TEXTURE = preload("res://Images/coin.svg")
const ALIEN_SPEED: float = 40
const ALIEN_DROP_DISTANCE: float = 40
const STAR_ROTATION_AMOUNT: float = 0.0015
const STAR_SCROLL_AMOUNT: float = 10#0.003


enum AlienMovement { RIGHT, DOWN, LEFT }


var _menu_state_machine: StateMachine
var _player: Player
var _player_lives: int = 3
var _game_over: bool = false
var _bunker_count: int = 7
var _rnd: RandomNumberGenerator = RandomNumberGenerator.new()
#var _wait: float = 1
var _time_dilation: float = 1.0
var _time_dilation_array: Array[Array] = []
var _alien_rows: int = 5
var _alien_cols: int = 11
var _aliens: Array[AlienShip] = []
var _bunkers: Array[Bunker] = []
var _alien_dir: AlienMovement = AlienMovement.RIGHT
var _bottom_alien_in_each_column: Array[AlienShip] = []
var _alien_downward_goal: float = 0
var _alien_speed_multiple: float = 1.0
var _minor_currency: int = 0
var _major_currency: int = 0
var _difficulty: int = 0
var _player_bullet_speed_multiple: float = 1.0
var _primary_alien_type: AlienShip.ShipType = AlienShip.ShipType.Regular
var _secondary_alien_type: AlienShip.ShipType = AlienShip.ShipType.Regular


func _ready() -> void:
	var first_wave: int = int(round(PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.SKIP_TO_LEVEL)))
	initialize(first_wave)
	_set_player_lives(3 + int(round(PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.LIVES_HIGHER_MAX))))


func _set_player_lives(amount: int) -> void:
	if _player_lives == amount:
		return
	_player_lives = amount
	var tween: Tween = create_tween()
	if amount > 0:
		tween.tween_property($Lives, "modulate:a", 0, 0.1)
		$Lives.text = str(amount)
		tween.tween_property($Lives, "modulate:a", 1, 0.1)
		tween.tween_property($Lives, "modulate:a", 0.5, 2)
	else:
		tween.tween_property($Lives, "modulate:a", 0, 0.5)


func initialize(difficulty: int) -> void:
	_player_bullet_speed_multiple = (1.0 + PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.GUN_BULLET_SPEED))
	_time_dilation_array = []
	_minor_currency = 0
	_major_currency = 0
	%GameOverLabel.hide()
	%Congrats.hide()
	_initialize_difficulty(difficulty)
	_create_bunkers()
	_create_aliens()
	_create_starfield()
	_create_player()
	MusicPlayer.play_next_track()
	%WaveNumber.modulate.a = 0
	%WaveNumber.text = str("Wave %d" % [_difficulty + 1])
	var tween: Tween = create_tween()
	tween.tween_property(%WaveNumber, "modulate:a", 1.0, 0.2)
	tween.tween_property(%WaveNumber, "modulate:a", 0.0, 0.8)


func _initialize_difficulty(difficulty: int) -> void:
	_difficulty = difficulty
	_primary_alien_type = AlienShip.ShipType.Regular
	_secondary_alien_type = AlienShip.ShipType.Regular
	_alien_speed_multiple = 1.0 + floor(difficulty / 4.0) * 0.33
	match difficulty % 4:
		0:
			_primary_alien_type = AlienShip.ShipType.Regular
		1:
			_primary_alien_type = AlienShip.ShipType.Thin
		2:
			_primary_alien_type = AlienShip.ShipType.Acid
		3:
			_primary_alien_type = AlienShip.ShipType.Shield
	if difficulty > 8:
		match _primary_alien_type:
			AlienShip.ShipType.Regular:
				_secondary_alien_type = AlienShip.ShipType.Thin if difficulty % 2 == 0 else AlienShip.ShipType.Acid
			AlienShip.ShipType.Shield:
				_secondary_alien_type = AlienShip.ShipType.Thin if difficulty % 2 == 0 else AlienShip.ShipType.Acid
			AlienShip.ShipType.Acid:
				_secondary_alien_type = AlienShip.ShipType.Thin if difficulty % 2 == 0 else AlienShip.ShipType.Shield
			AlienShip.ShipType.Thin:
				_secondary_alien_type = AlienShip.ShipType.Acid if difficulty % 2 == 0 else AlienShip.ShipType.Shield


func _create_bunkers() -> void:
	assert(_bunkers.is_empty())
	var placement_width: float = size.x / float(_bunker_count)
	for i: int in range(_bunker_count):
		var bunker: Bunker = BUNKER_SCENE.instantiate()
		add_child(bunker)
		bunker.initialize(self)
		bunker.position = Vector2((i + 0.5) * placement_width, size.y - 80)
		_bunkers.append(bunker)


func _create_aliens() -> void:
	assert(_aliens.is_empty())
	_alien_dir = AlienMovement.RIGHT
	_bottom_alien_in_each_column = []
	var placement: Vector2i = Vector2i(int(size.x / float(_alien_cols + 5)), int(size.y / float(_alien_rows + 5)))
	var aid: int = 0
	for x: int in range(_alien_cols):
		for y: int in range(_alien_rows):
			_create_alien((x + 0.5) * placement.x, (y + 0.5) * placement.y, x, y)
			aid += 1
			_aliens.back().name = str("Alien#%d" % [aid])
	for alien: AlienShip in _bottom_alien_in_each_column:
		alien.power_up_weapon(_rnd.randf())


func _create_starfield() -> void:
	var starfield_image: Image = Image.create_empty(int(size.x * 2), int(size.y), false, Image.FORMAT_RGB8)
	starfield_image.fill(Color.BLACK)
	for i: int in range(3):
		_add_galaxy(starfield_image, 500 + _rnd.randi() % 2500, _rnd)
	for i: int in range(7):
		_add_stars(starfield_image, 100 * i, _rnd.randf() * starfield_image.get_size().x, _rnd.randf() * starfield_image.get_size().y, true, _rnd)
	_add_stars(starfield_image, 1000, 0, 0, false, _rnd)
	var starfield_texture: Texture = ImageTexture.create_from_image(starfield_image)
	%StarfieldImage.texture = starfield_texture
	%Parallax2D.repeat_size = starfield_image.get_size()
	#%Parallax2D.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func register_menu_scene(menu_state_machine: StateMachine) -> void:
	_menu_state_machine = menu_state_machine


func on_alien_died(alien: AlienShip) -> void:
	assert(_aliens.has(alien))
	_minor_currency += 1
	var col: int = alien.get_col()
	_aliens.erase(alien)
	if _bottom_alien_in_each_column[col] == alien:
		var next_alien: AlienShip = _find_lowest_alien_in_row(col)
		_bottom_alien_in_each_column[col] = next_alien
		if next_alien != null:
			next_alien.power_up_weapon(min(_rnd.randf(), _rnd.randf()))
	if _aliens.is_empty():
		_on_level_won()


func _find_lowest_alien_in_row(col: int) -> AlienShip:
	var ret_val: AlienShip = null
	for alien: AlienShip in _aliens:
		if alien.get_col() == col:
			if ret_val == null or alien.position.y > ret_val.position.y:
				ret_val = alien
	return ret_val


static func _add_galaxy(image: Image, count: int, rnd: RandomNumberGenerator) -> void:
	var isize: Vector2 = image.get_size()
	var cx: int = rnd.randi() % int(isize.x)
	var cy: int = rnd.randi() % int(isize.y)
	var tilt_x: float = rnd.randf() * PI / 3.0
	var tilt_y: float = rnd.randf() * PI / 3.0
	#var galaxy_angle: float = rnd.randf() * TAU
	#var galaxy_vector: Vector2 = Vector2(sin(galaxy_angle), cos(galaxy_angle))
	var max_dist: float = rnd.randf() * 100.0 + 50.0
	var spiral_offset: float = rnd.randf() * TAU
	var spiral_dir: bool = (rnd.randi() % 2) == 1
	for i: int in range(count):
		var dist: float = rnd.randf() * max_dist
		var radian: float = rnd.randf()
		for j: int in range(dist / 5):
			var nrad: float = rnd.randf()
			if nrad < radian:
				radian = nrad
		if rnd.randi() % 2 == 1:
			radian += 1
		if rnd.randi() % 2 == 1:
			radian = -radian
		if spiral_dir:
			radian += dist / max_dist
		else:
			radian -= dist / max_dist
		radian *= PI
		radian += spiral_offset
		var sx: float = cx + sin(radian) * dist
		var sy: float = cy + cos(radian) * dist
		#rotate in 3d space
		var rx: float = sx * cos(tilt_y) + sy * sin(tilt_x) * sin(tilt_y)
		var ry: float = sy * cos(tilt_x)
		
		var px: int = int(isize.x + rx) % int(isize.x)
		var py: int = int(isize.y + ry) % int(isize.y)
		var hh: float = 0.33 + image.get_pixel(px, py).get_luminance()
		if hh > 1.0:
			hh = 1.0
		image.set_pixel(px, py, Color(hh,hh,hh))


static func _add_stars(image: Image, count: int, center_x: float, center_y: float, force: bool, rnd: RandomNumberGenerator) -> void:
	var isize: Vector2 = image.get_size()
	var center_point: Vector2 = isize / 2.0
	for i: int in range(count):
		var sx: float = -1
		var sy: float = -1
		if force:
			for j: int in range(15):
				var sx_a: float = rnd.randf() * isize.x
				var sy_a: float = rnd.randf() * isize.y
				if sx < 0 or Vector2(sx_a, sy_a).distance_squared_to(center_point) < Vector2(sx, sy).distance_squared_to(center_point):
					sx = sx_a
					sy = sy_a
		else:
			sx = rnd.randf() * isize.x
			sy = rnd.randf() * isize.y
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
		if count % 10 == 1:
			_add_large_star(image, sx, sy)
		else:
			_add_small_star(image, sx, sy)


static func _add_small_star(image: Image, sx: float, sy: float) -> void:
	var isize: Vector2 = image.get_size()
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


static func _add_large_star(image: Image, sx: float, sy: float) -> void:
	var isize: Vector2 = image.get_size()
	var lx: int = int(sx)
	var ly: int = int(sy)
	var mx: int = (lx + 1) % int(isize.x)
	var my: int = (ly + 1) % int(isize.y)
	var hx: int = (lx + 2) % int(isize.x)
	var hy: int = (ly + 2) % int(isize.y)
	var ax: float = (sx - float(lx))
	var ay: float = (sy - float(ly))
	var ll: float = max((1.0 - ax) * (1.0 - ay), image.get_pixel(lx, ly).get_luminance())
	var lm: float = max((1.0 - ax), image.get_pixel(lx, my).get_luminance())
	var lh: float = max((1.0 - ax) * ay, image.get_pixel(lx, hy).get_luminance())
	var ml: float = max((1.0 - ay), image.get_pixel(mx, ly).get_luminance())
	var mh: float = max(ay, image.get_pixel(mx, hy).get_luminance())
	var hl: float = max(ax * (1.0 - ay), image.get_pixel(hx, ly).get_luminance())
	var hm: float = max(ax, image.get_pixel(hx, my).get_luminance())
	var hh: float = max(ax * ay, image.get_pixel(hx, hy).get_luminance())
	image.set_pixel(lx, ly, Color(ll, ll, ll))
	image.set_pixel(lx, my, Color(lm, lm, lm))
	image.set_pixel(lx, hy, Color(lh, lh, lh))
	image.set_pixel(mx, ly, Color(ml, ml, ml))
	image.set_pixel(mx, my, Color(1.0, 1.0, 1.0))
	image.set_pixel(mx, hy, Color(mh, mh, mh))
	image.set_pixel(hx, ly, Color(hl, hl, hl))
	image.set_pixel(hx, my, Color(hm, hm, hm))
	image.set_pixel(hx, hy, Color(hh, hh, hh))


func _create_alien(x: float, y: float, col: int, row: int) -> void:
	var alien: AlienShip = ALIEN_SHIP.instantiate()
	alien.position = Vector2(x, y)
	var alien_type: AlienShip.ShipType = AlienShip.ShipType.Regular
	if col == 2 or col == 5 or col == 8:
		alien_type = _primary_alien_type
	elif col == 1 or col == 9:
		alien_type = _secondary_alien_type
	alien.initialize(self, col, row, alien_type)
	add_child(alien)
	_aliens.append(alien)
	if _bottom_alien_in_each_column.size() <= col:
		_bottom_alien_in_each_column.append(alien)
	else:
		_bottom_alien_in_each_column[col] = alien


func get_ship_shielded_dir(alien_ship: AlienShip) -> int:
	var hit_col: int = alien_ship.get_col()
	var hit_row: int = alien_ship.get_row()
	for other: AlienShip in _aliens:
		if other.has_shield():
			if other.get_row() == hit_row:
				var other_col: int = other.get_col()
				if other_col == hit_col - 1:
					return -1
				elif other_col == hit_col + 1:
					return 1
	return 0


func _create_player() -> void:
	assert(_player == null)
	_player = PLAYER.instantiate()
	_player.initialize(self)
	add_child(_player)
	_place_player_in_spawn_location()


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
		var elapsed: float = abs(tuple[2]) - tuple[1]
		if elapsed < FADE_IN:
			value = Tween.interpolate_value(1.0, value - 1.0, elapsed, abs(tuple[2]), Tween.TRANS_QUAD, Tween.EASE_OUT)
		elif tuple[2] > 0:
			value = Tween.interpolate_value(value, 1.0 - value, elapsed - FADE_IN, tuple[2] - FADE_IN, Tween.TRANS_QUAD, Tween.EASE_OUT)
		assert(value >= tuple[0])
		if value < _time_dilation:
			_time_dilation = value
		var remaining: float = tuple[1] - delta
		if remaining < 0 && tuple[2] > 0:
			print("Removing time dilation: %s since remaining is now %s" % [tuple, remaining])
			continue
		new_td.append([tuple[0], remaining, tuple[2]])
	_time_dilation_array = new_td
	%Parallax2D.autoscroll = Vector2(STAR_SCROLL_AMOUNT * _time_dilation, 0.0)
	$Background.rotation += delta * _time_dilation * STAR_ROTATION_AMOUNT
	if Input.is_key_pressed(KEY_P) and not _aliens.is_empty():
		for alien: AlienShip in _aliens:
			alien.die()


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
		_alien_speed_multiple += 0.25
	
	if _alien_dir == AlienMovement.RIGHT:
		_move_all_aliens(tdd * Vector2.RIGHT, true, min_x, max_x, max_alien_y)
	elif _alien_dir == AlienMovement.LEFT:
		_move_all_aliens(tdd * Vector2.LEFT, true, min_x, max_x, max_alien_y)


func _move_all_aliens(velocity: Vector2, watch_margin: bool, min_x: float, max_x: float, max_alien_y: float) -> void:
	var mod_vel: Vector2 = velocity * ALIEN_SPEED
	#if _alien_dir != AlienMovement.DOWN:
	mod_vel *= _alien_speed_multiple
	for alien: AlienShip in _aliens:
		alien.position += mod_vel
		if watch_margin:
			if alien.position.x < min_x:
				_alien_dir = AlienMovement.DOWN
				_alien_downward_goal = max_alien_y + ALIEN_DROP_DISTANCE
				watch_margin = false
			elif alien.position.x > max_x:
				_alien_dir = AlienMovement.DOWN
				_alien_downward_goal = max_alien_y + ALIEN_DROP_DISTANCE
				watch_margin = false
		if alien.position.y > _player.position.y:
			if not _game_over:
				_on_game_over()


func on_bunker_destroyed(bunker: Bunker) -> void:
	assert(_bunkers.has(bunker))
	_bunkers.erase(bunker)
	bunker.queue_free()


func on_player_death() -> void:
	_place_player_in_spawn_location()
	_set_player_lives(_player_lives - 1)
	if _player_lives > 0:
		_player.start_respawn(1.0)
	elif not _game_over:
		_on_game_over()


func _on_level_won() -> void:
	_time_dilation_array = [[0, 1, -1]]
	var tween: Tween = create_tween()
	%Congrats.show()
	%Congrats.modulate.a = 0
	tween.tween_property(%Congrats, "modulate:a", 1, 2)
	_player.queue_free()
	_player = null
	get_tree().call_group("bullet", "queue_free")
	var wait_time: float = 0
	if _bunkers.is_empty():
		wait_time = 1.5
	else:
		for bunker: Bunker in _bunkers:
			wait_time = max(wait_time, _cash_in_bunker(tween, bunker))
		_bunkers = []
	assert(_major_currency <= _bunker_count)
	PlayerStats.on_wave_end(_minor_currency, _difficulty, _major_currency == _bunker_count)
	tween.tween_interval(wait_time)
	tween.tween_callback(Callable(self, "initialize").bind(_difficulty + 1))


func _cash_in_bunker(coord_tween: Tween, bunker: Bunker) -> float:
	_major_currency += 1
	# TODO: Spawn coin on fading bunker
	var coin_sprite: Sprite2D = Sprite2D.new()
	var bunker_size: Vector2 = bunker._sprite.texture.get_size()
	coin_sprite.position = bunker.position + Vector2.UP * 25 # + bunker_size / 2
	coin_sprite.centered = true
	coin_sprite.texture = COIN_TEXTURE
	var ratio: float = bunker_size.y / coin_sprite.texture.get_size().y
	coin_sprite.scale = Vector2(ratio, ratio)
	const FADE_TIME: float = 1.0
	coord_tween.tween_callback(Callable(self, "_spawn_coin").bind(coin_sprite, FADE_TIME))
	coord_tween.parallel()
	coord_tween.tween_property(bunker, "modulate:a", 0, FADE_TIME / 2.0)
	coord_tween.tween_callback(Callable(bunker, "queue_free"))
	#coord_tween.tween_interval(FADE_TIME / 2.0)
	return FADE_TIME / 2.0


func _spawn_coin(coin_sprite: Sprite2D, time: float) -> void:
	var tween: Tween = create_tween()
	add_child(coin_sprite)
	#coin_sprite.modulate.a = 0.01
	#tween.tween_property(coin_sprite, "modulate:a", 0.0, 0.01)
	#tween.tween_interval(0.01)
	tween.tween_property(coin_sprite, "modulate:a", 1.0, time / 4.0)
	tween.parallel().tween_callback(Callable($CoinNoise, "play"))
	tween.parallel().tween_property(coin_sprite, "position", coin_sprite.position + Vector2.UP	* 150, time)
	tween.parallel().tween_property(coin_sprite, "modulate:a", 0.0, time)
	tween.tween_callback(Callable(coin_sprite, "queue_free"))


func _on_game_over() -> void:
	_game_over = true
	PlayerStats.on_wave_end(_minor_currency, _difficulty, false)
	_time_dilation_array = [[0, 1, -1]]
	var tween: Tween = create_tween()
	%GameOverLabel.show()
	%GameOverLabel.modulate.a = 0
	tween.tween_property(%GameOverLabel, "modulate:a", 1, 3)
	tween.tween_interval(1.5)
	tween.tween_callback(Callable(self, "_on_exit_board"))


func _update_upgrades() -> void:
	#PlayerStats.add_currency(_minor_currency, _major_currency)
	_menu_state_machine.switch_state("MainMenu")


func _on_exit_board() -> void:
	var root: Window = get_tree().root
	var current_scene: Node = get_tree().current_scene
	assert(current_scene is Board)
	_update_upgrades()
	root.add_child(_menu_state_machine)
	get_tree().current_scene = _menu_state_machine
	if current_scene != null:
		current_scene.queue_free()


func _place_player_in_spawn_location() -> void:
	_player.position = Vector2(size.x / 2.0, get_player_floor())


func get_player_floor() -> float:
	return size.y - 40


func spawn_alien_bullet(pos: Vector2, acid: bool) -> void:
	var bullet: AlienBullet 
	if acid:
		bullet = DROP_BULLET.instantiate()
	else:
		bullet = ALIEN_BULLET.instantiate()
	bullet.position = pos
	bullet.initialize(self, _rnd)
	add_child(bullet)


func get_player_bullet_speed_multiple() -> float:
	return _player_bullet_speed_multiple


func spawn_player_bullet(pos: Vector2) -> void:
	var bullet: PlayerBullet = PLAYER_BULLET.instantiate()
	bullet.position = pos
	bullet.initialize(self, _rnd)
	add_child(bullet)
	
