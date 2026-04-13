extends Area3D

@export var teleport_to: Vector3
@export var scene: String
@export var achievement: bool

func _on_body_entered(body: Node3D):
	if body is PlayerCharacter:
		if scene:
			GameController.load_scene(scene)
		
		if achievement:
			AchievementManager.unlock_achievement("the_truth_of_this_world")

		body.global_position = teleport_to