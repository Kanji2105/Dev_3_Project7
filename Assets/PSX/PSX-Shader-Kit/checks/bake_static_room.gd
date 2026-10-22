extends SceneTree
# This frozen demo room has no gameplay animation. Keep Storage.tscn as the editable source.
var buckets := {}
var materials := {}
var source: Node3D
var output := Node3D.new()
var original_surfaces := 0
func _initialize() -> void:
	call_deferred("bake")
func own(node: Node) -> void:
	node.owner = output
	for child in node.get_children(): own(child)
func scan(node: Node) -> void:
	if node is MeshInstance3D and node.mesh and node.is_visible_in_tree():
		var category := "Furniture" if str(source.get_path_to(node)).begins_with("Furniture/") else "Architecture"
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			# Match all stored material properties, not just the texture or resource name.
			var signature := category
			if mat:
				for prop in mat.get_property_list():
					if prop.usage & PROPERTY_USAGE_STORAGE and not str(prop.name).begins_with("resource_"):
						signature += str(prop.name) + str(mat.get(prop.name))
			signature += str(node.cast_shadow)
			if not buckets.has(signature):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				buckets[signature] = {"tool":tool,"material":mat,"category":category,"shadow":node.cast_shadow}
			buckets[signature].tool.append_from(node.mesh,i,source.global_transform.affine_inverse()*node.global_transform)
			original_surfaces += 1
	elif node is StaticBody3D or node is Light3D or node is Label3D:
		var copy = node.duplicate()
		output.add_child(copy)
		copy.transform = source.global_transform.affine_inverse() * node.global_transform
		own(copy)
		if node is StaticBody3D: return
	for child in node.get_children(): scan(child)
func bake() -> void:
	source = load("res://scenes/Storage.tscn").instantiate()
	root.add_child(source)
	output.name = "Storage"
	root.add_child(output)
	scan(source)
	for data in buckets.values():
		data.tool.index()
		var mesh: ArrayMesh = data.tool.commit()
		mesh.surface_set_material(0,data.material)
		var instance := MeshInstance3D.new()
		instance.name = data.category + "_" + str(output.get_child_count())
		instance.mesh = mesh
		instance.cast_shadow = data.shadow
		output.add_child(instance)
		instance.owner = output
		if data.category == "Furniture": instance.add_to_group("psx_wobble",true)
	# Preserve the light path used by the demo lighting toggle.
	var lighting := Node3D.new()
	lighting.name = "Lighting"
	output.add_child(lighting)
	lighting.owner = output
	var light := output.get_node("Ceiling_Light_Main")
	light.reparent(lighting)
	light.owner = output
	var packed := PackedScene.new()
	assert(packed.pack(output)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/Storage_Optimized.scn")==OK)
	print("STATIC BAKE: ",original_surfaces," surfaces -> ",buckets.size()," material batches; collisions retained")
	quit()

