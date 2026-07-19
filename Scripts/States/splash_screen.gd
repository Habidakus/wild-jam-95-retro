class_name SplashScreen extends StateMachineState_PressAnyKey

var _rnd: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	var starfield_image: Image = Image.create_empty(int(size.x * 2), int(size.y), false, Image.FORMAT_RGB8)
	starfield_image.fill(Color.BLACK)
	
	var placed_galaxies: Array[Vector2] = []
	for i: int in range(4):
		var gv: Vector2 = Board._find_galaxy_center(placed_galaxies, _rnd)
		Board._add_galaxy(starfield_image, 1000 + _rnd.randi() % 2000, _rnd, gv)
	for i: int in range(7):
		Board._add_stars(starfield_image, 100 * i, _rnd.randf() * starfield_image.get_size().x, _rnd.randf() * starfield_image.get_size().y, true, _rnd)
	Board._add_stars(starfield_image, 1000, 0, 0, false, _rnd)
	var starfield_texture: Texture = ImageTexture.create_from_image(starfield_image)
	$ColorRect/TextureRect.texture = starfield_texture
	MusicPlayer.play_next_track()
