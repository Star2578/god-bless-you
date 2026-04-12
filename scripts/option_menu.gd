extends Control


@export var master_slider :HSlider
@export var sfx_slider :HSlider
@export var bgm_slider :HSlider

@export var master_label :Label
@export var sfx_label :Label
@export var bgm_label :Label

const MASTER_BUS:int = 0
const SFX_BUS:int = 1
const BGM_BUS:int = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))

	GameController.state_changed.connect(_option_menu_event)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_master_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
	master_label.text = "%d %%" % (value*100)

func _on_sfx_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(value))
	sfx_label.text = "%d %%" % (value*100)

func _on_bgm_slider_value_changed(value:float) -> void:
	AudioServer.set_bus_volume_db(BGM_BUS, linear_to_db(value))
	bgm_label.text = "%d %%" % (value*100)

func _on_back_button_pressed() -> void:
	if GameController.game_state == GameController.GameState.INGAME_OPTION:
		GameController.to_state(GameController.GameState.GAME)
	else:
		GameController.to_state(GameController.GameState.MAIN_MENU)

func _option_menu_event(_from: GameController.GameState, to: GameController.GameState):
	visible = (to == GameController.GameState.OPTION or to == GameController.GameState.INGAME_OPTION)
