extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var demo=load("res://scenes/Shader_Demo.tscn").instantiate()
	root.add_child(demo)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	var result=[]
	for preset in ["Original","Mild PSX","Strong PSX","Eco"]:
		demo.apply_preset(preset)
		for i in range(90): await process_frame
		var times=[]
		var last=Time.get_ticks_usec()
		for i in range(240):
			await process_frame
			var now=Time.get_ticks_usec()
			times.append(float(now-last)/1000.0)
			last=now
		times.sort()
		result.append({"mode":preset,"median_frame_ms":times[120],"p95_frame_ms":times[228],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
	var f=FileAccess.open("res://checks/performance-fresh.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	print(JSON.stringify(result))
	quit()
