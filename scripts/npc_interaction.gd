extends Interactable

class_name NPCInteraction

@export var npc_character:NPC
@export var dialogues:Array[String]
@export var dialogue_range:float

var dialogue_idx = -1
var saved_idx:int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact():
	if dialogues and self.npc_character.state != NPC.State.DEAD:
		DialogueManager.proceed_dialogue(self)

func save_progress(index:int):
	self.saved_idx = index
	stop_conversation()

func get_start_index() -> int:
	return self.saved_idx  # resume where they left off

func stop_conversation():
	var _prev:= npc_character.prev_state
	npc_character.to_state(_prev)
