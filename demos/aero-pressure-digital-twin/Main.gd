extends Spatial

# Anonymous touch-first concept. Vehicle geometry and all telemetry are simulated.
const NAVY = Color("071326")
const PANEL = Color("0d1d33")
const PANEL_LIGHT = Color("132944")
const WHITE = Color("f5f8fc")
const MUTED = Color("8fa5bd")
const CYAN = Color("20d6d2")
const BLUE = Color("2c72ff")
const LIME = Color("b6f23b")
const AMBER = Color("ffb020")
const RED = Color("ff4d68")

var car
var camera
var yaw = -0.62
var pitch = -0.30
var distance = 10.5
var tunnel_speed = 220.0
var flow_enabled = true
var elapsed = 0.0
var flow_lines = []
var sensor_markers = []
var sensor_values = []
var selected_sensor = 0
var dragging = false
var drag_origin = Vector2()
var yaw_origin = 0.0
var pitch_origin = 0.0
var speed_value
var pressure_value
var delta_value
var load_value
var status_value
var sensor_buttons = []

var sensor_names = [
	"FRONT WING", "NOSE", "FRONT FLOOR", "COCKPIT",
	"MID FLOOR", "SIDE BODY", "DIFFUSER", "REAR WING"
]
var sensor_positions = [
	Vector3(-3.55, 0.24, 0.68), Vector3(-2.35, 0.48, 0.0),
	Vector3(-1.45, 0.10, 0.62), Vector3(-0.35, 0.92, 0.0),
	Vector3(0.55, 0.10, -0.63), Vector3(0.75, 0.48, 0.72),
	Vector3(2.55, 0.18, 0.0), Vector3(3.22, 1.05, -0.60)
]
var pressure_bias = [310.0, 520.0, -610.0, 105.0, -840.0, -260.0, -720.0, 445.0]

func _ready():
	build_world()
	build_car()
	build_airflow()
	build_ui()
	update_camera()
	print("AERO_TWIN_READY screen=%s window=%s controls=true sensors=%d" % [OS.get_screen_size(), OS.window_size, sensor_names.size()])

func build_world():
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = NAVY
	e.ambient_light_color = Color("87a7c7")
	e.ambient_light_energy = 0.55
	# Keep the target shader below the embedded GLES2 varying limit.
	e.fog_enabled = false
	env.environment = e
	add_child(env)

	var key = DirectionalLight.new()
	key.rotation_degrees = Vector3(-48, -32, 0)
	key.light_color = Color("d9efff")
	key.light_energy = 1.15
	key.shadow_enabled = false
	add_child(key)
	var fill = OmniLight.new()
	fill.translation = Vector3(-3, 5, 5)
	fill.light_color = CYAN
	fill.light_energy = 1.6
	fill.omni_range = 14
	add_child(fill)

	camera = Camera.new()
	camera.fov = 47
	add_child(camera)

	add_mesh(box_mesh(Vector3(18, 0.08, 8)), Vector3(0, -0.55, 0), material(Color("0b2035"), 0.2))
	for x in [-7.0, -3.5, 0.0, 3.5, 7.0]:
		add_mesh(box_mesh(Vector3(0.045, 4.8, 8)), Vector3(x, 1.8, 0), material(Color(0.12, 0.55, 0.68, 0.16), 0.0, true))
	for z in [-3.7, 3.7]:
		add_mesh(box_mesh(Vector3(18, 0.035, 0.035)), Vector3(0, 1.8, z), material(Color(0.15, 0.75, 0.83, 0.35), 0.0, true))

func build_car():
	car = Spatial.new()
	car.name = "AnonymousSingleSeater"
	add_child(car)
	var packed_car = load("res://assets/racing_car.glb")
	var model = packed_car.instance()
	model.name = "CC0RacingCar"
	model.scale = Vector3(1.65, 1.65, 1.65)
	model.translation = Vector3(0, -0.48, 0)
	car.add_child(model)
	simplify_model_materials(model)

	for i in range(sensor_positions.size()):
		var marker = part(sphere_mesh(0.105, 12, 6), sensor_positions[i], material(CYAN, 0.0))
		marker.name = "PressureTap%02d" % (i + 1)
		sensor_markers.append(marker)
		sensor_values.append(101325.0)

