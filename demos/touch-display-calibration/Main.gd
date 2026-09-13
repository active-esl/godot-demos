extends Control

const NAVY = Color("071426")
const PANEL = Color("0d2038")
const PANEL_LIGHT = Color("15304f")
const WHITE = Color("f5f8fc")
const MUTED = Color("9aadc2")
const CYAN = Color("20d6d2")
const LIME = Color("b6f23b")
const AMBER = Color("ffb020")
const RED = Color("ff4d68")

var pages = []
var nav_buttons = []
var surface
var guided_status
var guided_detail
var live_status
var results_text
var generate_button
var samples = []
var target_index = 0
var active_contacts = {}
var max_contacts = 0
var drag_distance = 0.0
var pinch_observed = false
var last_pinch_distance = 0.0
var target_points = [Vector2(0.08, 0.10), Vector2(0.92, 0.10), Vector2(0.92, 0.90), Vector2(0.08, 0.90), Vector2(0.50, 0.50)]
var target_names = ["TOP LEFT", "TOP RIGHT", "BOTTOM RIGHT", "BOTTOM LEFT", "CENTRE"]

func _ready():
	build_ui()
	show_page(0)
	print("CALIBRATION_LAB_READY screen=%s window=%s controls=true" % [OS.get_screen_size(), OS.window_size])

func build_ui():
	var background = ColorRect.new()
	background.color = NAVY
	background.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var root = VBoxContainer.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.add_constant_override("separation", 0)
	add_child(root)
	root.add_child(build_header())
	var body = Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	pages = [build_display_page(), build_guided_page(), build_live_page(), build_results_page()]
	for page in pages:
		page.set_anchors_and_margins_preset(Control.PRESET_WIDE)
		body.add_child(page)

func build_header():
	var panel = PanelContainer.new()
	panel.rect_min_size.y = 112
	panel.add_stylebox_override("panel", box(NAVY, CYAN, 0, 2))
	var margin = MarginContainer.new()
	set_margins(margin, 34, 18, 34, 16)
	panel.add_child(margin)
	var row = HBoxContainer.new()
	row.add_constant_override("separation", 16)
	margin.add_child(row)
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(label("TOUCH + DISPLAY CALIBRATION LAB", 25, WHITE, true))
	title_box.add_child(label("GODOT 3  •  BSP-FIRST DIAGNOSTICS", 13, MUTED, true))
	row.add_child(title_box)
	for item in [["DISPLAY", 0], ["GUIDED TOUCH", 1], ["LIVE INPUT", 2], ["RESULTS", 3]]:
		var button = action_button(item[0], 180)
		button.connect("pressed", self, "show_page", [item[1]])
		row.add_child(button)
		nav_buttons.append(button)
	return panel

func build_display_page():
	var page = HBoxContainer.new()
	page.add_constant_override("separation", 18)
	var field = preload("res://CalibrationSurface.gd").new()
	field.name = "DisplayPattern"
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(field)
	var side = side_panel("DISPLAY VALIDATION", "Confirm scanout before calibrating touch.")
	page.add_child(side[0])
	var column = side[1]
	column.add_child(info_card("LOGICAL OUTPUT", "%d × %d" % [OS.window_size.x, OS.window_size.y], CYAN))
	column.add_child(info_card("PHYSICAL SCREEN", "%d × %d" % [OS.get_screen_size().x, OS.get_screen_size().y], WHITE))
	column.add_child(label("TEST PATTERNS", 14, MUTED, true))
	for item in [["GEOMETRY + OVERSCAN", "geometry"], ["COLOUR + GREYSCALE", "colour"], ["PIXEL GRID + AXES", "grid"]]:
		var button = action_button(item[0], 0)
		button.connect("pressed", field, "set_mode", [item[1]])
		column.add_child(button)
	column.add_child(note("Check readable orientation, equal circles, visible corner markers, full greyscale and RGB order. Correct panel scan, DRM orientation and compositor transform before touch."))
	return page

func build_guided_page():
	var page = VBoxContainer.new()
	page.add_constant_override("separation", 10)
	var status_row = HBoxContainer.new()
	guided_status = label("READY FOR FIVE-POINT CAPTURE", 20, LIME, true)
	guided_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(guided_status)
	guided_detail = label("Press START, then touch each displayed crosshair.", 15, MUTED, false)
	status_row.add_child(guided_detail)
	var start = action_button("START / RESET", 220)
	start.connect("pressed", self, "start_guided")
	status_row.add_child(start)
	page.add_child(status_row)
	surface = preload("res://CalibrationSurface.gd").new()
	surface.name = "GuidedTouchSurface"
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.connect("contact", self, "guided_contact")
	page.add_child(surface)
	return page

