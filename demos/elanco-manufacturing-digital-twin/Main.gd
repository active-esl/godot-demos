extends Control

# Touch-first demonstrator: every UI element is a Control node. Values are simulated.
const NAMES = ["PROCESS", "ASSET", "QUALITY"]
const INK = Color("172033")
const MUTED = Color("657087")
const PAPER = Color("f4f6f8")
const WHITE = Color("ffffff")
const PURPLE = Color("5b2b82")
const DARK = Color("35164f")
const AQUA = Color("00a6a6")
const GREEN = Color("57a773")
const AMBER = Color("f3a712")
const BLUE = Color("2878b5")
const LINE = Color("d8dee8")

var regular
var bold
var pages = []
var nav = []
var live = {}
var page = 0
var elapsed = 0.0
var batch = 64.0
var mixing = true
var drag_start = Vector2()
var dragging = false
var process_liquids = []
var process_agitators = []
var process_bubbles = []
var process_vials = []

func _ready():
	regular = load("res://fonts/DejaVuSans.ttf")
	bold = load("res://fonts/DejaVuSans-Bold.ttf")
	build_ui()
	show_page(0)
	print("ELANCO_TWIN_READY screen=%s window=%s controls=true" % [OS.get_screen_size(), OS.window_size])

func build_ui():
	add_child(rect(PAPER, true))
	var shell = VBoxContainer.new()
	shell.set_anchors_and_margins_preset(PRESET_WIDE)
	shell.add_constant_override("separation", 0)
	add_child(shell)
	shell.add_child(header())
	var margin = MarginContainer.new()
	margins(margin, 52, 30, 52, 28)
	margin.size_flags_vertical = SIZE_EXPAND_FILL
	shell.add_child(margin)
	var stack = Control.new()
	stack.size_flags_horizontal = SIZE_EXPAND_FILL
	stack.size_flags_vertical = SIZE_EXPAND_FILL
	margin.add_child(stack)
	pages = [process_page(), asset_page(), quality_page()]
	for child in pages:
		child.set_anchors_and_margins_preset(PRESET_WIDE)
		stack.add_child(child)
	shell.add_child(navigation())

func header():
	var panel = PanelContainer.new()
	panel.rect_min_size.y = 142
	panel.add_stylebox_override("panel", style(WHITE, 0, PURPLE, 0, 0, 4))
	var margin = MarginContainer.new()
	margins(margin, 52, 24, 52, 20)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_constant_override("separation", 28)
	margin.add_child(row)
	var mark = HBoxContainer.new()
	mark.add_constant_override("separation", 5)
	for colour in [AMBER, GREEN, AQUA]:
		var stripe = rect(colour)
		stripe.rect_min_size = Vector2(12, 70)
		mark.add_child(stripe)
	row.add_child(mark)
	row.add_child(label("elanco", 46, DARK, true))
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_child(label("MANUFACTURING DIGITAL TWIN", 29, INK, true))
	titles.add_child(label("CONCEPT DEMONSTRATION  •  SIMULATED DATA", 17, MUTED))
	row.add_child(titles)
	row.add_child(pill("●  LINE HEALTHY", GREEN, 270))
	return panel

func page_shell(title, subtitle):
	var view = VBoxContainer.new()
	view.add_constant_override("separation", 22)
	view.add_child(label(title, 36, DARK, true))
	view.add_child(label(subtitle, 19, MUTED))
	var body = VBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_constant_override("separation", 22)
	view.add_child(body)
	return view

func process_page():
	var view = page_shell("Speke Site  •  Batch A24-0902", "Live process overview — select an asset for detail")
	var body = view.get_node("Body")
	var cards = HBoxContainer.new()
	cards.size_flags_vertical = SIZE_EXPAND_FILL
	cards.add_constant_override("separation", 28)
	body.add_child(cards)
	cards.add_child(process_card(0, "RAW MATERIAL", "Feed vessel V-101", "LEVEL", "%", AQUA))
	cards.add_child(process_card(1, "BIOREACTOR", "Reactor R-204", "TEMPERATURE", "°C", PURPLE))
	cards.add_child(process_card(2, "FILL & FINISH", "Line FL-03", "THROUGHPUT", "VIALS/MIN", BLUE))
	var strip = HBoxContainer.new()
	strip.rect_min_size.y = 112
	strip.add_constant_override("separation", 22)
	body.add_child(strip)
	for item in [["BATCH COMPLETE", "64%", "batch"], ["QUALITY SCORE", "98.7%", "quality"], ["OEE", "91.4%", "oee"], ["NEXT SAMPLE", "08:42", "sample"]]:
		var card = metric(item[0], item[1])
		strip.add_child(card)
		live[item[2]] = card.get_node("Margin/Content/Value")
	return view

