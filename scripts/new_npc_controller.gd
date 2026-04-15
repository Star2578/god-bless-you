extends CharacterBody3D
class_name NPC

@export_group("NPC Parameters")
@export var npc_name:String = "PLACEHOLDER_NAME"
@export var hp:int = 3 # -1 for every collapse
@export var move_speed: float = 2.0
@export var recovery_delay:float = 4.0 # time it take for npc to get up from unconscious state
@export var angular_speed:float = 4.0


@export_group("NPC pathfindings")
@export var roaming_enabled:bool = false
@export var roaming_paths:Node3D
@export var idle_interval:float = 2.0 # time before start roaming again after reach target path
@export var walk_random: bool = false


@export_group("Animation")
@export var animation_tree:AnimationTree
@export var idle_walk_multiplier:float = 1.0


@export_group("Ragdoll")
@export var ragdoll_skeleton:Skeleton3D
@export var animated_skeleton:Skeleton3D
@export var character_collision:CollisionShape3D
@export var collision_min_impact:float = 2.0 # minimum impact for npc to activate ragdoll
@export var impact_force:float = 100.0 # minimum impact for npc to activate ragdoll


enum State { IDLE, START_ROAMING, ROAMING, UNCONSCIOUS ,LAY_DOWN, STANDING_UP,TALKING , TURNING , DEAD }
var state := State.IDLE
var prev_state:NPC.State

# path finding
@onready var nav_agent_3d : NavigationAgent3D = $NavigationAgent3D
var _idle_timer:float
var current_target_idx:int = -1
var next_target_position: Vector3
var frame_since_path_calc:int = 0

# animation
var last_facing_direction:Vector2

# ragdoll
var physics_bones:Array
var physical_bone_sim:PhysicalBoneSimulator3D
var hip_bone:PhysicalBone3D
var _teleport_pending: bool = false
var _pending_ragdoll_position: Vector3

var stuck_timer:float = 0.0
const stuck_limit:float = 5.0
var prev_position:Vector3

var recovery_timer:float = 0.0


var turn_stuck:float = 0.0
const turn_limit:float =5

func _ready() -> void:
	for child in ragdoll_skeleton.get_children():
		if child is PhysicalBoneSimulator3D:
			physical_bone_sim = child
	physics_bones = physical_bone_sim.get_children().filter(
		func(x): return x is PhysicalBone3D
	)
	for b:PhysicalBone3D in physics_bones:
		b.add_collision_exception_with(self)
		(b.get_child(0) as CollisionShape3D).disabled = true
		if "hips" in b.name.to_lower():
			hip_bone = b

func _process(delta: float) -> void:
	# print(State.keys()[self.state])
	match self.state:
		NPC.State.IDLE:
			_idle_timer += delta
			if _idle_timer >= self.idle_interval and roaming_paths != null  and len(roaming_paths.get_children()) > 1 and self.roaming_enabled:
				_idle_timer = 0.0
				state = NPC.State.START_ROAMING

		NPC.State.START_ROAMING:
			# Pick a random target different from the current one

			if walk_random:
				var rand_path_idx := randi_range(0, len(roaming_paths.get_children())-1)
				while rand_path_idx == current_target_idx:
					rand_path_idx = randi_range(0, len(roaming_paths.get_children())-1)
				current_target_idx = rand_path_idx
			else:
				current_target_idx = (current_target_idx+1) % roaming_paths.get_child_count()
			nav_agent_3d.target_position = roaming_paths.get_children()[current_target_idx].global_position
			to_state(NPC.State.TURNING)

		NPC.State.ROAMING:
			if frame_since_path_calc >= 5:
				var next_next_target_position:= nav_agent_3d.get_next_path_position()

				if global_position.distance_to(prev_position) < 0.01:
					stuck_timer += delta*10
				if stuck_timer >= stuck_limit:
					var all_path:= nav_agent_3d.get_current_navigation_path()
					var current_path_idx = nav_agent_3d.get_current_navigation_path_index()
					if len(all_path) > current_path_idx+1:
						self.global_position = all_path[current_path_idx+1]
					stuck_timer = 0


				next_target_position = next_next_target_position
				frame_since_path_calc = 0
			else:
				frame_since_path_calc +=1

		NPC.State.TURNING:
			# change facing direction before move
			turn_stuck += delta
			if stuck_timer >= stuck_limit:
				to_state(NPC.State.IDLE)
				stuck_timer = 0

			var next_pos := nav_agent_3d.get_next_path_position()
			var dir_to_target = (next_pos - self.global_position).normalized()
			var target_angle = Vector2(dir_to_target.z, dir_to_target.x).angle()
			self.rotation.y = rotate_toward(self.rotation.y, target_angle, self.angular_speed * delta)

			var angle_diff = abs(wrapf(target_angle - rotation.y, -PI, PI))

			if angle_diff < 0.01:
				to_state(NPC.State.ROAMING)

		NPC.State.TALKING:
			return
		# When character turn fully ragdoll
		NPC.State.UNCONSCIOUS:
			if hp <= 0:
				to_state( self.State.DEAD)

			recovery_timer -= delta

			if recovery_timer <= 0.0:
				self.velocity = Vector3.ZERO
				sync_ragdoll_position()
				deactivate_ragdoll()
				_resume_after_ragdoll()

		NPC.State.DEAD:
			return

