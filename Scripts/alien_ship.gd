class_name AlienShip extends Area2D


const EXPLOSION_SCENE: Resource = preload("res://Scenes/alien_ship_explosion.tscn")
const WEAPON_COOLDOWN_TIME: float = 4.0


var _can_shoot: bool = false
var _weapon_cooldown: float
var _board: Board
var _col: int
var _is_dead: bool = false


func initialize(board: Board, col: int) -> void:
	_board = board
	_col = col


func get_col() -> int:
	return _col


func get_impact_damage() -> int:
	return 250


func power_up_weapon(power_up_length: float) -> void:
	_can_shoot = true
	_weapon_cooldown = 1 + WEAPON_COOLDOWN_TIME * power_up_length


func on_bullet_impact(bullet: Bullet, point: Vector2, _velocity: Vector2) -> void:
	if bullet.is_dead():
		return
	bullet.die_against_alien(self, point)
	die()


func is_dead() -> bool:
	return _is_dead


func die() -> void:
	assert(_is_dead == false)
	_is_dead = true
	#_board.start_time_dilation(0.05)
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	explosion.position = position
	explosion.seed = randi()
	explosion.spread = 80 + randf() * 40
	match _board._alien_dir:
		Board.AlienMovement.DOWN:
			explosion.direction = Vector2.DOWN
		Board.AlienMovement.RIGHT:
			explosion.direction = Vector2.RIGHT
		Board.AlienMovement.LEFT:
			explosion.direction = Vector2.LEFT
	_board.add_child(explosion)
	_board.on_alien_died(self)
	queue_free()


func _process(delta: float) -> void:
	var time_dilation: float = _board.get_time_dilation()
	$AnimatedSprite2D.speed_scale = time_dilation
	if not _can_shoot:
		return
	_weapon_cooldown -= delta * time_dilation
	if _weapon_cooldown > 0:
		return
	_board.spawn_alien_bullet(position)
	_weapon_cooldown = WEAPON_COOLDOWN_TIME


func _physics_process(_delta: float) -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = global_transform
	query.collision_mask = collision_mask
	#query.collide_with_areas = true
	query.exclude = [self.get_rid()]

	var results: Array[Dictionary] = space_state.intersect_shape(query)
	if not results.is_empty():
		var rest_info = space_state.get_rest_info(query)
		if not rest_info.is_empty():
			for collision_data: Dictionary in results:
				var hit_object = collision_data.collider
				if hit_object.has_method("on_ship_impact"):
					hit_object.on_ship_impact(self)
				else:
					print("Space ship impact against %s, which does not have on_ship_impact() function" % [hit_object])