func process_card(index, title, subtitle, metric_name, unit, accent):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_stylebox_override("panel", style(WHITE, 10, accent, 7))
	var margin = MarginContainer.new()
	margins(margin, 28, 24, 28, 22)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(label(title, 23, DARK, true))
	box.add_child(label(subtitle, 18, MUTED))
	box.add_child(machine(index, accent, "process"))
	box.add_child(label(metric_name, 15, MUTED, true))
	var value_row = HBoxContainer.new()
	var value = label("--", 35, DARK, true)
	value_row.add_child(value)
	var units = label("  " + unit, 15, MUTED, true)
	units.size_flags_vertical = SIZE_SHRINK_END
	value_row.add_child(units)
	box.add_child(value_row)
	var bar = progress(accent, 20)
	box.add_child(bar)
	var button = button("VIEW ASSET DETAILS  →", false)
	button.connect("pressed", self, "show_page", [1])
	box.add_child(button)
	live["value%d" % index] = value
	live["gauge%d" % index] = bar
	return panel

func machine(kind, accent, scope = ""):
	var frame = CenterContainer.new()
	frame.rect_min_size.y = 230
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	var machine = Control.new()
	machine.rect_min_size = Vector2(280, 210)
	frame.add_child(machine)
	if kind < 2:
		machine.add_child(at(rect(Color("e4edf1")), 55, 14, 170, 165))
		var liquid = at(rect(Color(accent.r, accent.g, accent.b, 0.42)), 67, 102, 146, 65)
		liquid.set_meta("kind", kind)
		machine.add_child(liquid)
		machine.add_child(at(rect(PURPLE), 134, 0, 12, 135))
		machine.add_child(at(rect(INK), 42, 179, 196, 14))
		machine.add_child(at(rect(INK), 65, 193, 12, 17))
		machine.add_child(at(rect(INK), 203, 193, 12, 17))
		if kind == 1:
			var agitator = at(rect(accent), 90, 129, 100, 12)
			agitator.rect_pivot_offset = Vector2(50, 6)
			machine.add_child(agitator)
			if scope == "process":
				process_agitators.append(agitator)
			else:
				live["asset_agitator"] = agitator
		if scope == "process":
			process_liquids.append(liquid)
			for phase in [0.0, 0.33, 0.66]:
				var bubble = at(rect(Color(1, 1, 1, 0.72)), 86 + int(phase * 105), 142, 9, 9)
				bubble.set_meta("phase", phase)
				bubble.set_meta("kind", kind)
				machine.add_child(bubble)
				process_bubbles.append(bubble)
	else:
		machine.add_child(at(rect(INK), 20, 164, 240, 16))
		machine.add_child(at(rect(PURPLE), 75, 20, 130, 72))
		var vial_index = 0
		for x in [32, 87, 142, 197]:
			var vial = at(Control.new(), x, 103, 25, 61)
			vial.add_child(at(rect(AQUA), 4, 0, 17, 9))
			vial.add_child(at(rect(Color("c9e7eb")), 0, 9, 25, 52))
			vial.set_meta("phase", float(vial_index) * 55.0)
			machine.add_child(vial)
			if scope == "process":
				process_vials.append(vial)
			vial_index += 1
	return frame