func _physics_process(delta: float) -> void:
	prev_position = global_position

	if self.state == NPC.State.DEAD:
		return

	if self.state == NPC.State.ROAMING:
		add_velocity_toward_next_path()

	if self.state != NPC.State.TALKING and self.velocity != Vector3.ZERO:
		last_facing_direction = Vector2(self.velocity.z,self.velocity.x)
		self.rotation.y = rotate_toward(self.rotation.y,last_facing_direction.angle(),self.angular_speed*delta)
	elif self.state == NPC.State.TALKING:
		var dir_to_player = (GameController.player.global_position - self.global_position).normalized()
		# player camera is +X somehow
		last_facing_direction = Vector2(dir_to_player.z,dir_to_player.x)
		self.rotation.y = rotate_toward(self.rotation.y,last_facing_direction.angle(),self.angular_speed*delta)

	if self._teleport_pending:
		_teleport_pending = false
		global_position = self._pending_ragdoll_position
		velocity = Vector3.ZERO
		return


	if not physical_bone_sim.is_simulating_physics():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# if self.state != NPC.State.TALKING:
		move_and_slide()

		if animation_tree:
			var current_speed = max(0.6 if self.state== State.ROAMING else 0.0 ,velocity.length() * idle_walk_multiplier)
			animation_tree.set("parameters/IdleWalking/blend_position", current_speed)

func add_velocity_toward_next_path():
	if nav_agent_3d.is_navigation_finished():
		return
	var pos_diff = self.next_target_position - self.global_position
	var dir = pos_diff.normalized()

	var desired = Vector3(dir.x,0.0,dir.z) * self.move_speed

	nav_agent_3d.velocity = desired

func _on_navigation_agent_3d_link_reached(details: Dictionary) -> void:
	print(details)
	var dir:Vector3 = (details.link_exit_position - details.position).normalized()
	self.velocity.x = dir.x * self.move_speed
	self.velocity.z = dir.z * self.move_speed

func _on_navigation_agent_3d_navigation_finished() -> void:
	self.velocity = Vector3.ZERO
	to_state(State.IDLE)

func to_state(_state:NPC.State):
	if self.state == _state:
		return
	self.prev_state = self.state
	self.state = _state

func _on_navigation_agent_3d_velocity_computed(safe_velocity:Vector3):
	if self.state == NPC.State.TALKING:
		self.velocity = Vector3.ZERO
		return
	self.velocity.x = safe_velocity.x
	self.velocity.z = safe_velocity.z

func activate_ragdoll(revert_pose:bool):
	print("RAGDOLL ACTIVATED")
	if self.physical_bone_sim.is_simulating_physics():
		return

	# start with current animation pose
	if revert_pose:
		for b:PhysicalBone3D in physics_bones:
			(b.get_child(0) as CollisionShape3D).disabled = false
			var b_id := b.get_bone_id()
			var pose := animated_skeleton.get_bone_global_pose(b_id)
			ragdoll_skeleton.set_bone_global_pose(b_id , pose)

	character_collision.disabled = true
	animated_skeleton.visible = false
	ragdoll_skeleton.visible = true
	physical_bone_sim.physical_bones_start_simulation()

func deactivate_ragdoll():
	physical_bone_sim.physical_bones_stop_simulation()
	for b:PhysicalBone3D in physics_bones:
		(b.get_child(0) as CollisionShape3D).disabled = true
	character_collision.disabled = false
	animated_skeleton.visible = true
	ragdoll_skeleton.visible = false

func collapse(force: Vector3):
	if self.state == NPC.State.UNCONSCIOUS or self.state == NPC.State.DEAD:
		return

	self.hp -= 1
	self.recovery_timer = recovery_delay
	activate_ragdoll(true)

	if self.hp <= 0:
		to_state(NPC.State.DEAD)    # go straight to dead
		await get_tree().physics_frame
		hip_bone.apply_central_impulse(force)
		return

	to_state(NPC.State.UNCONSCIOUS)
	await get_tree().physics_frame
	hip_bone.apply_central_impulse(force)

func sync_ragdoll_position():
	# move real node position to current ragdoll position
	var space_state := get_world_3d().direct_space_state
	var raycast_query := PhysicsRayQueryParameters3D.create(hip_bone.global_position + (Vector3.UP * 0.2), hip_bone.global_position + (Vector3.DOWN * 10),1 , [self])
	var floor_collision := space_state.intersect_ray(raycast_query)
	if floor_collision:
		_pending_ragdoll_position  = floor_collision.position + (Vector3.UP * 0.01)
	else:
		_pending_ragdoll_position  = hip_bone.global_position + (Vector3.UP * 0.1)
	_teleport_pending = true

func _resume_after_ragdoll():
	# if had a destination and not reached, re-issue the target
	if roaming_enabled and roaming_paths != null and current_target_idx >= 0:
		var target = roaming_paths.get_children()[current_target_idx]
		nav_agent_3d.target_position = target.global_position   # re-issue same target
		next_target_position = nav_agent_3d.get_next_path_position()
		to_state(NPC.State.TURNING)   # turn toward path before moving
	else:
		to_state(NPC.State.IDLE)
