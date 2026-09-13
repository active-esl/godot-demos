extends Control

signal contact(position, index, pressed, source)
signal contact_drag(position, relative, index)

const BG = Color("071426")
const GRID = Color(0.15, 0.31, 0.45, 0.55)
const CYAN = Color("20d6d2")
const LIME = Color("b6f23b")
const AMBER = Color("ffb020")
const WHITE = Color("f5f8fc")

var mode = "grid"
var target = Vector2(-1, -1)
var contacts = {}
var trails = {}
var suppress_mouse_until = 0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func set_mode(value):
	mode = value
	contacts.clear()
	trails.clear()
	update()

func set_target(normalized):
	target = normalized
	update()

func clear_target():
	target = Vector2(-1, -1)
	update()

func clear_trace():
	contacts.clear()
	trails.clear()
	update()

func _gui_input(event):
	if event is InputEventScreenTouch:
		suppress_mouse_until = OS.get_ticks_msec() + 350
		if event.pressed:
			contacts[event.index] = event.position
			trails[event.index] = [event.position]
		else:
			contacts.erase(event.index)
		emit_signal("contact", event.position, event.index, event.pressed, "touch")
		accept_event()
		update()
	elif event is InputEventScreenDrag:
		suppress_mouse_until = OS.get_ticks_msec() + 350
		contacts[event.index] = event.position
		append_trail(event.index, event.position)
		emit_signal("contact_drag", event.position, event.relative, event.index)
		accept_event()
		update()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and OS.get_ticks_msec() >= suppress_mouse_until:
		if event.pressed:
			contacts[-1] = event.position
			trails[-1] = [event.position]
		else:
			contacts.erase(-1)
		emit_signal("contact", event.position, -1, event.pressed, "pointer")
		accept_event()
		update()
	elif event is InputEventMouseMotion and contacts.has(-1):
		contacts[-1] = event.position
		append_trail(-1, event.position)
		emit_signal("contact_drag", event.position, event.relative, -1)
		accept_event()
		update()

func append_trail(index, position):
	if not trails.has(index):
		trails[index] = []
	trails[index].append(position)
	if trails[index].size() > 160:
		trails[index].pop_front()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_size), BG)
	if mode == "colour":
		draw_colour_bars()
	elif mode == "geometry":
		draw_geometry()
	else:
		draw_grid()
	if target.x >= 0:
		draw_target(Vector2(target.x * rect_size.x, target.y * rect_size.y))
	for index in trails.keys():
		var points = PoolVector2Array(trails[index])
		if points.size() > 1:
			draw_polyline(points, CYAN, 4.0, true)
	for index in contacts.keys():
		var p = contacts[index]
		draw_circle(p, 36, Color(0.13, 0.84, 0.82, 0.22))
		draw_arc(p, 36, 0, TAU, 48, LIME, 4, true)
		draw_string(get_font("font"), p + Vector2(45, 7), "CONTACT %s  %.0f, %.0f" % [index, p.x, p.y], WHITE)

func draw_grid():
	for x in range(0, int(rect_size.x) + 1, 80):
		draw_line(Vector2(x, 0), Vector2(x, rect_size.y), GRID, 1)
	for y in range(0, int(rect_size.y) + 1, 80):
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), GRID, 1)
	for p in [Vector2(0, 0), Vector2(rect_size.x, 0), Vector2(0, rect_size.y), rect_size]:
		draw_circle(p, 18, AMBER)
	draw_line(Vector2(0, rect_size.y / 2), Vector2(rect_size.x, rect_size.y / 2), CYAN, 2)
	draw_line(Vector2(rect_size.x / 2, 0), Vector2(rect_size.x / 2, rect_size.y), CYAN, 2)

func draw_colour_bars():
	var colours = [Color.white, Color.yellow, Color.cyan, Color.green, Color.magenta, Color.red, Color.blue, Color.black]
	var width = rect_size.x / colours.size()
	for i in range(colours.size()):
		draw_rect(Rect2(i * width, 0, width + 1, rect_size.y * 0.72), colours[i])
	for i in range(16):
		var level = float(i) / 15.0
		draw_rect(Rect2(i * rect_size.x / 16.0, rect_size.y * 0.72, rect_size.x / 16.0 + 1, rect_size.y * 0.28), Color(level, level, level))

func draw_geometry():
	draw_grid()
	var inset = 24.0
	for i in range(6):
		var colour = CYAN if i % 2 == 0 else AMBER
		draw_rect(Rect2(inset + i * 28, inset + i * 28, rect_size.x - (inset + i * 28) * 2, rect_size.y - (inset + i * 28) * 2), colour, false, 3)
	var radius = min(rect_size.x, rect_size.y) * 0.26
	draw_circle(rect_size / 2, radius, Color(0.13, 0.84, 0.82, 0.12))
	draw_arc(rect_size / 2, radius, 0, TAU, 96, WHITE, 4, true)

func draw_target(position):
	draw_circle(position, 48, Color(0.71, 0.95, 0.23, 0.16))
	draw_arc(position, 48, 0, TAU, 64, LIME, 6, true)
	draw_line(position - Vector2(68, 0), position + Vector2(68, 0), LIME, 3)
	draw_line(position - Vector2(0, 68), position + Vector2(0, 68), LIME, 3)