func asset_page():
	var view = page_shell("Reactor R-204", "Live asset detail — adjust the setpoint or agitator")
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_constant_override("separation", 28)
	view.get_node("Body").add_child(columns)
	var asset = section(500)
	var abox = asset.get_node("Margin/Content")
	abox.add_child(label("LIVE DIGITAL ASSET", 18, MUTED, true))
	abox.add_child(machine(1, AQUA, "asset"))
	var state = pill("AGITATOR  •  RUNNING", GREEN, 350)
	abox.add_child(state)
	live["state"] = state.get_node("Text")
	columns.add_child(asset)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_constant_override("separation", 22)
	columns.add_child(right)
	var conditions = section(0)
	conditions.size_flags_vertical = SIZE_EXPAND_FILL
	var cbox = conditions.get_node("Margin/Content")
	cbox.add_child(label("PROCESS CONDITIONS  •  LAST 30 MIN", 18, MUTED, true))
	cbox.add_child(condition("TEMPERATURE", "37.2 °C", PURPLE, "temperature", 82))
	cbox.add_child(condition("PRESSURE", "1.82 bar", AQUA, "pressure", 61))
	cbox.add_child(condition("AGITATOR SPEED", "420 rpm", BLUE, "speed", 70))
	cbox.add_child(condition("DISSOLVED OXYGEN", "46.8%", GREEN, "oxygen", 47))
	right.add_child(conditions)
	var controls = section(0)
	var ctrl = controls.get_node("Margin/Content")
	var row = HBoxContainer.new()
	row.add_child(label("TEMPERATURE SETPOINT", 18, MUTED, true))
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	var setpoint = label("37.0 °C", 28, DARK, true)
	row.add_child(setpoint)
	ctrl.add_child(row)
	var slider = HSlider.new()
	slider.min_value = 32
	slider.max_value = 42
	slider.step = 0.1
	slider.value = 37
	slider.rect_min_size.y = 52
	slider.connect("value_changed", self, "setpoint_changed")
	ctrl.add_child(slider)
	var toggle = button("PAUSE AGITATOR", true)
	toggle.connect("pressed", self, "toggle_mixing")
	ctrl.add_child(toggle)
	live["setpoint"] = setpoint
	live["slider"] = slider
	live["toggle"] = toggle
	right.add_child(controls)
	return view

func condition(title, value, accent, key, initial):
	var box = VBoxContainer.new()
	var row = HBoxContainer.new()
	row.add_child(label(title, 16, INK, true))
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	var reading = label(value, 19, accent, true)
	row.add_child(reading)
	box.add_child(row)
	var bar = progress(accent, 17)
	bar.value = initial
	box.add_child(bar)
	live[key] = reading
	live[key + "_bar"] = bar
	return box

func quality_page():
	var view = page_shell("Quality & Resource Performance", "Manufacturing insight — simulated site data")
	var body = view.get_node("Body")
	var kpis = HBoxContainer.new()
	kpis.rect_min_size.y = 180
	kpis.add_constant_override("separation", 20)
	body.add_child(kpis)
	for item in [["RIGHT FIRST TIME", "98.7%", "+0.8%", GREEN], ["ENERGY / BATCH", "1.42 MWh", "−6.2%", AQUA], ["WATER / BATCH", "18.6 m³", "−4.1%", BLUE], ["BATCH YIELD", "96.8%", "+1.3%", PURPLE]]:
		kpis.add_child(kpi(item[0], item[1], item[2], item[3]))
	var lower = HBoxContainer.new()
	lower.size_flags_vertical = SIZE_EXPAND_FILL
	lower.add_constant_override("separation", 28)
	body.add_child(lower)
	var gates = section(0)
	gates.size_flags_horizontal = SIZE_EXPAND_FILL
	var gbox = gates.get_node("Margin/Content")
	gbox.add_child(label("BATCH QUALITY GATE", 21, DARK, true))
	gbox.add_child(gate("Identity & potency", 99, GREEN))
	gbox.add_child(gate("Sterility assurance", 97, GREEN))
	gbox.add_child(gate("Fill-weight conformity", 94, AQUA))
	lower.add_child(gates)
	var insights = section(610)
	var ibox = insights.get_node("Margin/Content")
	ibox.add_child(label("OPERATIONAL INSIGHT", 21, DARK, true))
	ibox.add_child(insight("IN CONTROL", "All critical parameters within limits", GREEN))
	ibox.add_child(insight("WATCH", "CIP water use trending above plan", AMBER))
	ibox.add_child(insight("OPPORTUNITY", "Optimise rinse stage 3", AQUA))
	lower.add_child(insights)
	return view

