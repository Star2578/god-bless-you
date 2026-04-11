extends Area3D
class_name Interactable

@export var pick3d: bool = false
var rigid_body: RigidBody3D = null

func _ready():
	if owner is RigidBody3D:
		rigid_body = owner

func interact():
	pass
