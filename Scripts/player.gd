class_name Player extends Area2D


const SPEED: float = 400
const BASE_GUN_COOLDOWN_RATE: float = 0.8


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
var _gun_cooldown_rate: float = BASE_GUN_COOLDOWN_RATE
var _state: PlayerState = PlayerState.UNDEFINED
var _active_shield: float = -1
var _shield_duration: float = -1
var _speed: float = 0
var _use_acceleration: bool = false


func initialize(board: Board) -> void:
	_board = board
	_min_x = 27 * 3 / 4.0
	_max_x = board.size.x - _min_x
	_state = PlayerState.ACTIVE
	show()
	_use_acceleration = PlayerStats.get_use_acceleration()
	var cooldown_strength: float = PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.GUN_RATE_OF_FIRE)
	_shield_duration = PlayerStats.get_max_strength_acquired(PlayerBuff.BuffType.RES_SHIELD)
	if _shield_duration > 0:
		_active_shield = _shield_duration
		%Shield.show()
		%Shield.modulate.a = 1.0
	else:
		%Shield.hide()
	_gun_cooldown_rate = BASE_GUN_COOLDOWN_RATE / (1.0 + cooldown_strength)


func get_barrel_position() -> Vector2:
	return Vector2(position.x, position.y + _cached_shape.get_rect().position.y)


func _ready() -> void:
	_cached_shape = ConvexPolygonShape2D.new()
	_cached_shape.set_point_cloud(%CollisionPolygon2D.polygon)


func is_shielded() -> bool:
	return _active_shield > 0


func get_shield_y() -> float:
	return %Shield.position.y - %Shield.texture.size().y / 2


func _process(delta: float) -> void:
	delta *= _board.get_time_dilation()
	_gun_cooldown -= delta
	if _active_shield > 0:
		var last_phase: int = int(round(_active_shield * 7.0 / _shield_duration))
		_active_shield -= delta
		var current_phase: int = int(round(_active_shield * 7.0 / _shield_duration))
		if last_phase != current_phase:
			var tween: Tween = create_tween()
			if current_phase % 2 == 0:
				tween.tween_property(%Shield, "modulate:a", 0.3, _shield_duration / 7.0)
			else:
				tween.tween_property(%Shield, "modulate:a", 1.0, _shield_duration / 7.0)
		if _active_shield <= 0:
			%Shield.hide()
	
	if _state != PlayerState.ACTIVE:
		return
	
	var old_direction_vector: Vector2 = _direction_vector
	if Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			_direction_vector = Vector2.ZERO
			_speed = 0.0
		else:
			var right: float = Input.get_action_strength("move_right")
			_direction_vector = Vector2.RIGHT * right if position.x < _max_x else Vector2.ZERO
	elif Input.is_action_pressed("move_left"):
		var left: float = Input.get_action_strength("move_left")
		_direction_vector = Vector2.LEFT * left if position.x > _min_x else Vector2.ZERO
	else:
		_direction_vector = Vector2.ZERO
		_speed = 0.0
	if old_direction_vector.x * _direction_vector.x < 0:
		_speed = 0.0
	if Input.is_action_pressed("fire"):
		_attempt_fire()


func _attempt_fire() -> void:
	if _gun_cooldown > 0:
		return
	_gun_cooldown = _gun_cooldown_rate
	_board.spawn_player_bullet(position)


func _on_hit_by_alien_bullet(_bullet: AlienBullet) -> void:
	if _active_shield > 0:
		return
	_die()


func _on_hit_by_alien_ship(_alien: AlienShip) -> void:
	if _active_shield > 0:
		return
	_die()


func _on_hit_by_ground_flames(_ground_flames: GroundFlames) -> void:
	_ground_flames.extinguish()
	if _active_shield > 0:
		return
	_die()


func _die() -> void:
	if _state != PlayerState.ACTIVE:
		return
	_direction_vector = Vector2.ZERO
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
	if _shield_duration > 0:
		_active_shield = _shield_duration
		%Shield.show()
		%Shield.modulate.a = 1.0


func _on_audio_stream_finished() -> void:
	if _state == PlayerState.RESPAWNING:
		$AudioStreamPlayer2D.play()


func _physics_process(delta: float) -> void:
	delta *= _board.get_time_dilation()
	if _use_acceleration:
		_speed = move_toward(_speed, SPEED, 2.0 * SPEED * delta)
	else: 
		_speed = SPEED
	var velocity: Vector2 = _direction_vector * _speed * delta
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
				elif hit_object is GroundFlames:
					_on_hit_by_ground_flames(hit_object as GroundFlames)
	
	position += velocity
