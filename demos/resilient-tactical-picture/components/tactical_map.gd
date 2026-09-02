extends Control

signal node_selected(node_id)

const INK := Color("dce9e6")
const MUTED := Color("718582")
const GRID := Color("173632")
const GREEN := Color("55e6a5")
const AMBER := Color("ffbf69")
const RED := Color("ff5d62")
const CYAN := Color("63d9ff")

var nodes := []
var links := []
var route := {}
var selected_id := ""
var source_id := ""
var destination_id := ""
var profile := "uk"
var font: DynamicFont
var small_font: DynamicFont
var ui_scale := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf")
	font.size = 18
	small_font = DynamicFont.new()
	small_font.font_data = load("res://fonts/DejaVuSans.ttf")
	small_font.size = 14

func set_ui_scale(new_scale: float) -> void:
	ui_scale = max(1.0, new_scale)
	font.size = int(round(18.0 * ui_scale))
	small_font.size = int(round(14.0 * ui_scale))
	update()

func configure(new_nodes: Array, new_links: Array, new_route: Dictionary, new_selected: String, new_source: String, new_destination: String, new_profile: String) -> void:
	nodes = new_nodes
	links = new_links
	route = new_route
	selected_id = new_selected
	source_id = new_source
	destination_id = new_destination
	profile = new_profile
	update()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color("0a0e0d"), true)
	_draw_grid()
	_draw_site()
	_draw_links()
	for item in nodes:
		_draw_node(item)
	_draw_legend()

func _draw_grid() -> void:
	var spacing := int(round(80.0 * ui_scale))
	for x in range(0, int(rect_size.x), spacing):
		draw_line(Vector2(x, 0), Vector2(x, rect_size.y), GRID, 1.0)
	for y in range(0, int(rect_size.y), spacing):
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), GRID, 1.0)

func _draw_site() -> void:
	var structure := PoolVector2Array([
		Vector2(rect_size.x * 0.52, rect_size.y * 0.16), Vector2(rect_size.x * 0.79, rect_size.y * 0.16),
		Vector2(rect_size.x * 0.79, rect_size.y * 0.49), Vector2(rect_size.x * 0.52, rect_size.y * 0.49)
	])
	draw_colored_polygon(structure, Color("102622"))
	for i in range(structure.size()):
		draw_line(structure[i], structure[(i + 1) % structure.size()], Color("37645c"), 3.0)
	var restricted := PoolVector2Array([
		Vector2(rect_size.x * 0.07, rect_size.y * 0.17), Vector2(rect_size.x * 0.37, rect_size.y * 0.09),
		Vector2(rect_size.x * 0.43, rect_size.y * 0.37), Vector2(rect_size.x * 0.13, rect_size.y * 0.45)
	])
	draw_colored_polygon(restricted, Color("321c1d70"))
	for i in range(restricted.size()):
		draw_line(restricted[i], restricted[(i + 1) % restricted.size()], Color("8f4244"), 2.0)
	draw_string(font, Vector2(rect_size.x * 0.57, rect_size.y * 0.22), "STRUCTURE B-12" if profile == "uk" else "BÂTIMENT B-12", MUTED)
	draw_string(font, Vector2(rect_size.x * 0.13, rect_size.y * 0.27), "RESTRICTED" if profile == "uk" else "ZONE RESTREINTE", Color("bf6d70"))

func _draw_links() -> void:
	var route_links: Array = route.link_ids if route.has("link_ids") else []
	for link in links:
		var start := _node_screen(link.from)
		var finish := _node_screen(link.to)
		var on_route := route_links.has(link.id)
		var color := CYAN if on_route else Color("41615b")
		var width := 5.0 * ui_scale if on_route else 2.0 * ui_scale
		if link.status == "offline":
			color = RED
			draw_dashed_line(start, finish, color, 3.0 * ui_scale, 10.0 * ui_scale)
		elif link.status == "degraded":
			color = AMBER
			draw_dashed_line(start, finish, color, width, 13.0 * ui_scale)
		else:
			draw_line(start, finish, color, width, true)
		if on_route:
			var midpoint := start.linear_interpolate(finish, 0.5) + Vector2(8, -9) * ui_scale
			draw_string(small_font, midpoint, link.bearer, color)

