extends Control


func _on_start_pressed():
	GameController.load_scene("res://scenes/game/game.tscn")

func _on_exit_pressed():
	get_tree().quit()