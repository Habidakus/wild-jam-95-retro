class_name AlienShip extends Area2D


const EXPLOSION_SCENE: Resource = preload("res://Scenes/alien_ship_explosion.tscn")
const SHIELD_NEG: Texture = preload("res://Images/Shield_Neg.png")
const SHIELD_POS: Texture = preload("res://Images/Shield_Pos.png")
const WEAPON_COOLDOWN_TIME: float = 4.0


enum ShipType {
	Regular,
	Acid,
	Thin,
	Shield,
	RapidFire,
}


static func get_strength(ship_type: ShipType) -> float:
	match ship_type:
		ShipType.Regular:
			return 1.0
		ShipType.Acid:
			return 1.5
		ShipType.Thin:
			return 1.25
		ShipType.Shield:
			return 1.8
		ShipType.RapidFire:
			return 1.65
		_:
			assert(false)
			return 1.0


var _can_shoot: bool = false
var _weapon_cooldown: float
var _board: Board
var _col: int
var _row: int
var _is_dead: bool = false
var _acid: bool = false
var _body_color: Color = Color.WHITE
var _animation_set: String = "Regular"
var _ship_mass: int = 250
var _has_shield: bool = false
var _loaded_shield: int = 0
var _weapon_speed_multiple: float = 1.0


func _ready() -> void:
	$AnimatedSprite2D.play(_animation_set)
	$Shield.modulate.a = 0.0


func initialize(board: Board, col: int, row: int, ship_type: ShipType) -> void:
	_board = board
	_col = col
	_row = row
	match ship_type:
		ShipType.Regular:
			if col == 0 or col == 10:
				_animation_set = "Hat"
			elif col % 2 == 0:
				_animation_set = "Waggle"
			pass
		ShipType.Acid:
			_acid = true
			_body_color = Color(0x50c878ff)
		ShipType.Thin:
			_animation_set = "Thin"
			$CollisionShape2D.scale = Vector2(0.36, 1.0)
		ShipType.Shield:
			_animation_set = "Shield"
			_ship_mass = 500
			_body_color = Color(0x5064c8ff)
			_has_shield = true
		ShipType.RapidFire:
			_animation_set = "RapidFire"
			_weapon_speed_multiple = 0.33
	$AnimatedSprite2D.material.set_shader_parameter("target_color", _body_color)


func has_shield() -> bool:
	return _has_shield


func get_col() -> int:
	return _col


func get_row() -> int:
	return _row


func get_impact_damage() -> int:
	return _ship_mass


func power_up_weapon(power_up_length: float) -> void:
	_can_shoot = true
	_weapon_cooldown = (1 + WEAPON_COOLDOWN_TIME * power_up_length) * _weapon_speed_multiple


func on_particle_beam_impact(_particle_beam_x: float) -> float:
	if is_dead():
		return -1
	var shield_dir: int = _board.get_ship_shielded_dir(self)
	if shield_dir != 0:
		var shield_y: float = _spawn_shield(shield_dir)
		return shield_y
	die()
	return -1


func on_bullet_impact(bullet: Bullet, point: Vector2, _velocity: Vector2) -> void:
	if is_dead():
		return
	if bullet.is_dead():
		return
	var shield_dir: int = _board.get_ship_shielded_dir(self)
	if shield_dir != 0:
		var shield_y: float = _spawn_shield(shield_dir)
		bullet.die_against_alien_bullet(Vector2(bullet.position.x, shield_y))
		return
	bullet.die_against_alien(self, point)
	die()


func _spawn_shield(dir: int) -> float:
	if dir != _loaded_shield:
		_loaded_shield = dir
		if dir < 0:
			$Shield.texture = SHIELD_NEG
			$Shield.position.x = -4
		else:
			$Shield.texture = SHIELD_POS
			$Shield.position.x = 4
	$Shield.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property($Shield, "modulate:a", 0.0, 0.5)
	return $Shield.texture.get_size().y / 2 + position.y


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


func _get_weapon_cooldown_time() -> float:
	if _acid:
		return WEAPON_COOLDOWN_TIME * 4.0
	else:
		return WEAPON_COOLDOWN_TIME * _weapon_speed_multiple


func _process(delta: float) -> void:
	var time_dilation: float = _board.get_time_dilation()
	$AnimatedSprite2D.speed_scale = time_dilation
	if not _can_shoot:
		return
	_weapon_cooldown -= delta * time_dilation
	if _weapon_cooldown > 0:
		return
	_board.spawn_alien_bullet(position, _acid)
	_weapon_cooldown = _get_weapon_cooldown_time()


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
