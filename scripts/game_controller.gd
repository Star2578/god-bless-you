extends Node

var explosion_vfx: PackedScene = preload("res://vfx/explosion_1.tscn")

func load_scene(scene_path):
	get_tree().change_scene_to_file(scene_path)

func init_explosion_vfx(parent: Node, g_pos: Vector3):
	print("init explosion:", parent)
	var ex = explosion_vfx.instantiate()

	parent.add_child(ex)
	ex.global_position = g_pos