func draw_dashed_line(a: Vector2, b: Vector2, color: Color, width: float, dash: float) -> void:
	var distance := a.distance_to(b)
	var direction := a.direction_to(b)
	var travelled := 0.0
	while travelled < distance:
		var finish := min(travelled + dash, distance)
		draw_line(a + direction * travelled, a + direction * finish, color, width)
		travelled += dash * 1.8

func _draw_node(item: Dictionary) -> void:
	var at := _to_screen(item.pos)
	var color := GREEN
	if item.status == "offline":
		color = RED
	elif item.status == "constrained":
		color = AMBER
	if item.id == source_id:
		draw_arc(at, 37.0 * ui_scale, 0.0, TAU, 40, CYAN, 4.0 * ui_scale)
	if item.id == destination_id:
		draw_arc(at, 43.0 * ui_scale, 0.0, TAU, 40, GREEN, 3.0 * ui_scale)
	if item.id == selected_id:
		draw_arc(at, 31.0 * ui_scale, 0.0, TAU, 40, INK, 3.0 * ui_scale)
	draw_circle(at, 23.0 * ui_scale, Color("071310"))
	if item.role_key == "vehicle":
		draw_rect(Rect2(at - Vector2(14, 11) * ui_scale, Vector2(28, 22) * ui_scale), color, true)
	elif item.role_key == "command":
		var diamond := PoolVector2Array([at + Vector2(0, -17) * ui_scale, at + Vector2(17, 0) * ui_scale, at + Vector2(0, 17) * ui_scale, at + Vector2(-17, 0) * ui_scale])
		draw_colored_polygon(diamond, color)
	else:
		draw_circle(at, 16.0 * ui_scale, color)
	if item.status == "offline":
		draw_line(at + Vector2(-11, -11) * ui_scale, at + Vector2(11, 11) * ui_scale, Color("071310"), 4.0 * ui_scale)
		draw_line(at + Vector2(-11, 11) * ui_scale, at + Vector2(11, -11) * ui_scale, Color("071310"), 4.0 * ui_scale)
	var label_offset := Vector2(-176, 7) if float(item.pos.x) > 0.72 else Vector2(32, 7)
	draw_string(font, at + label_offset * ui_scale, item.call, INK)

func _draw_legend() -> void:
	var y := rect_size.y - 31.0 * ui_scale
	draw_line(Vector2(28 * ui_scale, y), Vector2(68 * ui_scale, y), CYAN, 5.0 * ui_scale)
	draw_string(small_font, Vector2(78 * ui_scale, y + 6 * ui_scale), "ROUTE" if profile == "uk" else "ITINÉRAIRE", MUTED)
	draw_dashed_line(Vector2(195 * ui_scale, y), Vector2(235 * ui_scale, y), AMBER, 3.0 * ui_scale, 7.0 * ui_scale)
	draw_string(small_font, Vector2(245 * ui_scale, y + 6 * ui_scale), "DEGRADED" if profile == "uk" else "DÉGRADÉE", MUTED)
	draw_dashed_line(Vector2(390 * ui_scale, y), Vector2(430 * ui_scale, y), RED, 3.0 * ui_scale, 7.0 * ui_scale)
	draw_string(small_font, Vector2(440 * ui_scale, y + 6 * ui_scale), "OFFLINE" if profile == "uk" else "HORS LIGNE", MUTED)

func _to_screen(normalized: Vector2) -> Vector2:
	return Vector2(normalized.x * rect_size.x, normalized.y * rect_size.y)

func _node_screen(node_id: String) -> Vector2:
	for item in nodes:
		if item.id == node_id:
			return _to_screen(item.pos)
	return Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		point = event.position
		pressed = event.pressed and event.button_index == BUTTON_LEFT
	elif event is InputEventScreenTouch:
		point = event.position
		pressed = event.pressed
	if not pressed:
		return
	for item in nodes:
		if point.distance_to(_to_screen(item.pos)) <= 50.0 * ui_scale:
			emit_signal("node_selected", item.id)
			accept_event()
			return
