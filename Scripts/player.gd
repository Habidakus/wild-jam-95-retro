class_name Player extends Area2D

const SPEED: float = 400

var _board: Board
var _direction_vector: Vector2 = Vector2.ZERO
var _cached_shape: ConvexPolygonShape2D
var _min_x: float
var _max_x: float


func initialize(board: Board) -> void:
	_board = board
	_min_x = 27 * 3 / 4.0
	_max_x = board.size.x - _min_x


func _ready() -> void:
	_cached_shape = ConvexPolygonShape2D.new()
	_cached_shape.points = %CollisionPolygon2D.polygon


func _process(_delta: float) -> void:
	if Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			_direction_vector = Vector2.ZERO
		else:
			_direction_vector = Vector2.RIGHT if position.x < _max_x else Vector2.ZERO
	elif Input.is_action_pressed("move_left"):
		_direction_vector = Vector2.LEFT if position.x > _min_x else Vector2.ZERO
	else:
		_direction_vector = Vector2.ZERO


func _physics_process(delta: float) -> void:
	var velocity: Vector2 = _direction_vector * SPEED * delta * _board.get_time_dilation()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _cached_shape
	query.transform = global_transform.translated(velocity)
	query.collision_mask = collision_mask
	query.exclude = [self.get_rid()]

	var results: Array[Dictionary] = space_state.intersect_shape(query)
	if not results.is_empty():
		var rest_info = space_state.get_rest_info(query)
		if not rest_info.is_empty():
			for collision_data: Dictionary in results:
				var hit_object = collision_data.collider
				print("Player collided with %s" % [hit_object])
	
	position += velocity