func build_live_page():
	var page = VBoxContainer.new()
	page.add_constant_override("separation", 10)
	var row = HBoxContainer.new()
	live_status = label("CONTACTS 0  •  MAX 0  •  DRAG 0 px  •  PINCH NOT SEEN", 18, WHITE, true)
	live_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(live_status)
	var clear = action_button("CLEAR TRACE", 190)
	row.add_child(clear)
	page.add_child(row)
	var live_surface = preload("res://CalibrationSurface.gd").new()
	live_surface.name = "LiveTouchSurface"
	live_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	live_surface.connect("contact", self, "live_contact")
	live_surface.connect("contact_drag", self, "live_drag")
	clear.connect("pressed", self, "clear_live", [live_surface])
	page.add_child(live_surface)
	return page

func build_results_page():
	var page = HBoxContainer.new()
	page.add_constant_override("separation", 18)
	var report_panel = PanelContainer.new()
	report_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_panel.add_stylebox_override("panel", box(PANEL, Color(0.16, 0.35, 0.50, 1), 12, 1))
	var margin = MarginContainer.new()
	set_margins(margin, 30, 28, 30, 28)
	report_panel.add_child(margin)
	results_text = RichTextLabel.new()
	results_text.name = "CalibrationReport"
	results_text.bbcode_enabled = true
	results_text.add_font_override("normal_font", font(17, false))
	results_text.add_font_override("bold_font", font(17, true))
	results_text.scroll_active = true
	margin.add_child(results_text)
	page.add_child(report_panel)
	var side = side_panel("CORRECTION POLICY", "Fix coordinates below the application.")
	page.add_child(side[0])
	var column = side[1]
	column.add_child(layer_card("1  DEVICE TREE", "Preferred for fixed panel mounting: generic touchscreen inversion/swap properties."))
	column.add_child(layer_card("2  DRIVER", "Only when axis ranges, scaling or controller reporting are genuinely wrong/non-linear."))
	column.add_child(layer_card("3  LIBINPUT", "Optional generated udev matrix for compositor-specific deployment or hot validation."))
	column.add_child(layer_card("4  APPLICATION", "Last resort only. Never hide a reusable BSP defect in Godot, Qt or Flutter."))
	generate_button = action_button("COPY OPTIONAL UDEV RULE", 0)
	generate_button.connect("pressed", self, "copy_udev_rule")
	column.add_child(generate_button)
	var rerun = action_button("RUN GUIDED TEST", 0)
	rerun.connect("pressed", self, "show_and_start_guided")
	column.add_child(rerun)
	update_results()
	return page

func show_page(index):
	for i in range(pages.size()):
		pages[i].visible = i == index
	for i in range(nav_buttons.size()):
		nav_buttons[i].modulate = LIME if i == index else WHITE
	if index == 3:
		update_results()

func show_and_start_guided():
	show_page(1)
	start_guided()

func start_guided():
	samples.clear()
	target_index = 0
	surface.clear_trace()
	surface.set_target(target_points[0])
	guided_status.text = "TARGET 1 OF 5  •  " + target_names[0]
	guided_detail.text = "Touch the centre of the crosshair, then lift."
	print("CALIBRATION_CAPTURE_STARTED")

func guided_contact(position, index, pressed, source):
	if not pressed or target_index >= target_points.size():
		return
	var actual = Vector2(position.x / surface.rect_size.x, position.y / surface.rect_size.y)
	samples.append({"expected": target_points[target_index], "actual": actual, "source": source})
	print("CALIBRATION_SAMPLE target=%s expected=(%.4f,%.4f) actual=(%.4f,%.4f)" % [target_names[target_index], target_points[target_index].x, target_points[target_index].y, actual.x, actual.y])
	target_index += 1
	if target_index < target_points.size():
		surface.set_target(target_points[target_index])
		guided_status.text = "TARGET %d OF 5  •  %s" % [target_index + 1, target_names[target_index]]
	else:
		surface.clear_target()
		guided_status.text = "CAPTURE COMPLETE"
		guided_detail.text = "Results identify the lowest appropriate correction layer."
		update_results()
		show_page(3)

func live_contact(position, index, pressed, source):
	if pressed:
		active_contacts[index] = position
	else:
		active_contacts.erase(index)
	max_contacts = max(max_contacts, active_contacts.size())
	update_live_status()

