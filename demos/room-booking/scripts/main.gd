extends Control

const BookingModelClass = preload("res://scripts/booking_model.gd")
const CARBON := Color("07111f")

onready var status_strip = $Layout/StatusStrip
onready var meeting_card = $Layout/Body/Columns/MeetingCard
onready var agenda = $Layout/Body/Columns/Agenda
onready var demo_controls = $Layout/DemoControls

var model
var toast_label: Label
var toast_timer: Timer

func _ready() -> void:
	model = BookingModelClass.new()
	model.reset()
	_build_toast()
	meeting_card.connect("checkin_requested", self, "_on_checkin")
	meeting_card.connect("extend_requested", self, "_on_extend")
	meeting_card.connect("end_requested", self, "_on_end")
	meeting_card.connect("book_requested", self, "_on_book_now")
	agenda.connect("slot_requested", self, "_on_book_slot")
	demo_controls.connect("next_requested", self, "_on_next")
	demo_controls.connect("noshow_requested", self, "_on_noshow")
	demo_controls.connect("offline_requested", self, "_on_offline")
	demo_controls.connect("reset_requested", self, "_on_reset")
	_refresh()
	print("ROOM_BOOKING_DEMO_READY")

func _refresh() -> void:
	var snap = model.snapshot()
	status_strip.configure(model.room_name, model.floor_name, snap.state, model.format_time(model.now_min), model.offline)
	meeting_card.configure(snap, model)
	agenda.configure(model.free_slots(), model)
	demo_controls.configure(model.beat_index, model.BEATS.size(), model.offline)

func _on_next() -> void:
	model.next_beat()
	_show_toast("Story advanced to %s" % model.format_time(model.now_min))
	_refresh()

func _on_noshow() -> void:
	_show_toast("No-show auto-release applied" if model.demo_noshow() else "No unchecked booking to release")
	_refresh()

func _on_offline() -> void:
	model.offline = not model.offline
	_show_toast("Offline · showing cached agenda" if model.offline else "Back online · agenda synced")
	_refresh()

func _on_reset() -> void:
	model.reset()
	_show_toast("Demo reset to 08:55")
	_refresh()

func _on_checkin() -> void:
	_show_toast("Checked in" if model.check_in() else "Check-in is not available")
	_refresh()

func _on_extend() -> void:
	_show_toast("Meeting extended by 15 minutes" if model.extend_current() else "Extension blocked by the next booking")
	_refresh()

func _on_end() -> void:
	_show_toast("Meeting ended · room is free" if model.end_current() else "There is no meeting to end")
	_refresh()

func _on_book_now() -> void:
	_show_toast("Room booked for 30 minutes" if model.book_now() else "That time is unavailable")
	_refresh()

func _on_book_slot(start_min: int) -> void:
	_show_toast("Booked at %s" % model.format_time(start_min) if model.book_at(start_min) else "That slot is unavailable")
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.scancode:
		KEY_N: _on_next()
		KEY_X: _on_noshow()
		KEY_O: _on_offline()
		KEY_R: _on_reset()

func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.visible = false
	toast_label.align = Label.ALIGN_CENTER
	toast_label.valign = Label.VALIGN_CENTER
	toast_label.anchor_left = 0.28
	toast_label.anchor_right = 0.72
	toast_label.anchor_top = 0.86
	toast_label.anchor_bottom = 0.93
	toast_label.add_color_override("font_color", Color("f7f9fc"))
	var font := DynamicFont.new()
	font.font_data = load("res://fonts/DejaVuSans-Bold.ttf")
	toast_label.add_font_override("font", font)
	font.size = 17
	var box := StyleBoxFlat.new()
	box.bg_color = Color("dd07111f")
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	toast_label.add_stylebox_override("normal", box)
	add_child(toast_label)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 2.2
	toast_timer.connect("timeout", toast_label, "hide")
	add_child(toast_timer)

func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.show()
	toast_timer.start()
