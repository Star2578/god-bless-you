extends Node3D

@export var move_speed: float = 2.0
@export var idle_wait_time: float = 2.0

enum State { IDLE, START_ROAMING, ROAMING, FALL }
var state = State.IDLE

var path_node: Node3D
var current_target: Marker3D
var _idle_timer: float = 0.0

func _ready() -> void:
	path_node = get_tree().root.find_child("NPCPath", true, false)
func _process(delta: float) -> void:
	# print("Actual Mesh :", self.global_position)
	match state:

		State.IDLE:
			# Count down timer, no await in _process
			_idle_timer += delta
			if _idle_timer >= idle_wait_time:
				_idle_timer = 0.0
				state = State.START_ROAMING

		State.START_ROAMING:
			var child_count = path_node.get_child_count()
			if child_count == 0:
				return
			# Pick a random target different from the current one
			var rand_node: Marker3D = current_target
			while rand_node == current_target:
				rand_node = path_node.get_child(randi_range(0, child_count - 1))
			current_target = rand_node
			state = State.ROAMING

		State.ROAMING:
			if current_target == null:
				state = State.IDLE
				return

			# Move toward target
			var direction: Vector3 = (current_target.global_position - global_position)
			direction.y = 0.0  # keep movement flat, remove if you want vertical too
			var distance: float = direction.length()

			if distance < 0.2:
				state = State.IDLE
			else:
				global_position += direction.normalized() * move_speed * delta

			# Face the direction of movement
			if direction.length_squared() > 0.001:
				var look_target = global_position - direction.normalized()  # note the minus
				look_at(look_target, Vector3.UP)
