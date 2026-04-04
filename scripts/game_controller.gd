extends Node


func load_scene(scene_path):
	get_tree().change_scene_to_file(scene_path)
