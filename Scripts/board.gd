class_name Board extends Control

const BUNKER_SCENE = preload("res://Scenes/bunker_wide.tscn")
const PLAYER_BULLET = preload("res://Scenes/player_bullet.tscn")
const SHOTGUN_BULLET = preload("res://Scenes/shotgun_bullet.tscn")
const ALIEN_BULLET = preload("res://Scenes/alien_bullet.tscn")
const DROP_BULLET = preload("res://Scenes/alien_flame_bullet.tscn")
const ALIEN_SHIP = preload("res://Scenes/alien_ship.tscn")
const PLAYER = preload("res://Scenes/player.tscn")
const COIN_TEXTURE = preload("res://Images/coin.svg")
const HAPPY_BUNKER_SOUND = preload("res://Sounds/AlienYell001.wav")
const SAD_BUNKER_SOUND = preload("res://Sounds/AlienYell002.wav")
const ALIEN_SPEED: float = 40
const ALIEN_DROP_DISTANCE: float = 40
const STAR_ROTATION_AMOUNT: float = 0.0015
const STAR_ROTATION_DIFF_DELTA: float = 0.0003
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
var _difficulty: int = 0
var _player_bullet_speed_multiple: float = 1.0
var _primary_alien_type: AlienShip.ShipType = AlienShip.ShipType.Regular
var _secondary_alien_type: AlienShip.ShipType = AlienShip.ShipType.Regular
var _master_difficulty_list: Array[Array] = []
var _power_tracker: Array = []
var _power_tracker_tween: Tween = null


func _ready() -> void:
	var first_wave: int = int(round(PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.SKIP_TO_LEVEL)))
	initialize(first_wave)
	_set_player_lives(3 + int(round(PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.LIVES_HIGHER_MAX))))
	%PowerPBs.hide()
	_register_power(%PB_Particle, "power_1", PlayerBuff.BuffType.AMMO_PIERCING_POWER, PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.AMMO_PIERCING_COOLDOWN))
	_register_power(%PB_Shotgun, "power_2", PlayerBuff.BuffType.AMMO_SHOTGUN_AMOUNT, PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.AMMO_SHOTGUN_COOLDOWN))
	_register_power(%PB_Tracking, "power_3", PlayerBuff.BuffType.AMMO_SEEKER_POWER, PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.AMMO_SEEKER_COOLDOWN))
	if not _power_tracker.is_empty():
		_pulse_power_trackers(true)


func _pulse_power_trackers(play_sound: bool) -> void:
	if _power_tracker_tween != null:
		_power_tracker_tween.kill()
	if play_sound:
		%RechargeSound.play()
	_power_tracker_tween = create_tween()
	_power_tracker_tween.tween_property(%PowerPBs, "modulate:a", 1.0, 0.1)
	_power_tracker_tween.tween_interval(0.1)
	_power_tracker_tween.tween_property(%PowerPBs, "modulate:a", 0.5, 0.8)


func _fire_power(power: PlayerBuff.BuffType, strength: float, tpb: TextureProgressBar) -> void:
	tpb.value = 0
	_pulse_power_trackers(false)
	match power:
		PlayerBuff.BuffType.AMMO_PIERCING_POWER:
			_fire_piercing_power(strength)
		PlayerBuff.BuffType.AMMO_SHOTGUN_AMOUNT:
			_fire_shotgun_power(strength)
		_:
			assert(false)


func _fire_shotgun_power(strength: float) -> void:
	var top_of_tank: Vector2 = _player.get_barrel_position()
	%Shotgun_VFX.position = top_of_tank
	%Shotgun_VFX.one_shot = true
	%Shotgun_VFX.emitting = true
	%Shotgun_Audio.play()
	for i: int in range(strength):
		var bullet: ShotgunBullet = SHOTGUN_BULLET.instantiate()
		bullet.position = top_of_tank
		var direction: Vector2 = Vector2.DOWN
		for j: int in range(3):
			var v: Vector2 = Vector2(_rnd.randf() * 2.0 - 1.0, 0 - (_rnd.randf() + 0.1)).normalized()
			if v.distance_squared_to(Vector2.UP) < direction.distance_squared_to(Vector2.UP):
				direction = v
		bullet.initialize(self, direction)
		add_child(bullet)