func live_drag(position, relative, index):
	active_contacts[index] = position
	drag_distance += relative.length()
	if active_contacts.size() >= 2:
		var values = active_contacts.values()
		var distance = values[0].distance_to(values[1])
		if last_pinch_distance > 0 and abs(distance - last_pinch_distance) > 4:
			pinch_observed = true
		last_pinch_distance = distance
	update_live_status()

func clear_live(live_surface):
	active_contacts.clear()
	max_contacts = 0
	drag_distance = 0
	pinch_observed = false
	last_pinch_distance = 0
	live_surface.clear_trace()
	update_live_status()

func update_live_status():
	live_status.text = "CONTACTS %d  •  MAX %d  •  DRAG %.0f px  •  PINCH %s" % [active_contacts.size(), max_contacts, drag_distance, "SEEN" if pinch_observed else "NOT SEEN"]

func transformed(point, mode):
	match mode:
		"invert_x": return Vector2(1.0 - point.x, point.y)
		"invert_y": return Vector2(point.x, 1.0 - point.y)
		"invert_xy": return Vector2(1.0 - point.x, 1.0 - point.y)
		"swap": return Vector2(point.y, point.x)
		"swap_invert_x": return Vector2(1.0 - point.y, point.x)
		"swap_invert_y": return Vector2(point.y, 1.0 - point.x)
		"swap_invert_xy": return Vector2(1.0 - point.y, 1.0 - point.x)
	return point

func analyse():
	if samples.size() < target_points.size():
		return {"ready": false}
	var modes = ["identity", "invert_x", "invert_y", "invert_xy", "swap", "swap_invert_x", "swap_invert_y", "swap_invert_xy"]
	var best_mode = "identity"
	var best_error = 999.0
	for mode in modes:
		var error = 0.0
		for sample in samples:
			error += transformed(sample.actual, mode).distance_to(sample.expected)
		error /= samples.size()
		if error < best_error:
			best_error = error
			best_mode = mode
	return {"ready": true, "mode": best_mode, "error": best_error, "properties": dts_properties(best_mode), "matrix": udev_matrix(best_mode)}

func dts_properties(mode):
	var lines = []
	if "swap" in mode:
		lines.append("touchscreen-swapped-x-y;")
	if mode == "invert_x" or mode == "invert_xy" or mode == "swap_invert_x" or mode == "swap_invert_xy":
		lines.append("touchscreen-inverted-x;")
	if mode == "invert_y" or mode == "invert_xy" or mode == "swap_invert_y" or mode == "swap_invert_xy":
		lines.append("touchscreen-inverted-y;")
	return lines

func udev_matrix(mode):
	match mode:
		"invert_x": return "-1 0 1 0 1 0"
		"invert_y": return "1 0 0 0 -1 1"
		"invert_xy": return "-1 0 1 0 -1 1"
		"swap": return "0 1 0 1 0 0"
		"swap_invert_x": return "0 -1 1 1 0 0"
		"swap_invert_y": return "0 1 0 -1 0 1"
		"swap_invert_xy": return "0 -1 1 -1 0 1"
	return "1 0 0 0 1 0"

func update_results():
	if results_text == null:
		return
	var result = analyse()
	if not result.ready:
		results_text.bbcode_text = "[font=res://fonts/DejaVuSans-Bold.ttf][color=#20d6d2]NO COMPLETE CAPTURE YET[/color][/font]\n\nRun the guided five-point test. The tool will compare where each target is drawn with where the platform reports your touch.\n\n[b]Live environment[/b]\nLogical window: %d × %d\nPhysical screen: %d × %d\nAspect: %.3f\n\n[b]Interpretation policy[/b]\n• Constant axis reversal/swap → describe fixed mounting in Device Tree.\n• Wrong raw ranges or non-linear residual → inspect controller driver and electrical data.\n• Correct kernel coordinates but wrong compositor surface → use compositor/output mapping; generate a libinput rule only when necessary.\n• Never compensate separately in each application." % [OS.window_size.x, OS.window_size.y, OS.get_screen_size().x, OS.get_screen_size().y, OS.window_size.x / max(1.0, OS.window_size.y)]
		return
	var quality = "GOOD" if result.error < 0.035 else ("MARGINAL" if result.error < 0.08 else "NON-LINEAR / WRONG RANGE")
	var props = "(none — identity mapping)" if result.properties.empty() else "\n    ".join(result.properties)
	results_text.bbcode_text = "[color=#b6f23b][b]CAPTURE COMPLETE[/b][/color]\n\n[b]Best transform[/b]  %s\n[b]Mean normalized residual[/b]  %.4f\n[b]Fit quality[/b]  %s\n\n[color=#20d6d2][b]PREFERRED: DEVICE TREE[/b][/color]\nAdd these generic touchscreen properties to the panel controller node, rebuild the DTB, then repeat this test:\n\n    %s\n\nDo not add application rotation. These properties are consumed by the Linux touchscreen core and apply consistently to Godot, Qt, Flutter and desktop compositors.\n\n[color=#ffb020][b]OPTIONAL HOT VALIDATION: LIBINPUT[/b][/color]\nMatrix: %s\n\nIf residual remains high after the discrete transform, verify touchscreen-size-x/y, raw min/max, edge linearity and controller firmware before changing the application." % [result.mode.to_upper(), result.error, quality, props, result.matrix]
	print("CALIBRATION_RESULT mode=%s residual=%.5f dts=%s matrix=%s" % [result.mode, result.error, result.properties, result.matrix])

