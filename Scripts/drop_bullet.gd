class_name DropBullet extends AlienBullet


const GROUND_FLAME: Resource = preload("res://Scenes/ground_flames.tscn")


func _create_explosion_vfx() -> CPUParticles2D:
	var explosion: CPUParticles2D = EXPLOSION_SCENE.instantiate()
	return explosion


func _check_against_floor() -> void:
	if position.y >= _floor:
		queue_free()
		var ground_flame: GroundFlames = GROUND_FLAME.instantiate()
		_board.add_child(ground_flame)
		ground_flame.position = Vector2(position.x, _floor)


func _set_floor() -> void:
	_floor = _board.get_player_floor()
