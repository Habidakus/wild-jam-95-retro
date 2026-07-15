class_name PlayState extends StateMachineState


const BOARD_SCENE = preload("res://Scenes/board.tscn")


func enter_state() -> void:
	super.enter_state()
	var root: Window = get_tree().root
	var current_scene: Node = get_tree().current_scene
	assert(current_scene is StateMachine)
	var board_scene: Board = BOARD_SCENE.instantiate()
	board_scene.register_menu_scene(current_scene as StateMachine)
	root.add_child(board_scene)
	get_tree().current_scene = board_scene
	root.remove_child(current_scene)