func _fire_piercing_power(strength: float) -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape: SegmentShape2D = SegmentShape2D.new()
	var top_of_tank: Vector2 = _player.get_barrel_position()
	shape.a = top_of_tank
	shape.b = Vector2(top_of_tank.x, 0.0)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 2 + 4 + 8 # 2=alien bullet, 4=bunker, 8=aliens
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit_objects: Array = []
	var results: Array[Dictionary] = space_state.intersect_shape(query)
	if not results.is_empty():
		for collision_data: Dictionary in results:
			var hit_object = collision_data.collider
			if not hit_objects.has(hit_object):
				hit_objects.append(hit_object)
	hit_objects.sort_custom(func(a,b): return shape.a.distance_squared_to(a.position) < shape.a.distance_squared_to(b.position))
	var y_stopping_point: float
	for hit_object in hit_objects:
		if hit_object.has_method("on_particle_beam_impact"):
			y_stopping_point = hit_object.on_particle_beam_impact(top_of_tank.x)
			if y_stopping_point > 0:
				break
			strength -= 1.0
			if strength <= 0.0:
				y_stopping_point = hit_object.position.y
				break
	var height: float = top_of_tank.y - y_stopping_point
	var beam_center: Vector2 = (top_of_tank + Vector2(top_of_tank.x, y_stopping_point)) / 2.0
	%ParticleCannon_VFX.position = beam_center
	%ParticleCannon_VFX.emission_rect_extents = Vector2(0.95, height)
	%ParticleCannon_VFX.one_shot = true
	%ParticleCannon_VFX.emitting = true
	%ParticleCannon_Audio.play()


func _register_power(tpb: TextureProgressBar, input: String, power: PlayerBuff.BuffType, cooldown: float) -> void:
	var strength: float = PlayerStats.get_max_strength_acquired(power)
	if strength <= 0.0:
		tpb.hide()
		return
	%PowerPBs.show()
	tpb.show()
	tpb.max_value = 30.0 / (1.0 + cooldown)
	tpb.step = 0.01
	tpb.value = tpb.max_value
	_power_tracker.append([input, power, strength, tpb])


func _set_player_lives(amount: int) -> void:
	if _player_lives == amount:
		return
	_player_lives = amount
	var tween: Tween = create_tween()
	if amount > 0:
		tween.tween_property(%Lives, "modulate:a", 0, 0.1)
		%Lives.text = str(amount - 1)
		tween.tween_property(%Lives, "modulate:a", 1, 0.1)
		tween.tween_property(%Lives, "modulate:a", 0.5, 2)
	else:
		tween.tween_property(%Lives, "modulate:a", 0, 0.5)


