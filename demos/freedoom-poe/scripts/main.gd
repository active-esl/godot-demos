extends Control

const Raycaster = preload("res://scripts/raycaster.gd")
const CARBON := Color("07111f")
const PANEL := Color("101d30")
const CYAN := Color("20d6d2")
const LIME := Color("b6f23b")
const VIOLET := Color("7557ff")

var engine = Raycaster.new()
var screen: TextureRect
var texture := ImageTexture.new()
var telemetry: Label
var status: Label
var input_state := {"forward": false, "back": false, "left": false, "right": false, "strafe_left": false, "strafe_right": false}
var attract := true
var attract_clock := 0.0
var frame_clock := 0.0
var web_pointer_callback = null
var web_pointer_sequence := 0

func _ready() -> void:
	_build_ui()
	_build_web_pointer_bridge()
	_refresh_frame()
	print("FREEDOOM_POE_DEMO_READY")

func _build_web_pointer_bridge() -> void:
	if not OS.has_feature("HTML5"):
		return
	web_pointer_callback = JavaScript.create_callback(self, "_on_web_pointer_tap")
	var window = JavaScript.get_interface("window")
	window.activePoeInput = web_pointer_callback
	window.activePoeInputReady = true
	window.activePoeUxState = "attract"

func _on_web_pointer_tap(args: Array) -> void:
	if args.size() < 2:
		return
	var viewport_size := get_viewport_rect().size
	var position := Vector2(clamp(float(args[0]), 0.0, 1.0) * viewport_size.x, clamp(float(args[1]), 0.0, 1.0) * viewport_size.y)
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.button_index = BUTTON_LEFT
	press.position = position
	press.global_position = position
	press.pressed = true
	Input.parse_input_event(press)
	get_tree().create_timer(0.12).connect("timeout", self, "_release_web_pointer", [position])
	web_pointer_sequence += 1
	var window = JavaScript.get_interface("window")
	window.activePoeInputAck = web_pointer_sequence
	window.activePoeUxState = "manual"

func _release_web_pointer(position: Vector2) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = BUTTON_LEFT
	release.position = position
	release.global_position = position
	release.pressed = false
	Input.parse_input_event(release)

