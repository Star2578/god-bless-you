extends CharacterBody3D
class_name NPC

@export_group("NPC Parameters")
@export var npc_name:String = "PLACEHOLDER_NAME"
@export var hp:int = 10
@export var move_speed: float = 2.0
@export var recovery_delay:float = 4.0 # time it take for npc to get up from unconscious state
@export var angular_speed:float = 4.0

@export_group("NPC pathfindings")
@export var roaming_paths:Node3D
@export var idle_interval:float = 2.0 # time before start roaming again after reach target path

@export_group("Animation")
@export var animation_tree:AnimationTree
@export var idle_walk_multiplier:float = 1.0


enum State { IDLE, START_ROAMING, ROAMING, UNCONSCIOUS ,LAY_DOWN, STANDING_UP,TALKING }
var state = State.IDLE
var prev_state:NPC.State

# path finding
@onready var nav_agent_3d : NavigationAgent3D = $NavigationAgent3D
var _idle_timer:float
var current_target:Marker3D
var next_target_position: Vector3
var frame_since_path_calc:int = 0

# animation

var recovery_timer:float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# print(State.keys()[self.state])

	match self.state:
		NPC.State.IDLE:
			_idle_timer += delta
			if _idle_timer >= self.idle_interval and roaming_paths != null  and len(roaming_paths.get_children()) > 1:
				_idle_timer = 0.0
				state = NPC.State.START_ROAMING

		NPC.State.START_ROAMING:
			# Pick a random target different from the current one
			var rand_path: Marker3D = roaming_paths.get_children()[randi_range(0, len(roaming_paths.get_children())-1)]
			while rand_path == current_target:
				rand_path = roaming_paths.get_children()[randi_range(0, len(roaming_paths.get_children())-1)]
			current_target = rand_path
			nav_agent_3d.target_position = current_target.global_position

			state = NPC.State.ROAMING

		NPC.State.ROAMING:
			if frame_since_path_calc >= 1:
				next_target_position = nav_agent_3d.get_next_path_position()
				frame_since_path_calc = 0
			else:
				frame_since_path_calc +=1

		NPC.State.TALKING:
			pass

		# When character turn fully ragdoll
		NPC.State.UNCONSCIOUS:
			recovery_timer -= delta

			if recovery_timer <= 0.0:
				self.velocity = Vector3.ZERO
				self.state = NPC.State.STANDING_UP

				# physics_skeleton.physical_bones_stop_simulation()
				# deactivate_ragdoll()
				# sync_ragdoll_position()
				# physics_skeleton.skeleton_updated.connect(_on_skeleton_updated)
				# physics_skeleton.physical_bones_start_simulation()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	add_velocity_toward_next_path()

	if self.state != State.TALKING:
		self.rotation.y = rotate_toward(self.rotation.y,Vector2(self.velocity.x,-self.velocity.z).angle(),self.angular_speed*delta)
	else:
		var dir_to_player = (GameController.player_character.global_position - self.global_position).normalized()
		self.rotation.y = rotate_toward(self.rotation.y,Vector2(dir_to_player.x,-dir_to_player.z).angle(),self.angular_speed*delta)

	move_and_slide()

	if animation_tree:
		var current_speed = max(0.6 if self.state== State.ROAMING else 0.0 ,velocity.length() * idle_walk_multiplier)
		animation_tree.set("parameters/IdleWalking/blend_position", current_speed)

func add_velocity_toward_next_path():
	if nav_agent_3d.is_navigation_finished():
		return
	var pos_diff = self.next_target_position - self.global_position
	var dir = pos_diff.normalized()

	self.velocity.x = dir.x * self.move_speed
	self.velocity.z = dir.z * self.move_speed

func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	print(details)
	var dir:Vector3 = (details.link_exit_position - details.position).normalized()
	self.velocity.x = dir.x * self.move_speed
	self.velocity.z = dir.z * self.move_speed

func _on_navigation_agent_3d_navigation_finished() -> void:
	self.velocity = Vector3.ZERO
	self.state = State.IDLE

func to_state(_state:NPC.State):
	if self.state == _state:
		return
	self.prev_state = self.state
	self.state = _state
