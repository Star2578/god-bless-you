extends RigidBody3D
class_name Explosive

@export var explosion_radius: float = 3
@export var explosion_force: float = 10

@export var query_area: Area3D
@export var collider: CollisionShape3D

var was_thrown: bool = false

func _ready():
	collider.shape.radius = explosion_radius

func explode():
	print("EXPLODE!")

	AchievementManager.unlock_achievement("beware_explosive")
	
	var bodies = query_area.get_overlapping_bodies()
	
	for body in bodies:
		if body is RigidBody3D:
			var direction = body.global_transform.origin - global_transform.origin
			var distance = direction.length()
			
			if distance == 0: continue # Prevent division by zero
			
			var push_vector = direction.normalized()
			
			var falloff = (explosion_radius - distance) / explosion_radius
			falloff = clamp(falloff, 0, 1)
			
			var final_force = push_vector * explosion_force * falloff
			body.apply_central_impulse(final_force)

	GameController.init_explosion_vfx(get_parent(), global_position)
	queue_free()

func _on_body_entered(body: Node):
	if not was_thrown:
		return
	
	if not body.is_in_group("Particle"):
		explode()