func _process(delta: float) -> void:
	var forward := (1.0 if input_state.forward else 0.0) - (1.0 if input_state.back else 0.0)
	var turn := (1.0 if input_state.right else 0.0) - (1.0 if input_state.left else 0.0)
	var strafe := (1.0 if input_state.strafe_right else 0.0) - (1.0 if input_state.strafe_left else 0.0)
	if attract:
		attract_clock += delta
		forward = 0.65
		turn = sin(attract_clock * 0.47) * 0.72
	engine.step(delta, forward, turn, strafe)
	frame_clock += delta
	if frame_clock >= 1.0 / 20.0:
		frame_clock = 0.0
		_refresh_frame()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			attract = false
		match event.scancode:
			KEY_W, KEY_UP: input_state.forward = event.pressed
			KEY_S, KEY_DOWN: input_state.back = event.pressed
			KEY_A, KEY_LEFT: input_state.left = event.pressed
			KEY_D, KEY_RIGHT: input_state.right = event.pressed
			KEY_Q: input_state.strafe_left = event.pressed
			KEY_E: input_state.strafe_right = event.pressed
			KEY_SPACE:
				if event.pressed: _fire()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = CARBON
	bg.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE, 24)
	root.add_constant_override("separation", 18)
	add_child(root)
	var header := HBoxContainer.new()
	header.rect_min_size.y = 82
	root.add_child(header)
	var title := Label.new()
	title.text = "CAN IT RUN FREEDOOM?"
	title.add_color_override("font_color", Color("f7f9fc"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	status = Label.new()
	status.text = "ATTRACT MODE · TOUCH TO PLAY"
	status.add_color_override("font_color", LIME)
	header.add_child(status)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_constant_override("separation", 20)
	root.add_child(body)
	var viewport_panel := PanelContainer.new()
	viewport_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_panel.add_stylebox_override("panel", _panel_style(Color("05070b"), CYAN))
	body.add_child(viewport_panel)
	screen = TextureRect.new()
	screen.expand = true
	screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_panel.add_child(screen)
	var side := VBoxContainer.new()
	side.rect_min_size.x = 330
	side.add_constant_override("separation", 12)
	body.add_child(side)
	var kicker := Label.new()
	kicker.text = "POE EDGE RUNTIME"
	kicker.add_color_override("font_color", CYAN)
	side.add_child(kicker)
	var description := Label.new()
	description.text = "Touch-first 2.5D engine proof\ninside the Active-Edge PoE platform."
	description.add_color_override("font_color", Color("a7b4c8"))
	side.add_child(description)
	telemetry = Label.new()
	telemetry.rect_min_size.y = 112
	telemetry.add_color_override("font_color", Color("f7f9fc"))
	side.add_child(telemetry)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_constant_override("hseparation", 9)
	grid.add_constant_override("vseparation", 9)
	side.add_child(grid)
	_add_spacer(grid)
	_add_hold_button(grid, "▲", "forward")
	_add_spacer(grid)
	_add_hold_button(grid, "◀", "left")
	_add_hold_button(grid, "▼", "back")
	_add_hold_button(grid, "▶", "right")
	_add_hold_button(grid, "↤", "strafe_left")
	_add_action_button(grid, "FIRE", "_fire", VIOLET)
	_add_hold_button(grid, "↦", "strafe_right")
	_add_action_button(side, "USE / OPEN", "_use", CYAN)
	_add_action_button(side, "RESUME ATTRACT MODE", "_resume_attract", LIME)
	var footer := Label.new()
	footer.text = "GODOT 3.6 · GLES2 · SOFTWARE RAYCAST PROOF\nGPL ENGINE + FREEDOOM PAYLOAD INTEGRATION SEAM"
	footer.add_color_override("font_color", Color("72839a"))
	side.add_child(footer)

func _add_spacer(parent: Control) -> void:
	var spacer := Control.new()
	spacer.rect_min_size = Vector2(94, 64)
	parent.add_child(spacer)

func _add_hold_button(parent: Control, text: String, key: String) -> void:
	var button := _button(text, CYAN)
	button.rect_min_size = Vector2(94, 64)
	button.connect("button_down", self, "_set_control", [key, true])
	button.connect("button_up", self, "_set_control", [key, false])
	parent.add_child(button)

func _add_action_button(parent: Control, text: String, method: String, colour: Color) -> void:
	var button := _button(text, colour)
	button.rect_min_size.y = 58
	button.connect("pressed", self, method)
	parent.add_child(button)

func _button(text: String, colour: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_color_override("font_color", Color("f7f9fc"))
	button.add_stylebox_override("normal", _panel_style(PANEL, colour.darkened(0.55)))
	button.add_stylebox_override("hover", _panel_style(colour.darkened(0.60), colour))
	button.add_stylebox_override("pressed", _panel_style(colour.darkened(0.32), LIME))
	return button

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _set_control(key: String, pressed: bool) -> void:
	attract = false
	input_state[key] = pressed
	status.text = "MANUAL CONTROL · %s" % key.to_upper().replace("_", " ")

func _fire() -> void:
	attract = false
	engine.fire()
	status.text = "PLASMA DISCHARGE · SHOT %02d" % engine.shots

func _use() -> void:
	attract = false
	engine.use()
	status.text = "ACCESS CONTROL PULSE %02d" % engine.doors

func _resume_attract() -> void:
	attract = true
	status.text = "ATTRACT MODE · TOUCH TO PLAY"

func _refresh_frame() -> void:
	var image = engine.render_frame()
	texture.create_from_image(image, Texture.FLAG_FILTER)
	screen.texture = texture
	var snap = engine.snapshot()
	telemetry.text = "FRAMEBUFFER     256 × 160 @ 20 Hz\nPOSITION        %04.1f / %04.1f\nHEADING         %03d°\nINPUT           TOUCH + USB HID" % [snap.x, snap.y, int(rad2deg(snap.heading)) % 360]
