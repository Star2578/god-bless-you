extends Node

var explosion_vfx: PackedScene = preload("res://vfx/explosion_1.tscn")
var player: PlayerCharacter

# Game state
enum GameState {MAIN_MENU,OPTION,INGAME_OPTION,GAME, END_CREDIT}

var game_state:GameState = GameState.MAIN_MENU

signal state_changed(from: GameState, to: GameState)

func load_scene(scene_path):
	get_tree().change_scene_to_file(scene_path)

func init_explosion_vfx(parent: Node, g_pos: Vector3):
	# print("init explosion:", parent)
	var ex = explosion_vfx.instantiate()

	parent.add_child(ex)
	ex.global_position = g_pos

func to_state(state:GameState):
	if self.game_state == GameState.MAIN_MENU:
		if state == GameState.GAME:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			GameController.load_scene("res://scenes/game/class_room_build.tscn")

	if self.game_state == GameState.GAME:
		if state == GameState.INGAME_OPTION:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			set_pause_game(true)

	if self.game_state == GameState.INGAME_OPTION:
		if state == GameState.MAIN_MENU:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			set_pause_game(false)
			GameController.load_scene("res://scenes/game/main_menu.tscn")
		if state == GameState.GAME:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			set_pause_game(false)

	state_changed.emit(self.game_state,state)
	self.game_state = state

func set_pause_game(b:bool):
	get_tree().paused = b
