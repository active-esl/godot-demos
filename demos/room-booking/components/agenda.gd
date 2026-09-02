extends PanelContainer

signal slot_requested(start_min)

const CARBON := Color("07111f")
const MUTED := Color("657087")
const CYAN := Color("20d6d2")
const LIME := Color("b6f23b")

var list: VBoxContainer

func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("edf1f6")
	panel.corner_radius_top_left = 18
	panel.corner_radius_top_right = 18
	panel.corner_radius_bottom_left = 18
	panel.corner_radius_bottom_right = 18
	add_stylebox_override("panel", panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]: margin.add_constant_override("margin_" + side, 22)
	margin.add_constant_override("margin_top", 24)
	margin.add_constant_override("margin_bottom", 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_constant_override("separation", 12)
	margin.add_child(column)
	var heading := _label("TODAY'S AGENDA", 18, CARBON, true)
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_constant_override("separation", 8)
	scroll.add_child(list)

func configure(rows: Array, model) -> void:
	for child in list.get_children(): child.queue_free()
	for row in rows:
		if row.free:
			var available := int(row.end) - int(row.start)
			if available < 30: continue
			var button := Button.new()
			button.text = "%s — %s   AVAILABLE" % [model.format_time(int(row.start)), model.format_time(int(row.end))]
			button.align = Button.ALIGN_LEFT
			button.rect_min_size.y = 52
			button.add_color_override("font_color", CARBON)
			button.add_font_override("font", _font(true, 14))
			var box := StyleBoxFlat.new()
			box.bg_color = Color("e1f8d0")
			box.border_width_left = 5
			box.border_color = LIME
			box.corner_radius_top_right = 8
			box.corner_radius_bottom_right = 8
			button.add_stylebox_override("normal", box)
			button.add_stylebox_override("hover", box)
			button.connect("pressed", self, "emit_signal", ["slot_requested", int(row.start)])
			list.add_child(button)
		else:
			var booking: Dictionary = row.booking
			var item := VBoxContainer.new()
			item.rect_min_size.y = 61
			list.add_child(item)
			item.add_child(_label("%s — %s" % [model.format_time(int(booking.start)), model.format_time(int(booking.end))], 13, CYAN, true))
			var name := _label(str(booking.title), 16, CARBON, true)
			name.clip_text = true
			item.add_child(name)

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
