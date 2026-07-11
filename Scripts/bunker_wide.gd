class_name Bunker extends StaticBody2D

var _bitmap: BitMap
var _sprite: Sprite2D
var _image: Image
var _texture: Texture2D
#var _polygon_2d: Polygon2D
var _delay: float = 2
var _rnd: RandomNumberGenerator


func _ready() -> void:
	_bitmap = BitMap.new()
	_rnd = RandomNumberGenerator.new()
	call_deferred("_deferred_ready")


func _deferred_ready() -> void:
	_sprite = $Sprite2D
	_texture = _sprite.texture
	_image = _texture.get_image()
	_bitmap.create_from_image_alpha(_image)
	_calculate_image_and_collision()


func _process(delta: float) -> void:
	_delay -= delta
	if _delay > 0:
		return
	_delay = 0.5
	_apply_damage(_rnd.randi() % _bitmap.get_size().x)


func _apply_damage(x: int) -> void:
	var height: int = _bitmap.get_size().y
	var width: int = _bitmap.get_size().x
	for y in range(height):
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
		return


func _calculate_image_and_collision() -> void:
	var image_rect: Rect2 = Rect2(Vector2.ZERO, _image.get_size())
	var polygons: Array[PackedVector2Array] = _bitmap.opaque_to_polygons(image_rect)
	if not polygons.is_empty():
		#_polygon_2d.polygon = polygons[0]
		$CollisionPolygon2D.polygon = polygons[0]
	var width: int = _bitmap.get_size().x
	var height: int = _bitmap.get_size().y
	for x in range(width):
		for y in range(height):
			var bit_set: bool = _bitmap.get_bitv(Vector2i(x, y))
			var pixel_color: Color = Color.WHITE if bit_set else Color.TRANSPARENT
			_image.set_pixel(x, y, pixel_color)
	_texture = ImageTexture.create_from_image(_image)
	_sprite.texture = _texture
