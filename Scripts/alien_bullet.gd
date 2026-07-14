class_name AlienBullet extends Bullet

const EXPLOSION_SCENE: Resource = preload("res://Scenes/missle_impact.tscn")

const SPEED: float = 200
@onready var _collision_poly: CollisionPolygon2D = $CollisionPolygon2D
var _cached_shape: ConvexPolygonShape2D
var _floor: float
var _board: Board


func _ready() -> void:
	_cached_shape = ConvexPolygonShape2D.new()
	_cached_shape.points = _collision_poly.polygon
	$AudioStreamPlayer2D.play()


func get_damage() -> int:
	return 45


func initialize(flr: float, board: Board, rnd: RandomNumberGenerator) -> void:
	_floor = flr
	_board = board
	$AudioStreamPlayer2D.volume_db += rnd.randf() * 2 - 1.0
	$AudioStreamPlayer2D.pitch_scale *= (0.85 + rnd.randf() * 0.3)


func die_against_bunker(bunker: Bunker, hit_offset: Vector2) -> void:
	#_board.start_time_dilation(0.05)
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = hit_offset
	bunker.add_child(explosion)
	queue_free()


# Called when a player's bullet hits our bullet
func on_bullet_impact(player_bullet: Bullet, point: Vector2, _velocity: Vector2) -> void:
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = point
	_board.add_child(explosion)
	player_bullet.die_against_alien_bullet(point)
	queue_free()


func _physics_process(delta: float) -> void:
	var velocity: Vector2 = Vector2.DOWN * SPEED * delta * _board.get_time_dilation()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _cached_shape
	query.transform = global_transform.translated(velocity)
	query.collision_mask = collision_mask
	query.exclude = [self.get_rid()]

	var results: Array[Dictionary] = space_state.intersect_shape(query)
	if not results.is_empty():
		var rest_info = space_state.get_rest_info(query)
		if not rest_info.is_empty():
			for collision_data: Dictionary in results:
				var hit_object = collision_data.collider
				if hit_object.has_method("on_bullet_impact"):
					hit_object.on_bullet_impact(self, position, velocity)
				else:
					print("Bullet impact against %s, which does not have on_bullet_impact() function" % [hit_object])
	
	position += velocity
	if position.y > _floor:
		queue_free()
