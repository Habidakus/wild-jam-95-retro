extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true

func _on_finished() -> void:
	queue_free()
