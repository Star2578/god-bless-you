extends Node

const SAVE_PATH = "user://achievements.cfg"
var config = ConfigFile.new()

# Our dictionary of achievements: { "id": is_unlocked }
var achievements = {
	"beware_explosive": false,
	"trapped_in_the_void": false,
	"be_a_hero": false,
	"the_truth_of_this_world": false,
}

func _ready():
	load_achievements()

func unlock_achievement(id: String):
	if achievements.has(id) and not achievements[id]:
		achievements[id] = true
		save_achievements()
		print("Achievement Unlocked: ", id)
		# Signal to trigger a UI popup
		emit_signal("achievement_unlocked", id)

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
	config.clear()
	load_achievements()

func is_unlocked(id: String) -> bool:
	return achievements[id]