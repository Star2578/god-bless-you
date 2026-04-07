extends Skeleton3D

@export var target_skeleton:Skeleton3D

@export var linear_spring_stiffness:float = 1200.0
@export var linear_spring_damping:float = 40.0

@export var angular_spring_stiffness:float = 4000.0
@export var angular_spring_damping:float = 80.0

var physics_bones

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
