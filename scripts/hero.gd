extends Interactable

func interact():
	print("hero")
	AchievementManager.unlock_achievement("be_a_hero")