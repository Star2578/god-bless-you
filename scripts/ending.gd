extends Control


@onready var title: Label = %Title
@onready var text: Label = %Text

func _ready():
	title.text = AchievementManager.ending_title
	text.text = AchievementManager.ending_text

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_mainmenu_pressed():
	get_tree().change_scene_to_file("res://scenes/game/main_menu.tscn")
	GameController.to_state(GameController.GameState.MAIN_MENU)