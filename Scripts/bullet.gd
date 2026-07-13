class_name Bullet extends AnimatableBody2D


func die_against_bunker(_bunker: Bunker, _hit_offset: Vector2) -> void:
	assert(false, "MUST IMPLEMENT")


func die_against_alien(_alien: AlienShip, _hit_offset: Vector2) -> void:
	assert(false, "MUST IMPLEMENT")
