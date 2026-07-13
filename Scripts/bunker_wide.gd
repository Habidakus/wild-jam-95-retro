class_name Bunker extends StaticBody2D

var _bitmap: BitMap
var _sprite: Sprite2D
var _image: Image
var _texture: Texture2D
#var _delay: float = 2
var _rnd: RandomNumberGenerator

func _ready() -> void:
	_bitmap = BitMap.new()
	_rnd = RandomNumberGenerator.new()
	_sprite = $Sprite2D
	_texture = _sprite.texture
	_image = _texture.get_image()
	_bitmap.create_from_image_alpha(_image)
	_calculate_image_and_collision()
	var image_rect: Rect2 = Rect2(Vector2.ZERO, _image.get_size())
	var polygons: Array[PackedVector2Array] = _bitmap.opaque_to_polygons(image_rect, 0.75)
	if not polygons.is_empty():
		$CollisionPolygon2D.polygon = polygons[0]
		$CollisionPolygon2D.position = _image.get_size() / -2.0


func on_bullet_impact(bullet: Bullet, point: Vector2, velocity: Vector2) -> void:
	var s: Vector2 = _bitmap.get_size()
	var dx: int = int(s.x / 2.0 + point.x - position.x)
	if velocity.y > 0:
		var range_start: float = 0.0
		var range_end: float = s.y / 2 + point.y + velocity.y - position.y
		if range_end < range_start:
			return
		var ir_start: int = int(range_start)
		var ir_end: int = int(min(range_end + 1.0, s.y))
		for dy in range(ir_start, ir_end):
			var bit_set: bool = _bitmap.get_bitv(Vector2i(dx, dy))
			if bit_set:
				var ay: int = _apply_damage_down(dx, dy)
				if ay < 0:
					return
				var hit_offset: Vector2 = Vector2(dx - (s.x / 2.0), ay - (s.y / 2.0))
				bullet.die_against_bunker(self, hit_offset)
	else:
		var range_start: float = s.y - 1
		var range_end: float = s.y / 2 + point.y + velocity.y - position.y
		if range_end > range_start:
			return
		var ir_start: int = int(range_start)
		var ir_end: int = int(max(range_end - 1.0, 0))
		for dy in range(ir_start, ir_end, -1):
			var bit_set: bool = _bitmap.get_bitv(Vector2i(dx, dy))
			if bit_set:
				var ay: int = _apply_damage_up(dx, dy)
				if ay < 0:
					return
				var hit_offset: Vector2 = Vector2(dx - (s.x / 2.0), ay - (s.y / 2.0))
				bullet.die_against_bunker(self, hit_offset)


func _apply_damage_down(x: int, start_y: int) -> int:
	var height: int = _bitmap.get_size().y
	var width: int = _bitmap.get_size().x
	for y in range(start_y, height):
		var bit_set: bool = _bitmap.get_bitv(Vector2i(x, y))
		if not bit_set:
			continue
		_bitmap.set_bitv(Vector2i(x, y), false)
		if y + 1 < height:
			_bitmap.set_bitv(Vector2i(x, y + 1), false)
		if x + 1 < width:
			_bitmap.set_bitv(Vector2i(x + 1, y), false)
		if x > 0:
			_bitmap.set_bitv(Vector2i(x - 1, y), false)
		_calculate_image_and_collision()
		return y
	return -1

func _apply_damage_up(x: int, start_y: int) -> int:
	#var height: int = _bitmap.get_size().y
	var width: int = _bitmap.get_size().x
	for y in range(start_y, -1, -1):
		var bit_set: bool = _bitmap.get_bitv(Vector2i(x, y))
		if not bit_set:
			continue
		_bitmap.set_bitv(Vector2i(x, y), false)
		if y > 0:
			_bitmap.set_bitv(Vector2i(x, y - 1), false)
		if x + 1 < width:
			_bitmap.set_bitv(Vector2i(x + 1, y), false)
		if x > 0:
			_bitmap.set_bitv(Vector2i(x - 1, y), false)
		_calculate_image_and_collision()
		return y
	return -1


func _calculate_image_and_collision() -> void:
	var width: int = _bitmap.get_size().x
	var height: int = _bitmap.get_size().y
	for x in range(width):
		for y in range(height):
			var bit_set: bool = _bitmap.get_bitv(Vector2i(x, y))
			var pixel_color: Color = Color.WHITE if bit_set else Color.TRANSPARENT
			_image.set_pixel(x, y, pixel_color)
	_texture = ImageTexture.create_from_image(_image)
	_sprite.texture = _texture
