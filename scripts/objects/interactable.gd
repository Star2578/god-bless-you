extends Area3D
class_name Interactable

var pick3d: bool = false
var rigid_body: RigidBody3D = null

func _ready():
	rigid_body = get_parent().find_child("RigidBody3D")
	
	if rigid_body:
		pick3d = true

func interact():
	pass