func initialize(difficulty: int) -> void:
	_player_bullet_speed_multiple = (1.0 + PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.GUN_BULLET_SPEED))
	_time_dilation_array = []
	_minor_currency = 0
	%GameOverLabel.hide()
	%Congrats.hide()
	_initialize_difficulty(difficulty)
	_create_bunkers()
	_create_aliens()
	_create_starfield()
	_create_player()
	MusicPlayer.play_next_track()
	%WaveNumber.text = str("Wave %d" % [_difficulty + 1])
	var tween: Tween = create_tween()
	tween.tween_property(%WaveNumber, "modulate:a", 0.0, 0.2)
	tween.tween_property(%WaveNumber, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(%WaveNumber, "modulate:a", 0.0, 0.8)


func _initialize_difficulty(difficulty: int) -> void:
	_difficulty = difficulty
	if _master_difficulty_list.is_empty():
		_build_master_difficulty_list()
	var index: int = min(difficulty, _master_difficulty_list.size() - 1)
	_primary_alien_type = _master_difficulty_list[index][0]
	_secondary_alien_type = _master_difficulty_list[index][1]
	_alien_speed_multiple = _master_difficulty_list[index][2]


func _build_master_difficulty_list() -> void:
	assert(_master_difficulty_list.is_empty())
	for speed: int in range(0, 6):
		var asm: float = 1.0 + speed * 0.3333
		for primary: AlienShip.ShipType in AlienShip.ShipType.values():
			for secondary: AlienShip.ShipType in AlienShip.ShipType.values():
				if primary == secondary and primary != AlienShip.ShipType.Regular:
					continue # Never let two shields cover each other
				if primary == AlienShip.ShipType.Regular and secondary != AlienShip.ShipType.Regular and speed > 0:
					continue
				var prim_strength: float = AlienShip.get_strength(primary)
				var sec_strength: float = AlienShip.get_strength(secondary)
				if sec_strength < prim_strength:
					continue
				var strength: float = _calculate_wave_strength(primary, secondary, asm)
				_master_difficulty_list.append([primary, secondary, asm, strength])
	_master_difficulty_list.sort_custom(
		func(a, b):
			if a[2] != b[2]:
				return a[2] < b[2]
			if a[3] != b[3]:
				return a[3] < b[3]
			if a[1] != b[1]:
				return a[1] < b[1]
			return false
	)
	#var wave: int = 1
	#for entry: Array in _master_difficulty_list:
		#print("wave #%d: %s %s speed=%s" % [wave, AlienShip.ShipType.keys()[entry[0]], AlienShip.ShipType.keys()[entry[1]], entry[2]])
		#wave += 1


func _calculate_wave_strength(primary: AlienShip.ShipType, secondary: AlienShip.ShipType, speed: float) -> float:
	return AlienShip.get_strength(primary) * sqrt(AlienShip.get_strength(secondary)) * speed


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
	var placed_galaxies: Array[Vector2] = []
	for i: int in range(6):
		var gv: Vector2 = _find_galaxy_center(placed_galaxies, _rnd)
		_add_galaxy(starfield_image, 500 + _rnd.randi() % 2500, _rnd, gv)
	for i: int in range(7):
		_add_stars(starfield_image, 100 * i, _rnd.randf() * starfield_image.get_size().x, _rnd.randf() * starfield_image.get_size().y, true, _rnd)
	_add_stars(starfield_image, 1000, 0, 0, false, _rnd)
	var starfield_texture: Texture = ImageTexture.create_from_image(starfield_image)
	%StarfieldImage.texture = starfield_texture
	%Parallax2D.repeat_size = starfield_image.get_size()
	#%Parallax2D.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func _get_galaxy_closeness(a: Vector2, b: Vector2) -> float:
	var c: float = min(a.distance_squared_to(b), a.distance_squared_to(Vector2(-b.x, b.y)))
	var d: float = min(a.distance_squared_to(Vector2(b.x, -b.y)), a.distance_squared_to(Vector2(-b.x, -b.y)))
	return min(c, d)


static func _find_galaxy_center(previous: Array[Vector2], rnd: RandomNumberGenerator) -> Vector2:
	var initial: Vector2 = Vector2(rnd.randf(), rnd.randf())
	if previous.is_empty():
		previous.append(initial)
		return initial
	var iclose: float = 100.0
	for entry: Vector2 in previous:
		var tclose: float = _get_galaxy_closeness(entry, initial)
		if tclose < iclose:
			iclose = tclose
	var other: Vector2 = Vector2(rnd.randf(), rnd.randf())
	var oclose: float = 100.0
	for entry: Vector2 in previous:
		var tclose: float = _get_galaxy_closeness(entry, other)
		if tclose < oclose:
			oclose = tclose
	if iclose < oclose:
		previous.append(initial)
		return initial
	else:
		previous.append(other)
		return other


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


static func _add_galaxy(image: Image, count: int, rnd: RandomNumberGenerator, galaxy_center: Vector2) -> void:
	var isize: Vector2 = image.get_size()
	var cx: int = int(galaxy_center.x * isize.x)
	var cy: int = int(galaxy_center.y * isize.y)
	assert(cx >= 0 and cx < isize.x)
	assert(cy >= 0 and cy < isize.y)
	var tilt_x: float = rnd.randf() * PI / 3.0
	var tilt_y: float = rnd.randf() * PI / 3.0
	#var galaxy_angle: float = rnd.randf() * TAU
	#var galaxy_vector: Vector2 = Vector2(sin(galaxy_angle), cos(galaxy_angle))
	var max_dist: float = rnd.randf() * 200.0 + 50.0
	var spiral_offset: float = rnd.randf() * PI
	var spiral_dir: bool = (rnd.randi() % 2) == 1
	for i: int in range(count):
		var dist: float = rnd.randf()
		dist = dist * dist * max_dist
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
	$Background.rotation += delta * _time_dilation * (STAR_ROTATION_AMOUNT + STAR_ROTATION_DIFF_DELTA * _difficulty)
	for entry: Array in _power_tracker:
		if Input.is_action_just_pressed(entry[0]):
			var tpb: TextureProgressBar = entry[3]
			if tpb.value == tpb.max_value:
				_fire_power(entry[1], entry[2], entry[3])
	if OS.has_feature("editor"):
		if Input.is_key_pressed(KEY_P) and not _aliens.is_empty():
			for alien: AlienShip in _aliens:
				alien.die()


func _physics_process(delta: float) -> void:
	var tdd: float = delta * _time_dilation
	for entry: Array in _power_tracker:
		var tpb: TextureProgressBar = entry[3]
		if tpb.value < tpb.max_value:
			tpb.value += delta
			if tpb.value == tpb.max_value:
				_pulse_power_trackers(true)
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
			if _alien_dir != AlienMovement.DOWN:
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
	var has_all_bunkers: bool = false
	%BunkerComplete.step = 0.01
	%BunkerComplete.value = 0.0
	%BunkerComplete.modulate.a = 1.0
	%BunkerComplete.min_value = 0.0
	%BunkerComplete.max_value = float(_bunker_count)
	if _bunkers.is_empty():
		wait_time = 1.5
	else:
		has_all_bunkers = _bunkers.size() == _bunker_count
		var fill_value: int = 1
		for bunker: Bunker in _bunkers:
			wait_time = max(wait_time, _cash_in_bunker(tween, bunker, fill_value))
			fill_value += 1
		_bunkers = []
	var show_coin: bool = not PlayerStats.has_completed_difficulty(_difficulty)
	PlayerStats.on_wave_end(_minor_currency, _difficulty, has_all_bunkers)
	tween.tween_interval(wait_time)
	if show_coin:
		var major_current: Vector2 = %BunkerComplete.position
		if has_all_bunkers:
			var major_dest: Vector2 = major_current + Vector2.UP * 150
			%BunkerSound.stream = HAPPY_BUNKER_SOUND
			tween.tween_callback(Callable(%BunkerSound, "play"))
			tween.parallel().tween_property(%BunkerComplete, "position", major_dest, wait_time)
			tween.parallel().tween_property(%BunkerComplete, "modulate:a", 0.0, wait_time)
		else:
			%BunkerSound.stream = SAD_BUNKER_SOUND
			var major_dest: Vector2 = major_current + Vector2.DOWN * 50
			tween.tween_callback(Callable(%BunkerSound, "play"))
			tween.parallel().tween_property(%BunkerComplete, "position", major_dest, wait_time)
			tween.parallel().tween_property(%BunkerComplete, "value", 0.0, wait_time)
			tween.tween_property(%BunkerComplete, "modulate:a", 0.0, 0.0)
		tween.tween_property(%BunkerComplete, "position", major_current, 0.0)
	tween.tween_callback(Callable(self, "initialize").bind(_difficulty + 1))


func _cash_in_bunker(coord_tween: Tween, bunker: Bunker, fill_value: int) -> float:
	# TODO: Spawn coin on fading bunker
	var show_coin: bool = not PlayerStats.has_completed_difficulty(_difficulty)
	const FADE_TIME: float = 1.0
	if show_coin:
		var coin_sprite: Sprite2D = Sprite2D.new()
		var bunker_size: Vector2 = bunker._sprite.texture.get_size()
		coin_sprite.position = bunker.position + Vector2.UP * 25 # + bunker_size / 2
		coin_sprite.centered = true
		coin_sprite.texture = COIN_TEXTURE
		var ratio: float = bunker_size.y / coin_sprite.texture.get_size().y
		coin_sprite.scale = Vector2(ratio, ratio)
		coord_tween.tween_callback(Callable(self, "_spawn_coin").bind(coin_sprite, FADE_TIME, fill_value))
		coord_tween.parallel()
	coord_tween.tween_property(bunker, "modulate:a", 0, FADE_TIME / 2.0)
	coord_tween.tween_callback(Callable(bunker, "queue_free"))
	#coord_tween.tween_interval(FADE_TIME / 2.0)
	return FADE_TIME / 2.0 if show_coin else FADE_TIME / 4.0


func _spawn_coin(coin_sprite: Sprite2D, time: float, fill_value: float) -> void:
	var tween: Tween = create_tween()
	add_child(coin_sprite)
	#coin_sprite.modulate.a = 0.01
	#tween.tween_property(coin_sprite, "modulate:a", 0.0, 0.01)
	#tween.tween_interval(0.01)
	var destination: Vector2 = %BunkerComplete.position + %BunkerComplete.size / 2.0
	tween.tween_property(coin_sprite, "modulate:a", 1.0, time / 4.0)
	tween.parallel().tween_callback(Callable($CoinNoise, "play"))
	tween.parallel().tween_property(coin_sprite, "position", destination, time / 2.0)
	tween.parallel().tween_property(coin_sprite, "modulate:a", 0.0, time / 2.0)
	tween.tween_callback(Callable(coin_sprite, "queue_free"))
	tween.tween_property(%BunkerComplete, "value", float(fill_value), time / 2.0)


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
	
