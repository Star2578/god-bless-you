extends Interactable


func interact():
	print("sleep")
	AchievementManager.unlock_achievement("the_truth_of_this_world")
