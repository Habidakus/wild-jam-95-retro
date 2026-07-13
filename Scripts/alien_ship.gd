class_name AlienShip extends Area2D


const EXPLOSION_SCENE: Resource = preload("res://Scenes/alien_ship_explosion.tscn")
const WEAPON_COOLDOWN_TIME: float = 4.0


var _can_shoot: bool = false
var _weapon_cooldown: float
var _board: Board
var _col: int


func initialize(board: Board, col: int) -> void:
	_board = board
	_col = col


func get_col() -> int:
	return _col


func power_up_weapon(power_up_length: float) -> void:
	_can_shoot = true
	_weapon_cooldown = 1 + WEAPON_COOLDOWN_TIME * power_up_length


func on_bullet_impact(bullet: Bullet, point: Vector2, _velocity: Vector2) -> void:
	bullet.die_against_alien(self, point)
	die()


func die() -> void:
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
	if not _can_shoot:
		return
	_weapon_cooldown -= delta * _board.get_time_dilation()
	if _weapon_cooldown > 0:
		return
	_board.spawn_alien_bullet(position)
	_weapon_cooldown = WEAPON_COOLDOWN_TIME
