extends PanelContainer

signal checkin_requested
signal extend_requested
signal end_requested
signal book_requested

const CARBON := Color("07111f")
const MUTED := Color("657087")
const CLOUD := Color("f7f9fc")
const CYAN := Color("20d6d2")
const VIOLET := Color("7557ff")
const LIME := Color("b6f23b")
const RED := Color("ec4561")

var eyebrow: Label
var title: Label
var host: Label
var timing: Label
var hint: Label
var checkin_button: Button
var extend_button: Button
var end_button: Button
var book_button: Button

func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("ffffff")
	panel.corner_radius_top_left = 18
	panel.corner_radius_top_right = 18
	panel.corner_radius_bottom_left = 18
	panel.corner_radius_bottom_right = 18
	add_stylebox_override("panel", panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]: margin.add_constant_override("margin_" + side, 34)
	margin.add_constant_override("margin_top", 30)
	margin.add_constant_override("margin_bottom", 26)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_constant_override("separation", 13)
	margin.add_child(column)
	eyebrow = _label("CURRENT MEETING", 15, MUTED, true)
	column.add_child(eyebrow)
	title = _label("", 42, CARBON, true)
	title.autowrap = true
	title.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(title)
	host = _label("", 21, MUTED, false)
	column.add_child(host)
	timing = _label("", 25, CARBON, true)
	column.add_child(timing)
	hint = _label("", 17, MUTED, false)
	hint.autowrap = true
	column.add_child(hint)
	var actions := HBoxContainer.new()
	actions.add_constant_override("separation", 12)
	column.add_child(actions)
	checkin_button = _button("Check in", CYAN, CARBON)
	checkin_button.connect("pressed", self, "emit_signal", ["checkin_requested"])
	actions.add_child(checkin_button)
	extend_button = _button("Extend +15", VIOLET, CLOUD)
	extend_button.connect("pressed", self, "emit_signal", ["extend_requested"])
	actions.add_child(extend_button)
	end_button = _button("End meeting", RED, CLOUD)
	end_button.connect("pressed", self, "emit_signal", ["end_requested"])
	actions.add_child(end_button)
	book_button = _button("Book 30 min", LIME, CARBON)
	book_button.connect("pressed", self, "emit_signal", ["book_requested"])
	actions.add_child(book_button)

func configure(snapshot: Dictionary, model) -> void:
	var current = snapshot.current
	var upcoming = snapshot.upcoming
	if current != null:
		eyebrow.text = "CURRENT MEETING"
		title.text = str(current.title)
		host.text = "Hosted by " + str(current.host)
		timing.text = "%s — %s" % [model.format_time(int(current.start)), model.format_time(int(current.end))]
		if bool(current.checked_in):
			hint.text = "Checked in · Room occupied"
		else:
			var grace: int = max(0, int(current.start) + model.CHECKIN_GRACE - model.now_min)
			hint.text = "Awaiting check-in · Auto-release in %d min" % grace
	elif snapshot.state == "reserved" and upcoming != null:
		eyebrow.text = "UP NEXT"
		title.text = "Reserved from %s" % model.format_time(int(upcoming.start))
		host.text = str(upcoming.title) + " · " + str(upcoming.host)
		timing.text = "%s — %s" % [model.format_time(int(upcoming.start)), model.format_time(int(upcoming.end))]
		hint.text = "This room is being held for the next meeting."
	else:
		eyebrow.text = "ROOM AVAILABLE"
		title.text = "Free now"
		host.text = "Tap below to reserve this room instantly."
		if upcoming != null:
			timing.text = "Next · %s at %s" % [str(upcoming.title), model.format_time(int(upcoming.start))]
		else:
			timing.text = "No more bookings today"
		hint.text = "Walk-up bookings are added to the shared agenda."
	checkin_button.visible = current != null and not bool(current.checked_in)
	extend_button.visible = current != null
	end_button.visible = current != null
	book_button.visible = current == null and snapshot.state == "free"

func _label(value: String, size: int, colour: Color, bold: bool) -> Label:
	var item := Label.new()
	item.text = value
	item.add_color_override("font_color", colour)
	item.add_font_override("font", _font(bold, size))
	return item

func _button(value: String, colour: Color, ink: Color) -> Button:
	var item := Button.new()
	item.text = value
	item.rect_min_size = Vector2(138, 58)
	item.size_flags_horizontal = SIZE_EXPAND_FILL
	item.add_color_override("font_color", ink)
	item.add_color_override("font_color_hover", ink)
	item.add_font_override("font", _font(true, 16))
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	item.add_stylebox_override("normal", box)
	item.add_stylebox_override("hover", box)
	return item

func _font(bold: bool, size: int) -> DynamicFont:
	var font := DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf" if bold else "res://fonts/DejaVuSans.ttf")
	font.size = size
	return font
