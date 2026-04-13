extends Area3D

@export var teleport_to: Vector3


func _on_body_entered(body: Node3D):
	if body is PlayerCharacter:
		body.position = teleport_to