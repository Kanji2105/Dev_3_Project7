extends SubViewportContainer

signal settings_changed

@export_enum("Original:1", "Mild:2", "Medium:3", "Strong:4") var resolution_divisor: int = 2:
	set(value):
		resolution_divisor = clampi(value, 1, 4)
		if is_node_ready(): _apply()
@export var dithering_enabled := true:
	set(value):
		dithering_enabled = value
		if is_node_ready(): _apply()
@export_range(0.0, 1.0) var dither_strength := 0.7:
	set(value):
		dither_strength = clampf(value, 0.0, 1.0)
		if is_node_ready(): _apply()
@export_range(4, 64) var color_levels := 32:
	set(value):
		color_levels = clampi(value, 4, 64)
		if is_node_ready(): _apply()
@export var wobble_enabled := true:
	set(value):
		wobble_enabled = value
		if is_node_ready(): _apply()
@export_range(0.0, 1.0) var wobble_strength := 0.35:
	set(value):
		wobble_strength = clampf(value, 0.0, 1.0)
		if is_node_ready(): _apply()

var comparing := false
var _dither := ShaderMaterial.new()
var _surfaces: Array[Dictionary] = []
var _materials: Dictionary = {}
var _applied_wobble := false
var _shaders: Dictionary = {}

func _ready() -> void:
	stretch = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dither.shader = preload("res://PSXRender/dither.gdshader")
	get_viewport().size_changed.connect(_fit_window)
	$Viewport.size_changed.connect(_update_source_size)
	refresh_wobble_targets()
	_fit_window()
	_apply()

func _fit_window() -> void:
	size = get_viewport_rect().size

func _update_source_size() -> void:
	_dither.set_shader_parameter("source_size", Vector2($Viewport.size))

func render_size() -> Vector2i:
	return $Viewport.size

func set_comparison(enabled: bool) -> void:
	comparing = enabled
	_apply()

func _apply() -> void:
	stretch_shrink = 1 if comparing else resolution_divisor
	material = _dither if dithering_enabled and not comparing else null
	_dither.set_shader_parameter("strength", dither_strength)
	_dither.set_shader_parameter("levels", float(color_levels))
	_update_source_size()
	var active := wobble_enabled and not comparing
	if active != _applied_wobble:
		for entry in _surfaces:
			if is_instance_valid(entry.mesh):
				entry.mesh.set_surface_override_material(entry.index, entry.converted if active else entry.original)
		_applied_wobble = active
	for converted in _materials.values():
		converted.set_shader_parameter("wobble_strength", wobble_strength)
	settings_changed.emit()

func refresh_wobble_targets() -> void:
	for entry in _surfaces:
		if is_instance_valid(entry.mesh):
			entry.mesh.set_surface_override_material(entry.index, entry.original)
	_surfaces.clear()
	_materials.clear()
	_applied_wobble = false
	_collect($Viewport/GameWorld, false)
	if is_node_ready(): _apply()

func _collect(node: Node, selected: bool) -> void:
	selected = selected or node.is_in_group("psx_wobble")
	if selected and node is MeshInstance3D and node.mesh and not node.material_override and not node.material_overlay:
		for i in range(node.mesh.get_surface_count()):
			var source = node.get_active_material(i)
			# shortcut: only plain opaque StandardMaterial3D; author custom shaders for advanced materials.
			if not source is StandardMaterial3D or source.transparency != 0 or source.shading_mode != 1 or source.normal_enabled or source.emission_enabled or source.vertex_color_use_as_albedo or source.uv1_triplanar or source.detail_enabled or source.rim_enabled or source.clearcoat_enabled or source.subsurf_scatter_enabled or source.heightmap_enabled or source.metallic_texture or source.roughness_texture or source.ao_enabled or source.next_pass or node.mesh.get_blend_shape_count() > 0:
				continue
			if not _materials.has(source):
				var converted := ShaderMaterial.new()
				if not _shaders.has(source.cull_mode):
					var shader := Shader.new()
					shader.code = preload("res://PSXRender/wobble.gdshader").code.replace("cull_disabled", ["cull_back", "cull_front", "cull_disabled"][source.cull_mode])
					_shaders[source.cull_mode] = shader
				converted.shader = _shaders[source.cull_mode]
				converted.set_shader_parameter("albedo_texture", source.albedo_texture)
				converted.set_shader_parameter("tint", source.albedo_color)
				converted.set_shader_parameter("uv_scale", source.uv1_scale)
				converted.set_shader_parameter("uv_offset", source.uv1_offset)
				converted.set_shader_parameter("roughness_value", source.roughness)
				converted.set_shader_parameter("metallic_value", source.metallic)
				converted.set_shader_parameter("specular_value", source.metallic_specular)
				_materials[source] = converted
			_surfaces.append({"mesh":node, "index":i, "original":node.get_surface_override_material(i), "converted":_materials[source]})
	for child in node.get_children(): _collect(child, selected)
