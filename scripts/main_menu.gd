extends Control

@onready var badge_1 = %Badge1
@onready var badge_2 = %Badge2
@onready var badge_3 = %Badge3
@onready var badge_4 = %Badge4

func _ready():
	update_badges()

func update_badges():
	badge_1.modulate = Color(0,0,0,1) if not AchievementManager.is_unlocked("beware_explosive") else Color(1,1,1,1)
	badge_2.modulate = Color(0,0,0,1) if not AchievementManager.is_unlocked("trapped_in_the_void") else Color(1,1,1,1)
	badge_3.modulate = Color(0,0,0,1) if not AchievementManager.is_unlocked("be_a_hero") else Color(1,1,1,1)
	badge_4.modulate = Color(0,0,0,1) if not AchievementManager.is_unlocked("the_truth_of_this_world") else Color(1,1,1,1)

func _on_start_pressed():
	# GameController.load_scene("res://scenes/game/game.tscn")
	GameController.load_scene("res://scenes/game/class_room_build.tscn")

func _on_option_pressed():
	pass

func _on_exit_pressed():
	get_tree().quit()

func _on_reset_pressed():
	AchievementManager.reset_achievements()
	update_badges()