class_name Player extends Area2D


const SPEED: float = 400
const GUN_COOLDOWN: float = 0.6


enum PlayerState {
	UNDEFINED,
	ACTIVE,
	DYING,
	RESPAWNING,
}


const DEATH_STREAM: Resource = preload("res://Sounds/ElectroExplosion002.wav")
const RESPAWN_STREAM: Resource = preload("res://Sounds/Engine001.wav")


var _board: Board
var _direction_vector: Vector2 = Vector2.ZERO
var _cached_shape: ConvexPolygonShape2D
var _min_x: float
var _max_x: float
var _gun_cooldown: float = 0
var _state: PlayerState = PlayerState.UNDEFINED


func initialize(board: Board) -> void:
	_board = board
	_min_x = 27 * 3 / 4.0
	_max_x = board.size.x - _min_x
	_state = PlayerState.ACTIVE
	self.show()


func _ready() -> void:
	_cached_shape = ConvexPolygonShape2D.new()
	_cached_shape.set_point_cloud(%CollisionPolygon2D.polygon)


func _process(delta: float) -> void:
	_gun_cooldown -= delta * _board.get_time_dilation()
	if _state != PlayerState.ACTIVE:
		return

	if Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			_direction_vector = Vector2.ZERO
		else:
			var right: float = Input.get_action_strength("move_right")
			_direction_vector = Vector2.RIGHT * right if position.x < _max_x else Vector2.ZERO
	elif Input.is_action_pressed("move_left"):
		var left: float = Input.get_action_strength("move_left")
		_direction_vector = Vector2.LEFT * left if position.x > _min_x else Vector2.ZERO
	else:
		_direction_vector = Vector2.ZERO
	if Input.is_action_pressed("fire"):
		_attempt_fire()


func _attempt_fire() -> void:
	if _gun_cooldown > 0:
		return
	_gun_cooldown = GUN_COOLDOWN
	_board.spawn_player_bullet(position)


func _on_hit_by_alien_bullet(_bullet: AlienBullet) -> void:
	_die()


func _on_hit_by_alien_ship(_alien: AlienShip) -> void:
	_die()


func _die() -> void:
	if _state != PlayerState.ACTIVE:
		return
	_state = PlayerState.DYING
	$AudioStreamPlayer2D.stream = DEATH_STREAM
	$AudioStreamPlayer2D.play()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(self, "hide"))
	tween.tween_property(self, "modulate:a", 1.0, 0.01)
	tween.tween_callback(Callable(_board, "on_player_death"))


func start_respawn(time_to_respawn: float) -> void:
	_state = PlayerState.RESPAWNING
	self.hide()
	var offscreen: Vector2 = position + Vector2(0, 50)
	var return_spot: Vector2 = position
	position = offscreen
	self.show()
	$AudioStreamPlayer2D.stream = RESPAWN_STREAM
	#$AudioStreamPlayer2D.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	$AudioStreamPlayer2D.play()
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", return_spot, time_to_respawn)
	tween.tween_callback(Callable(self, "_respawn_complete"))


func _respawn_complete() -> void:
	_state = PlayerState.ACTIVE
	$AudioStreamPlayer2D.stop()


func _on_audio_stream_finished() -> void:
	if _state == PlayerState.RESPAWNING:
		$AudioStreamPlayer2D.play()


func _physics_process(delta: float) -> void:
	var velocity: Vector2 = _direction_vector * SPEED * delta * _board.get_time_dilation()
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
				if hit_object is AlienBullet:
					_on_hit_by_alien_bullet(hit_object as AlienBullet)
				elif hit_object is AlienShip:
					_on_hit_by_alien_ship(hit_object as AlienShip)
				else:
					print("Player collided with %s" % [hit_object])
	
	position += velocity
