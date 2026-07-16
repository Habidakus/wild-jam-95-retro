class_name Bunker extends StaticBody2D

const BASIC_BUNKER_IMAGE: Texture = preload("res://Images/test_bunker.png")
const WIDE_BUNKER_IMAGE: Texture = preload("res://Images/test_bunker_wide.png")
const VERY_WIDE_BUNKER_IMAGE: Texture = preload("res://Images/test_bunker_very_wide.png")


var _bitmap: BitMap
var _sprite: Sprite2D
var _image: Image
var _texture: Texture2D
var _rnd: RandomNumberGenerator
var _board: Board


func _ready() -> void:
	_bitmap = BitMap.new()
	_rnd = RandomNumberGenerator.new()
	_sprite = $Sprite2D


func initialize(board: Board) -> void:
	_board = board
	var max_bunker_width: float = PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.BUNKER_WIDTH)
	if max_bunker_width >= 2.0:
		_texture = VERY_WIDE_BUNKER_IMAGE
	elif max_bunker_width >= 1.0:
		_texture = WIDE_BUNKER_IMAGE
	else:
		_texture = BASIC_BUNKER_IMAGE
	print(str(_texture.get_size()))
	_image = _texture.get_image()
	_bitmap.create_from_image_alpha(_image)
	_calculate_image_and_collision()
	var image_rect: Rect2 = Rect2(Vector2.ZERO, _image.get_size())
	var polygons: Array[PackedVector2Array] = _bitmap.opaque_to_polygons(image_rect, 0.75)
	if not polygons.is_empty():
		$CollisionPolygon2D.polygon = polygons[0]
		$CollisionPolygon2D.position = _image.get_size() / -2.0


func _apply_damage(amount: int, impact_point: Vector2i) -> void:
	var select_array: Array = []
	var s: Vector2 = _bitmap.get_size()
	var maxd: float = 0
	for x: int in range(s.x):
		for y: int in range(s.y):
			var bit_coord: Vector2i = Vector2i(x, y)
			if _bitmap.get_bitv(bit_coord):
				var dist: float = impact_point.distance_squared_to(bit_coord)
				maxd = max(maxd, dist)
				select_array.append([bit_coord, dist])
	if select_array.size() > amount:
		for entry: Array in select_array:
			var alt: float = max(_rnd.randf(), _rnd.randf()) * maxd
			#var alt: float = rnd.randf() * maxd
			if entry[1] > alt:
				entry[1] = alt
		select_array.sort_custom(func(a, b): return a[1] < b[1])
	for i: int in range(min(amount, select_array.size())):
		_bitmap.set_bitv(select_array[i][0], false)
	_calculate_image_and_collision()


func on_ship_impact(alien: AlienShip) -> void:
	if alien.is_dead():
		return
	var s: Vector2 = _bitmap.get_size()
	var dx: int = int(s.x / 2.0 + alien.position.x - position.x)
	var dy: int = int(s.y / 2.0 + alien.position.y - position.y)
	_apply_damage(alien.get_impact_damage(), Vector2i(dx, dy))
	alien.die()


func on_bullet_impact(bullet: Bullet, point: Vector2, velocity: Vector2) -> void:
	if bullet.is_dead():
		return
	var s: Vector2 = _bitmap.get_size()
	var dx: int = int(s.x / 2.0 + point.x - position.x)
	if dx < 0.0:
		dx = 0
	elif dx >= s.x:
		dx = int(s.x) - 1
	if velocity.y > 0:
		var range_start: float = 0.0
		var range_end: float = s.y / 2 + point.y + velocity.y - position.y
		if range_end < range_start:
			return
		var ir_start: int = int(range_start)
		var ir_end: int = int(min(range_end + 1.0, s.y))
		for dy in range(ir_start, ir_end):
			var impact: Vector2 = Vector2i(dx, dy)
			var bit_set: bool = _bitmap.get_bitv(impact)
			if bit_set:
				_apply_damage(bullet.get_damage(), impact)
				var hit_offset: Vector2 = Vector2(dx - (s.x / 2.0), dy - (s.y / 2.0))
				bullet.die_against_bunker(self, hit_offset)
	else:
		var range_start: float = s.y - 1
		var range_end: float = s.y / 2 + point.y + velocity.y - position.y
		if range_end > range_start:
			return
		var ir_start: int = int(range_start)
		var ir_end: int = int(max(range_end - 1.0, 0))
		for dy in range(ir_start, ir_end, -1):
			var impact: Vector2 = Vector2i(dx, dy)
			var bit_set: bool = _bitmap.get_bitv(impact)
			if bit_set:
				_apply_damage(bullet.get_damage(), impact)
				var hit_offset: Vector2 = Vector2(dx - (s.x / 2.0), dy - (s.y / 2.0))
				bullet.die_against_bunker(self, hit_offset)


func _calculate_image_and_collision() -> void:
	var width: int = _bitmap.get_size().x
	var height: int = _bitmap.get_size().y
	var any: bool = false
	for x in range(width):
		for y in range(height):
			var bit_set: bool = _bitmap.get_bitv(Vector2i(x, y))
			any = any || bit_set
			var pixel_color: Color = Color.WHITE if bit_set else Color.TRANSPARENT
			_image.set_pixel(x, y, pixel_color)
	_texture = ImageTexture.create_from_image(_image)
	_sprite.texture = _texture
	if not any:
		_board.on_bunker_destroyed(self)