func build_airflow():
	var flow_material = material(Color(0.12, 0.84, 0.82, 0.55), 0.0, true)
	var flow_mesh = box_mesh(Vector3(1.15, 0.025, 0.025))
	for i in range(42):
		var line = MeshInstance.new()
		line.mesh = flow_mesh
		line.material_override = flow_material
		line.set_meta("lane", i)
		line.set_meta("phase", float(i % 7) / 7.0)
		add_child(line)
		flow_lines.append(line)

func build_ui():
	var layer = CanvasLayer.new()
	add_child(layer)
	var root = Control.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	layer.add_child(root)

	var header = PanelContainer.new()
	header.anchor_right = 1.0
	header.rect_min_size.y = 112
	header.add_stylebox_override("panel", panel_style(Color(0.025, 0.07, 0.12, 0.94), CYAN, 0, 3))
	root.add_child(header)
	var hm = MarginContainer.new()
	set_margins(hm, 42, 20, 42, 18)
	header.add_child(hm)
	var hr = HBoxContainer.new()
	hr.add_constant_override("separation", 22)
	hm.add_child(hr)
	var mark = ColorRect.new()
	mark.color = CYAN
	mark.rect_min_size = Vector2(11, 58)
	hr.add_child(mark)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(text("AERO PRESSURE DIGITAL TWIN", 28, WHITE, true))
	titles.add_child(text("VIRTUAL WIND TUNNEL  •  SIMULATED DATA", 15, MUTED, false))
	hr.add_child(titles)
	hr.add_child(pill("●  8 PRESSURE ZONES ONLINE", LIME, 330))

	var hint = pill("DRAG TO ORBIT  •  TOUCH CONTROLS", CYAN, 390)
	hint.anchor_left = 0.025
	hint.anchor_top = 0.12
	hint.rect_position.y = 18
	root.add_child(hint)

	var side = PanelContainer.new()
	side.anchor_left = 0.765
	side.anchor_right = 0.985
	side.anchor_top = 0.12
	side.anchor_bottom = 0.97
	side.add_stylebox_override("panel", panel_style(Color(0.035, 0.09, 0.15, 0.96), Color(0.15, 0.33, 0.48, 0.9), 18, 1))
	root.add_child(side)
	var sm = MarginContainer.new()
	set_margins(sm, 26, 25, 26, 24)
	side.add_child(sm)
	var column = VBoxContainer.new()
	column.add_constant_override("separation", 13)
	sm.add_child(column)
	column.add_child(text("LIVE AERODYNAMICS", 21, WHITE, true))
	column.add_child(text("Distributed pressure acquisition", 14, MUTED, false))
	column.add_child(separator())
	speed_value = metric_row(column, "TUNNEL SPEED", "220 km/h", CYAN)
	pressure_value = metric_row(column, "ABS PRESSURE", "101.325 kPa", WHITE)
	delta_value = metric_row(column, "SELECTED ΔP", "+0.31 kPa", AMBER)
	load_value = metric_row(column, "AERO LOAD", "1.00 ×", LIME)
	status_value = metric_row(column, "SAMPLE STREAM", "480 Hz", CYAN)
	column.add_child(separator())
	column.add_child(text("TUNNEL SPEED", 14, MUTED, true))
	var slider = HSlider.new()
	slider.min_value = 120
	slider.max_value = 300
	slider.step = 5
	slider.value = tunnel_speed
	slider.rect_min_size.y = 54
	slider.connect("value_changed", self, "speed_changed")
	column.add_child(slider)
	var toggle = action_button("PAUSE AIRFLOW")
	toggle.connect("pressed", self, "toggle_flow", [toggle])
	column.add_child(toggle)
	column.add_child(text("PRESSURE ZONES", 14, MUTED, true))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_constant_override("hseparation", 8)
	grid.add_constant_override("vseparation", 8)
	column.add_child(grid)
	for i in range(sensor_names.size()):
		var b = action_button("%02d  %s" % [i + 1, sensor_names[i]])
		b.rect_min_size.y = 42
		b.connect("pressed", self, "select_sensor", [i])
		grid.add_child(b)
		sensor_buttons.append(b)
	column.add_child(separator())
	var views = HBoxContainer.new()
	views.add_constant_override("separation", 8)
	column.add_child(views)
	for item in [["SIDE", -0.62, -0.30], ["FRONT", -1.57, -0.12], ["TOP", -0.62, -1.05]]:
		var b = action_button(item[0])
		b.connect("pressed", self, "set_view", [item[1], item[2]])
		views.add_child(b)
	select_sensor(0)

