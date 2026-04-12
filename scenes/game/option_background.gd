extends TextureRect

var speed = 2
var noise : NoiseTexture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise = texture as NoiseTexture2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	noise.noise.offset += Vector3(-speed * delta, speed * delta , 0)