extends TextureRect

var speed = 2
var noise : NoiseTexture2D


func _ready():
	noise = texture as NoiseTexture2D


func _physics_process(delta: float):
	noise.noise.offset += Vector3(-speed * delta, speed * delta , 0)