class_name GroundFlames extends Area2D


const FLAME_DURATION: float = 6.0


func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(FLAME_DURATION / 2.0)
	tween.tween_property($ShrinkControl, "scale", Vector2(1, 0.333), FLAME_DURATION / 2.0)
	tween.tween_callback(Callable(self, "extinguish"))
	add_to_group("bullet")


func extinguish() -> void:
	queue_free()


#func _physics_process(_delta: float) -> void:
	#var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	#var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	#query.shape = $CollisionShape2D.shape
	#query.transform = global_transform
	#query.collision_mask = collision_mask
	#query.collide_with_areas = true
	#query.exclude = [self.get_rid()]
#
	#var results: Array[Dictionary] = space_state.intersect_shape(query)
	#if not results.is_empty():
		#var rest_info = space_state.get_rest_info(query)
		#if not rest_info.is_empty():
			#for collision_data: Dictionary in results:
				#var hit_object = collision_data.collider
				#if hit_object.has_method("on_flame_impact"):
					#hit_object.on_flame_impact(self)
				#else:
					#print("Space ship impact against %s, which does not have on_ship_impact() function" % [hit_object])
