extends Node3D

@onready var stats: Label = $HUD/Margin/Panel/Padding/Info/Stats
@onready var status: Label = $HUD/Margin/Panel/Padding/Info/Status
@onready var psx = $PSXRender
@onready var world = $PSXRender/Viewport/GameWorld
var elapsed := 0.0
var dim_lighting := false
var menu := PanelContainer.new()
var resolution := OptionButton.new()
var dither := CheckButton.new()
var wobble := CheckButton.new()
var dither_amount := HSlider.new()
var wobble_amount := HSlider.new()
var palette := OptionButton.new()
var shadows := CheckButton.new()

func _ready() -> void:
	Engine.max_fps = 60
	_build_menu()
	psx.settings_changed.connect(_sync_menu)
	get_viewport().size_changed.connect(_place_ui)
	_place_ui()
	_sync_menu()
	$HUD/Margin/Panel/Padding/Info/Controls.text = "WASD: Move   Shift: Sprint   F: Flashlight\n1-4: Resolution   T: Dither   V: Wobble\nHold Tab: Original   Esc: Settings\nL: Lighting   R: Reset view   H: Hide HUD"

func _place_ui() -> void:
	var size := get_viewport().get_visible_rect().size
	menu.position = Vector2(size.x - 336, 20)
	$HUD/Crosshair.position = size * 0.5 - Vector2(5,12)

func _build_menu() -> void:
	menu.name = "Settings"
	menu.custom_minimum_size = Vector2(316,0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.045,0.055,0.97)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	menu.add_theme_stylebox_override("panel",style)
	$HUD.add_child(menu)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	menu.add_child(column)
	var title := Label.new()
	title.text = "PSX SETTINGS"
	column.add_child(title)
	var buttons := GridContainer.new()
	buttons.columns = 2
	column.add_child(buttons)
	for preset in ["Original", "Mild PSX", "Strong PSX", "Eco"]:
		var button := Button.new()
		button.text = preset
		button.custom_minimum_size = Vector2(138,34)
		button.pressed.connect(apply_preset.bind(preset))
		buttons.add_child(button)
	for label in ["Full resolution", "1/2 resolution", "1/3 resolution", "1/4 resolution"]:
		resolution.add_item(label)
	resolution.item_selected.connect(func(index: int): psx.resolution_divisor = index + 1)
	column.add_child(resolution)
	dither.text = "Dithering"
	dither.toggled.connect(func(on: bool): psx.dithering_enabled = on)
	column.add_child(dither)
	_add_slider(column, dither_amount, "Dither strength", func(value: float): psx.dither_strength = value)
	for count in [16,32,64]: palette.add_item("%d color levels / channel" % count,count)
	palette.item_selected.connect(func(index: int): psx.color_levels = palette.get_item_id(index))
	column.add_child(palette)
	wobble.text = "Vertex wobble (props)"
	wobble.toggled.connect(func(on: bool): psx.wobble_enabled = on)
	column.add_child(wobble)
	_add_slider(column,wobble_amount,"Wobble strength",func(value: float): psx.wobble_strength = value)
	shadows.text = "Real-time shadows (higher GPU cost)"
	shadows.add_theme_font_size_override("font_size",14)
	shadows.toggled.connect(_set_shadows)
	column.add_child(shadows)
	var resume := Button.new()
	resume.text = "Back to demo"
	resume.custom_minimum_size.y = 36
	resume.pressed.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	column.add_child(resume)
	var note := Label.new()
	note.text = "Hold Tab to compare.\nHUD stays sharp. 60 FPS cap."
	note.add_theme_font_size_override("font_size",14)
	column.add_child(note)

func _add_slider(parent: Node, slider: HSlider, text: String, callback: Callable) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",14)
	parent.add_child(label)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size.y = 24
	slider.value_changed.connect(callback)
	parent.add_child(slider)

func _sync_menu() -> void:
	resolution.select(psx.resolution_divisor - 1)
	dither.set_pressed_no_signal(psx.dithering_enabled)
	wobble.set_pressed_no_signal(psx.wobble_enabled)
	dither_amount.set_value_no_signal(psx.dither_strength)
	wobble_amount.set_value_no_signal(psx.wobble_strength)
	palette.select(palette.get_item_index(psx.color_levels))
	shadows.set_pressed_no_signal(world.get_node("Player/Camera3D/Flashlight").shadow_enabled)

func _set_shadows(on: bool) -> void:
	world.get_node("Player/Camera3D/Flashlight").shadow_enabled = on
	world.get_node("Storage/Lighting/Ceiling_Light_Main").shadow_enabled = on
	shadows.set_pressed_no_signal(on)

func apply_preset(preset: String) -> void:
	psx.set_comparison(false)
	psx.resolution_divisor = 1 if preset == "Original" else (4 if preset == "Strong PSX" else 2)
	psx.dithering_enabled = preset != "Original"
	psx.wobble_enabled = preset != "Original" and preset != "Eco"
	psx.dither_strength = 0.7 if preset != "Strong PSX" else 1.0
	psx.color_levels = 16 if preset == "Strong PSX" else 32
	psx.wobble_strength = 0.7 if preset == "Strong PSX" else 0.35
	_set_shadows(preset != "Eco")

func _process(delta: float) -> void:
	menu.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	$HUD/Crosshair.visible = not menu.visible
	elapsed += delta
	if elapsed >= 0.25:
		elapsed = 0.0
		stats.text = "%d FPS | %d draw calls | Compatibility" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		var pixels: Vector2i = psx.render_size()
		status.text = "%s | %d x %d | Sharp HUD" % ["Original comparison" if psx.comparing else "PSX demo",pixels.x,pixels.y]

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		psx.set_comparison(false)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.physical_keycode == KEY_TAB:
			psx.set_comparison(event.pressed)
			get_viewport().set_input_as_handled()
		if event.pressed:
			if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
				psx.resolution_divisor = event.physical_keycode - KEY_1 + 1
				get_viewport().set_input_as_handled()
			elif event.physical_keycode == KEY_T:
				psx.dithering_enabled = not psx.dithering_enabled
				get_viewport().set_input_as_handled()
			elif event.physical_keycode == KEY_V:
				psx.wobble_enabled = not psx.wobble_enabled
				get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_hud"):
		$HUD.visible = not $HUD.visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_lighting"):
		dim_lighting = not dim_lighting
		world.get_node("WorldEnvironment").environment.ambient_light_energy = 0.14 if dim_lighting else 0.35
		world.get_node("SoftRoomFill").light_energy = 0.12 if dim_lighting else 0.45
		world.get_node("Storage/Lighting/Ceiling_Light_Main").light_energy = 0.18 if dim_lighting else 0.4
		get_viewport().set_input_as_handled()
