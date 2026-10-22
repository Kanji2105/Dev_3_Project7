extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func send_key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run_checks() -> void:
	Input.use_accumulated_input = false
	var demo = load("res://scenes/Shader_Demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	var player = demo.get_node("PSXRender/Viewport/GameWorld/Player")
	var psx = demo.get_node("PSXRender")
	for i in range(90):
		await physics_frame
	assert(player.is_on_floor(), "Player must settle in viewport physics world")
	for divisor in range(1, 5):
		await send_key(KEY_1 + divisor - 1)
		assert(psx.resolution_divisor == divisor, "Preset key failed")
		await process_frame
		var expected := Vector2i(Vector2(root.get_visible_rect().size) / divisor)
		assert(psx.render_size() == expected, "Wrong resolution")
		assert(psx.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var before: float = player.rotation.y
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(20, 0)
		motion.screen_relative = Vector2(20, 0)
		motion.position = Vector2(640,360)
		Input.parse_input_event(motion)
		print("YAW DELTA ", player.rotation.y - before)
		assert(absf((player.rotation.y - before) + 0.04) < 0.001, "Mouse lost or sensitivity changed")
		player.reset_view()
		for i in range(20):
			await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://pixelation-mode-%d.png" % divisor)
		print("PASS preset ", divisor, " ", psx.render_size(), " mouse stable")
	var was_on: bool = player.flashlight.visible
	await send_key(KEY_F)
	assert(player.flashlight.visible != was_on, "Flashlight input lost")
	await send_key(KEY_F)
	await send_key(KEY_L)
	assert(demo.dim_lighting)
	await send_key(KEY_L)
	await send_key(KEY_ESCAPE)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var click := InputEventMouseButton.new()
	click.position = Vector2(700,400)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Click capture failed")
	var start: Vector3 = player.position
	Input.action_press("move_forward")
	for i in range(40):
		await physics_frame
	Input.action_release("move_forward")
	assert(player.position.distance_to(start) > 0.1)
	await send_key(KEY_R)
	assert(player.position.distance_to(player.spawn_transform.origin) < 0.15)
	await send_key(KEY_H)
	assert(not demo.get_node("HUD").visible)
	await send_key(KEY_H)
	assert(demo.get_node("HUD").visible)
	root.size = Vector2i(960,540)
	for i in range(10):
		await process_frame
	assert(psx.size == root.get_visible_rect().size, "Resize mismatch")
	assert(demo.get_node("HUD").get_viewport() == root, "HUD got pixelated")
	print("ALL PIXELATION CHECKS PASSED: presets, mouse, light, movement, reset, cursor, HUD, resize")
	quit()


