extends Node3D

@export var particle: GPUParticles3D

func _on_particle_finished():
	queue_free()


func _on_particle_tree_entered():
	particle.emitting = true
