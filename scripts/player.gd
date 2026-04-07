extends Node3D

# Drag your sphere.tscn into this export slot in the Inspector
@export var sphere_scene: PackedScene

@export var shoot_speed: float = 30.0

# A spawn point node positioned in front of your character
# (add a Marker3D as a child and place it in front)
@export var camera : Camera3D

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()

func shoot():
	var sphere = sphere_scene.instantiate()

	# Add to the main scene (not as a child of the player)
	get_tree().get_root().add_child(sphere)

	# Position it at the spawn point
	sphere.global_transform = camera.global_transform

	# Launch it forward (negative Z is forward in Godot)
	sphere.linear_velocity = -camera.global_transform.basis.z * shoot_speed
