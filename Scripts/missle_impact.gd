extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	var rnd: RandomNumberGenerator = RandomNumberGenerator.new()
	$AudioStreamPlayer2D.volume_db += (rnd.randf() * 2.0 - 1.0)
	$AudioStreamPlayer2D.pitch_scale *= (.9 + rnd.randf() * .2)
	$AudioStreamPlayer2D.play()

func _on_finished() -> void:
	queue_free()