func _process(delta):
	elapsed += delta
	var speed_factor = tunnel_speed / 220.0
	for i in range(flow_lines.size()):
		var line = flow_lines[i]
		var lane = int(line.get_meta("lane"))
		var row = lane % 7
		var level = int(lane / 7)
		var phase = float(line.get_meta("phase"))
		var x = fmod(elapsed * (4.0 + speed_factor * 4.2) + phase * 13.0 + float(level) * 1.7, 15.0) - 7.5
		var z = -2.65 + float(row) * 0.88
		var y = 0.05 + float(level) * 0.56
		var deflect = exp(-pow(x / 2.5, 2.0))
		y += sin(z * 1.8 + elapsed * 2.0) * 0.045 + deflect * (0.18 + abs(z) * 0.025)
		z += sin(x * 0.7 + float(row)) * deflect * 0.16
		line.translation = Vector3(x, y, z)
		line.visible = flow_enabled

	var q = pow(tunnel_speed / 220.0, 2.0)
	for i in range(sensor_values.size()):
		var pulse = sin(elapsed * 2.1 + float(i) * 0.83) * 24.0
		sensor_values[i] = 101325.0 + pressure_bias[i] * q + pulse
		var intensity = min(1.0, abs(sensor_values[i] - 101325.0) / 900.0)
		sensor_markers[i].scale = Vector3.ONE * (1.0 + intensity * 0.42 + sin(elapsed * 3.0 + i) * 0.06)
	update_readings(q)

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().size.x * 0.75:
			dragging = true
			drag_origin = event.position
			yaw_origin = yaw
			pitch_origin = pitch
		elif not event.pressed:
			dragging = false
	elif event is InputEventScreenDrag and dragging:
		orbit_from_delta(event.position - drag_origin)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed and event.position.x < get_viewport().size.x * 0.75:
			dragging = true
			drag_origin = event.position
			yaw_origin = yaw
			pitch_origin = pitch
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		orbit_from_delta(event.position - drag_origin)

func orbit_from_delta(delta):
	yaw = yaw_origin - delta.x * 0.006
	pitch = clamp(pitch_origin - delta.y * 0.004, -1.15, 0.18)
	update_camera()

func update_camera():
	var target = Vector3(0, 0.55, 0)
	var offset = Vector3(cos(pitch) * cos(yaw), sin(-pitch), cos(pitch) * sin(yaw)) * distance
	camera.translation = target + offset
	camera.look_at(target, Vector3.UP)

func speed_changed(value):
	tunnel_speed = value

func toggle_flow(button):
	flow_enabled = not flow_enabled
	button.text = "PAUSE AIRFLOW" if flow_enabled else "RESUME AIRFLOW"

func select_sensor(index):
	selected_sensor = index
	for i in range(sensor_buttons.size()):
		sensor_buttons[i].modulate = WHITE if i == index else Color(0.72, 0.80, 0.88, 1)

func set_view(new_yaw, new_pitch):
	yaw = new_yaw
	pitch = new_pitch
	update_camera()

func update_readings(q):
	if speed_value == null:
		return
	var selected = sensor_values[selected_sensor]
	var dp = selected - 101325.0
	speed_value.text = "%d km/h" % int(tunnel_speed)
	pressure_value.text = "%.3f kPa" % (selected / 1000.0)
	delta_value.text = "%+.2f kPa" % (dp / 1000.0)
	load_value.text = "%.2f ×" % q
	status_value.text = "480 Hz  •  Z%02d" % (selected_sensor + 1)

