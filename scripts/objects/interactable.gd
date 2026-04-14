extends Area3D
class_name Interactable

@export var pick3d: bool = false
@export var sounds: AudioStream = preload("res://sounds/sfx/freesoundsxx-object-fall-soft-275694_pPIA9oEB.mp3")
@export_range(0.1, 5.0) var velocity_threshold: float = 0.5 # Min speed to play sound
@export_range(0.1, 10.0) var force_scalar: float = 1.0     # Adjust volume sensitivity
@export var max_sound_distance: float = 20

var rigid_body: RigidBody3D = null
var sfx_player: AudioStreamPlayer3D = null

func _ready():
	if owner is RigidBody3D:
		rigid_body = owner

		sfx_player = AudioStreamPlayer3D.new()
		sfx_player.stream = sounds
		sfx_player.bus = "SFX"
		sfx_player.max_distance = max_sound_distance
		rigid_body.add_child.call_deferred(sfx_player)

		rigid_body.contact_monitor = true
		rigid_body.max_contacts_reported = 3

		rigid_body.body_entered.connect(_on_body_entered)

func interact():
	pass

func _on_body_entered(body: Node):
	if not sounds:
		return

	# Calculate impact intensity based on current velocity
	var impact_velocity = rigid_body.linear_velocity.length()

	if impact_velocity > velocity_threshold:
		# Map velocity to decibels.
		# We use linear_to_db so the volume scaling feels natural to the ear.
		var volume_linear = clamp(impact_velocity * 0.1 * force_scalar, 0.0, 2.0)
		sfx_player.volume_db = linear_to_db(volume_linear)

		# Pitch variation makes it feel less repetitive
		sfx_player.pitch_scale = randf_range(0.9, 1.1)

		sfx_player.play()
