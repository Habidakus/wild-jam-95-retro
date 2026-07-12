class_name AlienShip extends Area2D


const WEAPON_COOLDOWN_TIME: float = 4.0


var _can_shoot: bool = false
var _weapon_cooldown: float
var _board: Board


func initialize(board: Board) -> void:
	_board = board


func power_up_weapon(power_up_length: float) -> void:
	_can_shoot = true
	_weapon_cooldown = 1 + WEAPON_COOLDOWN_TIME * power_up_length


func _process(delta: float) -> void:
	if not _can_shoot:
		return
	_weapon_cooldown -= delta * _board.get_time_dilation()
	if _weapon_cooldown > 0:
		return
	_board.spawn_alien_bullet(position)
	_weapon_cooldown = WEAPON_COOLDOWN_TIME
