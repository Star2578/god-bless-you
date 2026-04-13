extends Area3D

@export var how_long: float = 10
var player_is_in: bool = false

var counter = 0.0

func _physics_process(delta):
	if player_is_in:
		counter += delta
	else:
		counter = 0
	
	if counter >= how_long:
		print("PLAYER STUCK HAHA")
		AchievementManager.unlock_achievement("im_stuck")
		counter = 0

func _on_player_entered(body: Node3D):
	print(body, " stuck")
	if body is PlayerCharacter:
		player_is_in = true

func _on_player_exited(body: Node3D):
	print(body, " unstuck")
	if body is PlayerCharacter:
		player_is_in = false