# (Autoload)
extends Node

var floating_dialogue_prefab = preload("res://scenes/visuals/floating_dialogue.tscn")
var floating_dialogue_offset:Vector3 = Vector3(-0.7,0.4,-0.7)

var active_npc: NPCInteraction = null
var dialogue_index: int = -1
var is_open: bool = false


signal dialogue_started(npc)
signal dialogue_ended(npc)

func proceed_dialogue(npc: NPCInteraction):
	if npc != active_npc:
		if is_open and active_npc != null:
			_close_dialogue(false)
		active_npc=npc
		active_npc.npc_character.to_state(NPC.State.TALKING)
		dialogue_index = npc.get_start_index()
		is_open = true
		dialogue_started.emit(npc)
		advance()
	else:
		advance()


func show_line():
	spawn_text(active_npc.dialogues[dialogue_index])


	# DialogueUI.show(active_npc.dialogues[dialogue_index])

func advance():
	dialogue_index += 1
	if dialogue_index >= active_npc.dialogues.size():
		end_dialogue()
		return
	show_line()

func end_dialogue():
	if not is_open:
		return
	_close_dialogue(false)

func _close_dialogue(save:bool):

	var existing_dialogue:Label3D = active_npc.npc_character.find_child(active_npc.npc_character.name + "_dialogue",false,false)
	if existing_dialogue:
		existing_dialogue.queue_free()

	active_npc.save_progress(dialogue_index if save else -1)  # remember where we stopped
	dialogue_ended.emit(active_npc)
	active_npc = null
	is_open = false
	# DialogueUI.hide()

func spawn_text(text:String):
	var node_name = active_npc.npc_character.name + "_dialogue"

	var existing_dialogue:Label3D = active_npc.npc_character.find_child(node_name,false,false)
	# reuse old dialogue
	if existing_dialogue:
		existing_dialogue.text = text
	else:
		var mid_point := (GameController.player.global_position + active_npc.global_position) / 2.0

		# Offset relative to camera's orientation
		var camera := get_viewport().get_camera_3d()
		var world_offset := camera.global_basis * floating_dialogue_offset
		mid_point += world_offset

		var new_dialogue = floating_dialogue_prefab.instantiate() as Label3D
		new_dialogue.name = node_name
		new_dialogue.text = text
		new_dialogue.position = mid_point
		active_npc.npc_character.add_child(new_dialogue)
