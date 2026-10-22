extends SceneTree
var demo
var psx
var world
var samples := []
func _initialize() -> void:
	call_deferred("run")
func frames(count: int = 5) -> void:
	for i in range(count): await process_frame
func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func shot(name: String) -> Image:
	await frames(8)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	assert(img.save_png("res://previews/" + name + ".png") == OK)
	return img
func changes(a: Image, b: Image) -> int:
	var count := 0
	for y in range(0,a.get_height(),4):
		for x in range(0,a.get_width(),4):
			var ac := a.get_pixel(x,y)
			var bc := b.get_pixel(x,y)
			if maxf(absf(ac.r-bc.r),maxf(absf(ac.g-bc.g),absf(ac.b-bc.b))) > 0.01: count += 1
	return count
func measure(name: String) -> void:
	await frames(70)
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in range(180):
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now-last)/1000.0)
		last = now
	times.sort()
	samples.append({"mode":name,"median_frame_ms":times[90],"p95_frame_ms":times[171],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
func run() -> void:
	Input.use_accumulated_input = false
	demo = load("res://scenes/Shader_Demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	psx = demo.get_node("PSXRender")
	world = psx.get_node("Viewport/GameWorld")
	await frames(90)
	world.get_node("Player").set_physics_process(false)
	demo.get_node("HUD").hide()
	DirAccess.make_dir_recursive_absolute("res://previews")
	demo.apply_preset("Original")
	var baked_original := await shot("01-original")
	var baked = world.get_node("Storage")
	var baked_count: int = baked.find_children("*","CollisionShape3D",true,false).size()
	world.remove_child(baked)
	var original = load("res://scenes/Storage.tscn").instantiate()
	world.add_child(original)
	assert(original.find_children("*","CollisionShape3D",true,false).size() == baked_count,"Collider count changed")
	var source_original := await shot("00-source-room")
	var bake_diff := changes(baked_original,source_original)
	print("Room bake changed samples: ",bake_diff," / 57600")
	assert(bake_diff < 600,"Baked room visually differs too much")
	world.remove_child(original)
	original.free()
	world.add_child(baked)
	psx.refresh_wobble_targets()
	assert(psx._surfaces.size() > 0,"No wobble targets")
	psx.resolution_divisor = 2
	var pixel_only := await shot("02-pixelation-only")
	psx.dithering_enabled = true
	psx.color_levels = 16
	psx.dither_strength = 1.0
	var dither_image := await shot("03-dithering")
	assert(changes(pixel_only,dither_image)>100,"Dithering had no visible effect")
	psx.wobble_enabled = true
	psx.wobble_strength = 0.7
	var wobble_image := await shot("04-all-effects")
	assert(changes(dither_image,wobble_image)>10,"Wobble had no visible effect")
	for entry in psx._surfaces: assert(entry.mesh.get_surface_override_material(entry.index) is ShaderMaterial)
	key(KEY_TAB,true)
	await frames()
	assert(psx.comparing and psx.stretch_shrink == 1 and psx.material == null)
	for entry in psx._surfaces: assert(entry.mesh.get_surface_override_material(entry.index) == entry.original)
	key(KEY_TAB,false)
	await frames()
	assert(not psx.comparing and psx.stretch_shrink == 2 and psx.material != null)
	assert(psx.color_levels == 16 and is_equal_approx(psx.wobble_strength,0.7))
	key(KEY_TAB,true)
	demo.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not psx.comparing,"Comparison stuck on focus loss")
	key(KEY_TAB,false)
	# Independent instances and unsupported custom materials must remain untouched.
	var other = load("res://PSXRender/PSXRender.tscn").instantiate()
	root.add_child(other)
	other.hide()
	other.dither_strength = 0.1
	assert(other._dither != psx._dither and psx.dither_strength == 1.0)
	other.queue_free()
	var special := MeshInstance3D.new()
	special.mesh = BoxMesh.new()
	var custom := ShaderMaterial.new()
	custom.shader = Shader.new()
	custom.shader.code = "shader_type spatial; void fragment(){ALBEDO=vec3(1.0);}"
	special.set_surface_override_material(0,custom)
	special.add_to_group("psx_wobble")
	world.add_child(special)
	psx.refresh_wobble_targets()
	assert(special.get_surface_override_material(0)==custom)
	special.queue_free()
	await frames()
	demo.get_node("HUD").show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await frames()
	var button: Button = demo.menu.find_children("*","Button",true,false)[1]
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = button.get_global_rect().get_center()
	click.pressed = true
	Input.parse_input_event(click)
	await frames(1)
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await frames()
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Settings click captured mouse")
	assert(psx.color_levels == 32 and psx.wobble_strength < 0.4,"Mild preset button failed")
	await shot("05-settings")
	demo.get_node("HUD").hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for preset in ["Original","Mild PSX","Strong PSX","Eco"]:
		demo.apply_preset(preset)
		await measure(preset)
	var report := FileAccess.open("res://checks/performance.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(samples,"  "))
	print("PERFORMANCE ",JSON.stringify(samples))
	print("ALL PSX CHECKS PASSED: room parity, colliders, visible effects, restoration, focus, material isolation, GUI, presets")
	quit()