func copy_udev_rule():
	var result = analyse()
	if not result.ready:
		return
	var rule = "SUBSYSTEM==\"input\", KERNEL==\"event*\", ATTRS{name}==\"<touch-device-name>\", ENV{WL_OUTPUT}=\"<output-name>\", ENV{LIBINPUT_CALIBRATION_MATRIX}=\"%s\"" % result.matrix
	OS.set_clipboard(rule)
	generate_button.text = "COPIED — VALIDATE BEFORE INSTALL"

func side_panel(title, subtitle):
	var panel = PanelContainer.new()
	panel.rect_min_size.x = 430
	panel.add_stylebox_override("panel", box(PANEL, Color(0.16, 0.35, 0.50, 1), 12, 1))
	var margin = MarginContainer.new()
	set_margins(margin, 26, 26, 26, 26)
	panel.add_child(margin)
	var column = VBoxContainer.new()
	column.add_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(label(title, 22, WHITE, true))
	column.add_child(label(subtitle, 14, MUTED, false))
	return [panel, column]

func info_card(name, value, colour):
	var panel = PanelContainer.new()
	panel.add_stylebox_override("panel", box(PANEL_LIGHT, Color(0.16, 0.35, 0.50, 1), 8, 1))
	var row = HBoxContainer.new()
	row.rect_min_size.y = 58
	panel.add_child(row)
	row.add_child(label("  " + name, 13, MUTED, true))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(label(value + "  ", 20, colour, true))
	return panel

func layer_card(title, body):
	var panel = PanelContainer.new()
	panel.add_stylebox_override("panel", box(PANEL_LIGHT, Color(0.16, 0.35, 0.50, 1), 8, 1))
	var margin = MarginContainer.new()
	set_margins(margin, 16, 13, 16, 13)
	panel.add_child(margin)
	var column = VBoxContainer.new()
	column.add_child(label(title, 14, CYAN, true))
	var body_label = label(body, 13, MUTED, false)
	body_label.autowrap = true
	column.add_child(body_label)
	margin.add_child(column)
	return panel

func note(value):
	var node = label(value, 14, MUTED, false)
	node.autowrap = true
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node

func action_button(value, width):
	var button = Button.new()
	button.text = value
	button.rect_min_size = Vector2(width, 52)
	button.add_font_override("font", font(13, true))
	button.add_color_override("font_color", WHITE)
	button.add_color_override("font_color_hover", NAVY)
	button.add_stylebox_override("normal", box(PANEL_LIGHT, Color(0.16, 0.35, 0.50, 1), 7, 1))
	button.add_stylebox_override("hover", box(CYAN, CYAN, 7, 1))
	button.add_stylebox_override("pressed", box(Color("2c72ff"), CYAN, 7, 2))
	return button

func label(value, size, colour, strong):
	var node = Label.new()
	node.text = value
	node.add_font_override("font", font(size, strong))
	node.add_color_override("font_color", colour)
	return node

func font(size, strong):
	var result = DynamicFont.new()
	result.size = size
	result.use_filter = true
	var data = DynamicFontData.new()
	data.font_path = "res://fonts/DejaVuSans-Bold.ttf" if strong else "res://fonts/DejaVuSans.ttf"
	result.font_data = data
	return result

func box(fill, border, radius, width):
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func set_margins(node, left, top, right, bottom):
	node.add_constant_override("margin_left", left)
	node.add_constant_override("margin_top", top)
	node.add_constant_override("margin_right", right)
	node.add_constant_override("margin_bottom", bottom)