func part(mesh, position, mat, scale_value = Vector3.ONE):
	var node = MeshInstance.new()
	node.mesh = mesh
	node.material_override = mat
	node.translation = position
	node.scale = scale_value
	car.add_child(node)
	return node

func add_mesh(mesh, position, mat):
	var node = MeshInstance.new()
	node.mesh = mesh
	node.material_override = mat
	node.translation = position
	add_child(node)
	return node

func box_mesh(size):
	var mesh = CubeMesh.new()
	mesh.size = size
	return mesh

func sphere_mesh(radius, radial, rings):
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = radial
	mesh.rings = rings
	return mesh

func cylinder_mesh(radius, height, sides):
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	return mesh

func material(colour, roughness = 0.4, transparent = false):
	var mat = SpatialMaterial.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	if transparent:
		mat.flags_transparent = true
		mat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
		mat.flags_unshaded = true
	return mat

func simplify_model_materials(node):
	# The CC0 glTF carries desktop PBR materials. Preserve its five colour groups
	# while removing material features that exceed the target Vivante GLES2
	# shader-input budget.
	if node is MeshInstance:
		var colours = [Color("0050a5"), Color("07101f"), Color("08090b"), Color("d92f35"), Color("3c4148")]
		node.mesh = node.mesh.duplicate()
		for surface in range(node.mesh.get_surface_count()):
			var mat = SpatialMaterial.new()
			mat.albedo_color = colours[surface % colours.size()]
			mat.roughness = 0.72
			mat.metallic = 0.05
			mat.flags_vertex_lighting = true
			node.mesh.surface_set_material(surface, mat)
	for child in node.get_children():
		simplify_model_materials(child)

func text(value, size, colour, strong):
	var node = Label.new()
	node.text = value
	node.add_color_override("font_color", colour)
	node.add_font_override("font", make_font(size, strong))
	return node

func make_font(size, strong):
	var font = DynamicFont.new()
	font.size = size
	font.use_filter = true
	var data = DynamicFontData.new()
	data.font_path = "res://fonts/DejaVuSans-Bold.ttf" if strong else "res://fonts/DejaVuSans.ttf"
	font.font_data = data
	return font

func pill(value, colour, width):
	var panel = PanelContainer.new()
	panel.rect_min_size = Vector2(width, 50)
	panel.add_stylebox_override("panel", panel_style(Color(colour.r, colour.g, colour.b, 0.10), colour, 24, 1))
	var label = text(value, 14, colour, true)
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	panel.add_child(label)
	return panel

func action_button(value):
	var button = Button.new()
	button.text = value
	button.rect_min_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_font_override("font", make_font(13, true))
	button.add_color_override("font_color", WHITE)
	button.add_color_override("font_color_hover", NAVY)
	button.add_stylebox_override("normal", panel_style(PANEL_LIGHT, Color(0.16, 0.35, 0.50, 1), 7, 1))
	button.add_stylebox_override("hover", panel_style(CYAN, CYAN, 7, 1))
	button.add_stylebox_override("pressed", panel_style(BLUE, CYAN, 7, 2))
	return button

func metric_row(parent, name, value, colour):
	var row = HBoxContainer.new()
	row.rect_min_size.y = 36
	parent.add_child(row)
	row.add_child(text(name, 13, MUTED, true))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var reading = text(value, 18, colour, true)
	row.add_child(reading)
	return reading

func separator():
	var line = ColorRect.new()
	line.color = Color(0.20, 0.38, 0.52, 0.55)
	line.rect_min_size.y = 1
	return line

func panel_style(fill, border, radius, width):
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 13
	box.content_margin_right = 13
	return box

func set_margins(node, left, top, right, bottom):
	node.add_constant_override("margin_left", left)
	node.add_constant_override("margin_top", top)
	node.add_constant_override("margin_right", right)
	node.add_constant_override("margin_bottom", bottom)