func navigation():
	var panel = PanelContainer.new()
	panel.rect_min_size.y = 112
	panel.add_stylebox_override("panel", style(WHITE, 0, LINE, 0, 3))
	var margin = MarginContainer.new()
	margins(margin, 250, 17, 250, 17)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_constant_override("separation", 20)
	margin.add_child(row)
	for i in range(NAMES.size()):
		var item = button(NAMES[i], false)
		item.size_flags_horizontal = SIZE_EXPAND_FILL
		item.connect("pressed", self, "show_page", [i])
		row.add_child(item)
		nav.append(item)
	return panel

func section(width):
	var panel = PanelContainer.new()
	panel.rect_min_size.x = width
	panel.add_stylebox_override("panel", style(WHITE, 10))
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margins(margin, 27, 24, 27, 24)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.name = "Content"
	box.add_constant_override("separation", 18)
	margin.add_child(box)
	return panel

func metric(title, value):
	var panel = section(0)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var box = panel.get_node("Margin/Content")
	box.add_child(label(title, 15, MUTED, true))
	var reading = label(value, 29, DARK, true)
	reading.name = "Value"
	box.add_child(reading)
	return panel

func kpi(title, value, change, accent):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_stylebox_override("panel", style(WHITE, 10, accent, 8))
	var margin = MarginContainer.new()
	margins(margin, 24, 20, 24, 18)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_child(label(title, 15, MUTED, true))
	box.add_child(label(value, 30, DARK, true))
	box.add_child(label(change + " VS PLAN", 16, accent, true))
	margin.add_child(box)
	return panel

func gate(title, value, accent):
	var box = VBoxContainer.new()
	var row = HBoxContainer.new()
	row.add_child(label(title, 18, INK))
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(label("%d%%" % value, 18, accent, true))
	box.add_child(row)
	var bar = progress(accent, 20)
	bar.value = value
	box.add_child(bar)
	return box

func insight(state, detail, accent):
	var panel = PanelContainer.new()
	panel.add_stylebox_override("panel", style(Color(accent.r, accent.g, accent.b, 0.10), 8))
	var margin = MarginContainer.new()
	margins(margin, 17, 13, 17, 13)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.add_child(label("●  " + state, 15, accent, true))
	box.add_child(label(detail, 17, INK))
	margin.add_child(box)
	return panel

func label(text, size, colour, heavy = false):
	var node = Label.new()
	node.text = text
	var font = DynamicFont.new()
	font.font_data = bold if heavy else regular
	font.size = size
	font.use_filter = true
	node.add_font_override("font", font)
	node.add_color_override("font_color", colour)
	node.mouse_filter = MOUSE_FILTER_IGNORE
	return node

func button(text, primary):
	var node = Button.new()
	node.text = text
	node.rect_min_size.y = 58
	var font = DynamicFont.new()
	font.font_data = bold
	font.size = 17
	node.add_font_override("font", font)
	node.add_color_override("font_color", WHITE if primary else PURPLE)
	node.add_color_override("font_color_hover", WHITE if primary else DARK)
	node.add_stylebox_override("normal", style(PURPLE if primary else Color("edf0f5"), 8))
	node.add_stylebox_override("hover", style(DARK if primary else Color("e2e7ee"), 8))
	node.add_stylebox_override("pressed", style(AQUA, 8))
	return node

func pill(text, colour, width):
	var panel = PanelContainer.new()
	panel.rect_min_size = Vector2(width, 58)
	panel.add_stylebox_override("panel", style(colour, 29))
	var caption = label(text, 17, WHITE, true)
	caption.name = "Text"
	caption.align = Label.ALIGN_CENTER
	caption.valign = Label.VALIGN_CENTER
	panel.add_child(caption)
	return panel

func progress(colour, height):
	var bar = ProgressBar.new()
	bar.rect_min_size.y = height
	bar.percent_visible = false
	bar.add_stylebox_override("bg", style(Color("e9edf2"), 7))
	bar.add_stylebox_override("fg", style(colour, 7))
	return bar

