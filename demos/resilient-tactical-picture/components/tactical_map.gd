extends Control

signal person_selected(person_id)

const INK := Color("dce9e6")
const MUTED := Color("718582")
const GRID := Color("173632")
const GREEN := Color("55e6a5")
const AMBER := Color("ffbf69")
const RED := Color("ff5d62")
const CYAN := Color("63d9ff")

var people := []
var selected_id := ""
var beat := 0
var profile := "uk"
var font: DynamicFont
var ui_scale := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf")
	font.size = 18

func set_ui_scale(new_scale: float) -> void:
	ui_scale = max(1.0, new_scale)
	font.size = int(round(18.0 * ui_scale))
	update()

func configure(new_people: Array, new_selected: String, new_beat: int, new_profile: String) -> void:
	people = new_people
	selected_id = new_selected
	beat = new_beat
	profile = new_profile
	update()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color("0a0e0d"), true)
	_draw_grid()
	_draw_site()
	_draw_routes()
	for person in people:
		_draw_person(person)
	_draw_legend()

func _draw_grid() -> void:
	var spacing := int(round(80.0 * ui_scale))
	for x in range(0, int(rect_size.x), spacing):
		draw_line(Vector2(x, 0), Vector2(x, rect_size.y), GRID, 1.0)
	for y in range(0, int(rect_size.y), spacing):
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), GRID, 1.0)

func _draw_site() -> void:
	var building := PoolVector2Array([
		Vector2(rect_size.x * 0.52, rect_size.y * 0.18), Vector2(rect_size.x * 0.79, rect_size.y * 0.18),
		Vector2(rect_size.x * 0.79, rect_size.y * 0.53), Vector2(rect_size.x * 0.52, rect_size.y * 0.53)
	])
	draw_colored_polygon(building, Color("102622"))
	for i in range(building.size()):
		draw_line(building[i], building[(i + 1) % building.size()], Color("37645c"), 3.0)
	var restricted := PoolVector2Array([
		Vector2(rect_size.x * 0.08, rect_size.y * 0.18), Vector2(rect_size.x * 0.38, rect_size.y * 0.10),
		Vector2(rect_size.x * 0.44, rect_size.y * 0.39), Vector2(rect_size.x * 0.14, rect_size.y * 0.47)
	])
	draw_colored_polygon(restricted, Color("321c1d70"))
	for i in range(restricted.size()):
		draw_line(restricted[i], restricted[(i + 1) % restricted.size()], Color("8f4244"), 2.0)
	draw_string(font, Vector2(rect_size.x * 0.57, rect_size.y * 0.24), "STRUCTURE B-12" if profile == "uk" else "BÂTIMENT B-12", MUTED)
	draw_string(font, Vector2(rect_size.x * 0.14, rect_size.y * 0.28), "RESTRICTED" if profile == "uk" else "ZONE RESTREINTE", Color("bf6d70"))

func _draw_routes() -> void:
	if people.size() < 2:
		return
	var points := PoolVector2Array()
	for person in people:
		points.append(_to_screen(person.pos))
	for i in range(points.size() - 1):
		draw_dashed_line(points[i], points[i + 1], Color("489a86"), 2.0, 9.0)
	if beat >= 5:
		var casualty := _person_screen("raven_4")
		var extraction := Vector2(rect_size.x * 0.89, rect_size.y * 0.20)
		draw_dashed_line(casualty, extraction, AMBER, 4.0, 14.0)
		draw_circle(extraction, 23.0, Color("382d1d"))
		draw_arc(extraction, 23.0, 0.0, TAU, 40, AMBER, 4.0)
		draw_string(font, extraction + Vector2(-56, 52), "EXTRACT" if profile == "uk" else "ÉVACUER", AMBER)

func draw_dashed_line(a: Vector2, b: Vector2, color: Color, width: float, dash: float) -> void:
	var distance := a.distance_to(b)
	var direction := a.direction_to(b)
	var travelled := 0.0
	while travelled < distance:
		var end := min(travelled + dash, distance)
		draw_line(a + direction * travelled, a + direction * end, color, width)
		travelled += dash * 1.8

func _draw_person(person: Dictionary) -> void:
	var at := _to_screen(person.pos)
	var color := GREEN
	if person.status == "man_down": color = RED
	elif person.status == "evacuation": color = AMBER
	if person.id == "raven_4" and beat >= 3:
		draw_circle(at, max(38.0, person.confidence * 9.0) * ui_scale, Color(color.r, color.g, color.b, 0.10))
		draw_arc(at, max(38.0, person.confidence * 9.0) * ui_scale, 0.0, TAU, 56, Color(color.r, color.g, color.b, 0.45), 2.0 * ui_scale)
	if person.id == selected_id:
		draw_arc(at, 34.0 * ui_scale, 0.0, TAU, 40, Color("f5fbf8"), 3.0 * ui_scale)
	draw_circle(at, 23.0 * ui_scale, Color("071310"))
	draw_circle(at, 17.0 * ui_scale, color)
	draw_string(font, at + Vector2(32, 6) * ui_scale, person.call, INK)

func _draw_legend() -> void:
	draw_circle(Vector2(34, rect_size.y / ui_scale - 34) * ui_scale, 7.0 * ui_scale, GREEN)
	draw_string(font, Vector2(51, rect_size.y / ui_scale - 27) * ui_scale, "TRACKED" if profile == "uk" else "SUIVI", MUTED)
	draw_circle(Vector2(174, rect_size.y / ui_scale - 34) * ui_scale, 7.0 * ui_scale, CYAN)
	draw_string(font, Vector2(191, rect_size.y / ui_scale - 27) * ui_scale, "GATEWAY" if profile == "uk" else "PASSERELLE", MUTED)
	draw_circle(Vector2(rect_size.x * 0.46, rect_size.y * 0.82), 18.0, CYAN)
	draw_arc(Vector2(rect_size.x * 0.46, rect_size.y * 0.82), 29.0, 0.0, TAU, 40, Color("4694a9"), 2.0)

func _to_screen(normalized: Vector2) -> Vector2:
	return Vector2(normalized.x * rect_size.x, normalized.y * rect_size.y)

func _person_screen(person_id: String) -> Vector2:
	for person in people:
		if person.id == person_id: return _to_screen(person.pos)
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
	if not pressed: return
	for person in people:
		if point.distance_to(_to_screen(person.pos)) <= 48.0 * ui_scale:
			emit_signal("person_selected", person.id)
			accept_event()
			return
