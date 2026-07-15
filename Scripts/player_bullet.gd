class_name PlayerBullet extends Bullet

const EXPLOSION_SCENE: Resource = preload("res://Scenes/missle_impact.tscn")

const SPEED: float = 350
@onready var _collision_poly: CollisionPolygon2D = $CollisionPolygon2D
var _cached_shape: ConvexPolygonShape2D
var _board: Board
var _is_dead: bool = false


func _ready() -> void:
	_cached_shape = ConvexPolygonShape2D.new()
	_cached_shape.points = _collision_poly.polygon
	$AudioStreamPlayer2D.play()
	add_to_group("bullet")


func initialize(board: Board, rnd: RandomNumberGenerator) -> void:
	_board = board
	#$AudioStreamPlayer2D.volume_db += rnd.randf() * 2 - 1.0
	$AudioStreamPlayer2D.pitch_scale *= (0.65 + rnd.randf() * 0.3)


func get_damage() -> int:
	return 55


func die_against_bunker(bunker: Bunker, hit_offset: Vector2) -> void:
	if _is_dead:
		return
	_is_dead = true
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = hit_offset
	bunker.add_child(explosion)
	queue_free()


func die_against_alien(_alien: AlienShip, hit_offset: Vector2) -> void:
	if _is_dead:
		return
	_is_dead = true
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = hit_offset
	_board.add_child(explosion)
	queue_free()


func die_against_alien_bullet(hit_offset: Vector2) -> void:
	if _is_dead:
		return
	_is_dead = true
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = hit_offset
	_board.add_child(explosion)
	queue_free()


func is_dead() -> bool:
	return _is_dead


func _physics_process(delta: float) -> void:
	var velocity: Vector2 = Vector2.UP * SPEED * delta * _board.get_time_dilation()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _cached_shape
	query.transform = global_transform.translated(velocity)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
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
					print("Player bullet impact against %s, which does not have on_bullet_impact() function" % [hit_object])
	
	position += velocity
	if position.y < 0:
		queue_free()
