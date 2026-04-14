extends Node

const SAVE_PATH = "user://achievements.cfg"
var config = ConfigFile.new()

# Our dictionary of achievements: { "id": is_unlocked }
var achievements = {
	"beware_explosive": false,
	"trapped_in_the_void": false,
	"be_a_hero": false,
	"the_truth_of_this_world": false,
	"im_stuck": false,
}

var ending_title: String
var ending_text: String

func _ready():
	load_achievements()

func unlock_achievement(id: String):
	if achievements.has(id) and not achievements[id]:
		achievements[id] = true
		save_achievements()
		print("Achievement Unlocked: ", id)
		
		if id == "trapped_in_the_void":
			ending_title = "Trapped in The Void"
			ending_text = "Being Invincible doesn't stop you from existing in the void. Alone. For all eternity"
			get_tree().change_scene_to_file("res://scenes/game/ending.tscn")
		elif id == "be_a_hero":
			ending_title = "Be a Hero"
			ending_text = "You choose to not question anything and becomes a hero. And for real this time, you are [TITLE CARD]"
			get_tree().change_scene_to_file("res://scenes/game/ending.tscn")
		elif id == "im_stuck":
			ending_title = "Stuck..."
			ending_text = "Eventhough you are invincible, you somehow cannot unstuck yourself from the locker"
			get_tree().change_scene_to_file("res://scenes/game/ending.tscn")
		elif id == "the_truth_of_this_world":
			ending_title = "???"
			ending_text = "All of this is a [REDACTED]. Until next time."
			get_tree().change_scene_to_file("res://scenes/game/ending.tscn")


func save_achievements():
	for id in achievements.keys():
		config.set_value("unlocks", id, achievements[id])
	config.save(SAVE_PATH)

func load_achievements():
	var err = config.load(SAVE_PATH)
	if err == OK:
		for id in achievements.keys():
			achievements[id] = config.get_value("unlocks", id, false)
	
	print(achievements)

func reset_achievements():
	for id in achievements.keys():
		achievements[id] = false
	
	save_achievements()
	
	config.clear() 
	
	print("Achievements have been reset!")

func is_unlocked(id: String) -> bool:
	return achievements[id]