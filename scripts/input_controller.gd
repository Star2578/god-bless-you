extends Node

func _input(event):
	if event.is_action_pressed("ui_cancel") and event.pressed:
		if GameController.game_state == GameController.GameState.GAME:
			GameController.to_state(GameController.GameState.INGAME_OPTION)
		elif GameController.game_state == GameController.GameState.INGAME_OPTION:
			GameController.to_state(GameController.GameState.GAME)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
