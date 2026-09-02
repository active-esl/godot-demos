extends PanelContainer

const CARBON := Color("07111f")
const CLOUD := Color("f7f9fc")
const CYAN := Color("20d6d2")
const LIME := Color("b6f23b")
const AMBER := Color("f0a71a")
const RED := Color("ec4561")

var state_label: Label
var room_label: Label
var detail_label: Label
var clock_label: Label

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.add_constant_override("margin_left", 32)
	margin.add_constant_override("margin_right", 32)
	margin.add_constant_override("margin_top", 20)
	margin.add_constant_override("margin_bottom", 18)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_constant_override("separation", 22)
	margin.add_child(row)
	var brand := Label.new()
	brand.text = "ACTIVE-EDGE"
	brand.add_color_override("font_color", CARBON)
	brand.add_font_override("font", _font(true, 23))
	brand.rect_min_size.x = 190
	row.add_child(brand)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(names)
	room_label = Label.new()
	room_label.add_color_override("font_color", CARBON)
	room_label.add_font_override("font", _font(true, 32))
	names.add_child(room_label)
	detail_label = Label.new()
	detail_label.add_color_override("font_color", Color("26364c"))
	detail_label.add_font_override("font", _font(false, 16))
	names.add_child(detail_label)
	state_label = Label.new()
	state_label.align = Label.ALIGN_CENTER
	state_label.valign = Label.VALIGN_CENTER
	state_label.rect_min_size = Vector2(220, 66)
	state_label.add_color_override("font_color", CLOUD)
	state_label.add_font_override("font", _font(true, 28))
	row.add_child(state_label)
	clock_label = Label.new()
	clock_label.align = Label.ALIGN_RIGHT
	clock_label.valign = Label.VALIGN_CENTER
	clock_label.rect_min_size.x = 100
	clock_label.add_color_override("font_color", CARBON)
	clock_label.add_font_override("font", _font(true, 28))
	row.add_child(clock_label)

func configure(room: String, floor_name: String, state: String, clock: String, offline: bool) -> void:
	room_label.text = room
	detail_label.text = floor_name + ("  ·  Offline · cached agenda" if offline else "  ·  Synced just now")
	clock_label.text = clock
	state_label.text = state.to_upper()
	var colour := LIME
	if state == "reserved": colour = AMBER
	elif state == "busy": colour = RED
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	state_label.add_stylebox_override("normal", box)
	var strip := StyleBoxFlat.new()
	strip.bg_color = CYAN if offline else colour
	add_stylebox_override("panel", strip)

func _font(bold: bool, size: int) -> DynamicFont:
	var font := DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf" if bold else "res://fonts/DejaVuSans.ttf")
	font.size = size
	return font
