@tool
extends Node3D
class_name BoneHitboxGenerator


@export var hurtboxes:Array[Area3D]
@export var hitboxes:Array[Area3D]

@export_category("FUNC")
@export var btn_update: bool:
	set(v): generate_from_mesh()

@export var clear: bool:
	set(v): _clear()

@export_enum("Hurtbox", "Hitbox") var Update_Type: String

@export_category("PROPERTY")
@export var skeleton: Skeleton3D
@export var mesh_instance: MeshInstance3D
@export var min_weight: float = 0.25
@export var padding: float = 0.02

func generate_from_mesh():
	print("RUNNING GENERATOR")

	if skeleton == null or mesh_instance == null:
		push_error("Assign Skeleton3D and MeshInstance3D")
		return

	var mesh := mesh_instance.mesh
	if mesh == null:
		push_error("Mesh is null")
		return

	var bone_count := skeleton.get_bone_count()
	var bone_vertices := []
	bone_vertices.resize(bone_count)

	for i in range(bone_count):
		bone_vertices[i] = []

	# Read mesh data
	for surface in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface)

		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones_array = arrays[Mesh.ARRAY_BONES]
		var weights_array = arrays[Mesh.ARRAY_WEIGHTS]

		if vertices.is_empty():
			continue

		for v in range(vertices.size()):
			var vertex = vertices[v]

			# Convert vertex to global space
			var vertex_global = mesh_instance.global_transform * vertex

			# Apply bone weights
			if bones_array is PackedInt32Array:
				# Old format
				for i in range(4):
					var bone_idx = bones_array[v * 4 + i]
					var weight = weights_array[v * 4 + i]

					if weight > min_weight and bone_idx < bone_count:
						var bone_rest = skeleton.get_bone_rest(bone_idx)
						var bone_global = skeleton.global_transform * bone_rest
						var to_bone_space = bone_global.affine_inverse()

						var vertex_in_bone = to_bone_space * vertex_global
						bone_vertices[bone_idx].append(vertex_in_bone)

			elif bones_array is PackedVector4Array:
				# New format
				var bone_ids: Vector4 = bones_array[v]
				var bone_weights: Vector4 = weights_array[v]

				for i in range(4):
					var bone_idx = int(bone_ids[i])
					var weight = bone_weights[i]

					if weight > min_weight and bone_idx < bone_count:
						var bone_rest = skeleton.get_bone_rest(bone_idx)
						var bone_global = skeleton.global_transform * bone_rest
						var to_bone_space = bone_global.affine_inverse()

						var vertex_in_bone = to_bone_space * vertex_global
						bone_vertices[bone_idx].append(vertex_in_bone)

	# Build hitboxes
	for bone_idx in range(bone_count):
		var verts: Array = bone_vertices[bone_idx]

		if verts.size() < 3:
			continue

		var aabb := AABB(verts[0], Vector3.ZERO)

		for v in verts:
			aabb = aabb.expand(v)

		aabb = aabb.grow(padding)

		print(skeleton.get_bone_name(bone_idx), " size: ", aabb.size)

		if Update_Type == "Hurtbox":
			var hurtbox = create_hurtbox(bone_idx, aabb)
			hurtboxes.append(hurtbox)
		elif Update_Type != "":
			hitboxes.append(create_hitbox(bone_idx, aabb))


	print("Done generating hitboxes")



func create_hurtbox(bone_idx: int, aabb: AABB) -> Area3D:
	var bone_name = skeleton.get_bone_name(bone_idx)

	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone_name
	attachment.name = "BoneHurtbox_" + bone_name


	var collision := CollisionShape3D.new()

	skeleton.add_child(attachment,true)
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()

	area.name = bone_name
	shape.size = aabb.size
	col.shape = shape
	col.debug_color = Color.REBECCA_PURPLE

	area.add_child(col)
	attachment.add_child(area)

	area.owner = get_tree().edited_scene_root
	col.owner = get_tree().edited_scene_root
	attachment.owner = get_tree().edited_scene_root

	return area

func create_hitbox(bone_idx: int, aabb: AABB) -> Area3D:
	var bone_name = skeleton.get_bone_name(bone_idx)

	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone_name
	attachment.name = "BoneHitbox_" + bone_name

	skeleton.add_child(attachment,true)

	var area = Area3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()

	area.name = bone_name
	shape.size = aabb.size
	col.shape = shape

	area.add_child(col)
	attachment.add_child(area)

	col.disabled = true
	col.debug_color = Color.RED

	col.owner = get_tree().edited_scene_root
	area.owner = get_tree().edited_scene_root
	attachment.owner = get_tree().edited_scene_root

	return area

func _clear():
	print(Update_Type)
	if skeleton == null:
		push_error("Skeleton not assigned!")
		return

	var removed := 0

	if Update_Type == "Hurtbox":
		for child in skeleton.get_children():
			if child.name.begins_with("BoneHurtbox_"):
				child.queue_free()
				removed += 1
		hurtboxes.clear()
	elif Update_Type != "":
		for child in skeleton.get_children():
			if child.name.begins_with("BoneHitbox_"):
				child.queue_free()
				removed += 1
		hitboxes.clear()

	print(" Removed ", removed, " hitboxes")