func rect(colour, full = false):
	var node = ColorRect.new()
	node.color = colour
	node.mouse_filter = MOUSE_FILTER_IGNORE
	if full:
		node.set_anchors_and_margins_preset(PRESET_WIDE)
	return node

func at(node, x, y, width, height):
	node.rect_position = Vector2(x, y)
	node.rect_size = Vector2(width, height)
	return node

func style(colour, radius, border = Color(0, 0, 0, 0), left = 0, top = 0, bottom = 0):
	var box = StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border
	box.border_width_left = left
	box.border_width_top = top
	box.border_width_bottom = bottom
	return box

func margins(node, left, top, right, bottom):
	node.add_constant_override("margin_left", left)
	node.add_constant_override("margin_top", top)
	node.add_constant_override("margin_right", right)
	node.add_constant_override("margin_bottom", bottom)

func show_page(index):
	page = int(clamp(index, 0, pages.size() - 1))
	for i in range(pages.size()):
		pages[i].visible = i == page
	for i in range(nav.size()):
		var active = i == page
		nav[i].add_color_override("font_color", WHITE if active else MUTED)
		nav[i].add_stylebox_override("normal", style(PURPLE if active else Color("edf0f5"), 8))

func setpoint_changed(value):
	live["setpoint"].text = "%.1f °C" % value

func toggle_mixing():
	mixing = not mixing
	live["toggle"].text = "PAUSE AGITATOR" if mixing else "START AGITATOR"
	live["state"].text = "AGITATOR  •  RUNNING" if mixing else "AGITATOR  •  PAUSED"

func _process(delta):
	elapsed += delta
	if mixing:
		batch = fmod(batch + delta * 0.16, 100.0)
		live["asset_agitator"].rect_rotation = fmod(elapsed * 110.0, 360.0)
		for agitator in process_agitators:
			agitator.rect_rotation = fmod(elapsed * 150.0, 360.0)
	var level = 72.0 + sin(elapsed * 0.45) * 2.0
	var temperature = live["slider"].value + sin(elapsed * 0.7) * 0.3
	var throughput = 118.0 + sin(elapsed * 0.8) * 4.0
	process_value(0, level, 100.0, "%.1f" % level)
	process_value(1, temperature, 45.0, "%.1f" % temperature)
	process_value(2, throughput, 150.0, "%.0f" % throughput)
	live["batch"].text = "%d%%" % int(batch)
	live["temperature"].text = "%.1f °C" % temperature
	live["temperature_bar"].value = temperature / 45.0 * 100.0
	live["pressure"].text = "%.2f bar" % (1.82 + sin(elapsed * 0.45) * 0.04)
	live["speed"].text = "%d rpm" % (420 if mixing else 0)
	live["speed_bar"].value = 70 if mixing else 0
	live["oxygen"].text = "%.1f%%" % (46.8 + sin(elapsed * 0.31) * 1.2)
	animate_process_machinery(level)

func animate_process_machinery(level):
	for liquid in process_liquids:
		var fraction = level / 100.0 if liquid.get_meta("kind") == 0 else 0.66 + sin(elapsed * 0.55) * 0.035
		var height = 145.0 * fraction
		liquid.rect_position.y = 167.0 - height
		liquid.rect_size.y = height
	for bubble in process_bubbles:
		var phase = bubble.get_meta("phase")
		var direction = -1.0 if bubble.get_meta("kind") == 1 else 1.0
		var travel = fmod(elapsed * 0.34 + phase, 1.0)
		bubble.rect_position.y = 42.0 + (travel if direction > 0 else 1.0 - travel) * 105.0
		bubble.modulate.a = sin(travel * PI)
	for vial in process_vials:
		vial.rect_position.x = 25.0 + fmod(elapsed * 48.0 + vial.get_meta("phase"), 220.0)

func process_value(index, value, maximum, text):
	live["value%d" % index].text = text
	live["gauge%d" % index].value = value / maximum * 100.0

func _input(event):
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		if event.pressed:
			dragging = true
			drag_start = event.position
		elif dragging:
			var movement = event.position - drag_start
			dragging = false
			if abs(movement.x) > 140 and abs(movement.x) > abs(movement.y) * 1.4:
				show_page(page + 1 if movement.x < 0 else page - 1)
