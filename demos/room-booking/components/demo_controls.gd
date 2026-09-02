extends PanelContainer

signal next_requested
signal noshow_requested
signal offline_requested
signal reset_requested

const CARBON := Color("07111f")
const CLOUD := Color("f7f9fc")
const MUTED := Color("a7b4c8")

var progress: Label

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CARBON
	add_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_constant_override("margin_left", 32)
	margin.add_constant_override("margin_right", 32)
	margin.add_constant_override("margin_top", 13)
	margin.add_constant_override("margin_bottom", 13)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_constant_override("separation", 12)
	margin.add_child(row)
	var label := _label("PRESENTATION CONTROLS", 14, MUTED, true)
	label.rect_min_size.x = 210
	row.add_child(label)
	for spec in [["Next beat  →", "next_requested"], ["No-show", "noshow_requested"], ["Offline", "offline_requested"], ["Reset", "reset_requested"]]:
		var button := Button.new()
		button.text = spec[0]
		button.rect_min_size = Vector2(130, 50)
		button.add_color_override("font_color", CLOUD)
		button.add_font_override("font", _font(true, 15))
		button.connect("pressed", self, "emit_signal", [spec[1]])
		row.add_child(button)
	progress = _label("", 14, MUTED, false)
	progress.align = Label.ALIGN_RIGHT
	progress.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(progress)

func configure(index: int, count: int, offline: bool) -> void:
	progress.text = "Beat %d of %d%s  ·  Keys: N / X / O / R" % [index + 1, count, "  ·  OFFLINE" if offline else ""]

func _label(value: String, size: int, colour: Color, bold: bool) -> Label:
	var item := Label.new()
	item.text = value
	item.add_color_override("font_color", colour)
	item.add_font_override("font", _font(bold, size))
	return item

func _font(bold: bool, size: int) -> DynamicFont:
	var font := DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf" if bold else "res://fonts/DejaVuSans.ttf")
	font.size = size
	return font
