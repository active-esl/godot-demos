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
var clock_timer: Timer
var calendar_request: HTTPRequest
var calendar_feed_url := ""
var web_pointer_callback = null
var web_pointer_sequence := 0

func _ready() -> void:
	model = BookingModelClass.new()
	model.reset()
	_build_toast()
	_build_clock_timer()
	_build_web_calendar_feed()
	_build_web_pointer_bridge()
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

func _build_web_pointer_bridge() -> void:
	if not OS.has_feature("HTML5"):
		return
	# The containing 3D product viewer owns pointer gesture arbitration and
	# raycasts the LCD. Give it a stable application-level input boundary rather
	# than redispatching synthetic DOM events into the export canvas.
	web_pointer_callback = JavaScript.create_callback(self, "_on_web_pointer_tap")
	var window = JavaScript.get_interface("window")
	window.activePoeInput = web_pointer_callback
	window.activePoeInputReady = true

func _on_web_pointer_tap(args: Array) -> void:
	if args.size() < 2:
		return
	var viewport_size := get_viewport_rect().size
	var position := Vector2(clamp(float(args[0]), 0.0, 1.0) * viewport_size.x, clamp(float(args[1]), 0.0, 1.0) * viewport_size.y)
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	var press := InputEventMouseButton.new()
	press.button_index = BUTTON_LEFT
	press.position = position
	press.global_position = position
	press.pressed = true
	Input.parse_input_event(press)
	# Keep the press alive until the next idle frame. Some HTML5 browsers batch
	# callback work; a synchronous press+release can be collapsed before a
	# Control observes its pressed state.
	get_tree().create_timer(0.05).connect("timeout", self, "_release_web_pointer", [position])
	web_pointer_sequence += 1
	var window = JavaScript.get_interface("window")
	window.activePoeInputAck = web_pointer_sequence

func _release_web_pointer(position: Vector2) -> void:
	var release := InputEventMouseButton.new()
	release.button_index = BUTTON_LEFT
	release.position = position
	release.global_position = position
	release.pressed = false
	Input.parse_input_event(release)

func _refresh() -> void:
	var snap = model.snapshot()
	status_strip.configure(model.room_name, model.floor_name, snap.state, model.format_time(model.now_min), model.sync_label(), model.offline)
	meeting_card.configure(snap, model)
	agenda.configure(model.free_slots(), model)
	demo_controls.configure(model.beat_index, model.BEATS.size(), model.offline, model.clock_mode_label())
	if OS.has_feature("HTML5"):
		var window = JavaScript.get_interface("window")
		window.activePoeUxState = str(snap.state)
		window.activePoeBookingCount = model.bookings.size()

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
	_show_toast("Live room time restored")
	_refresh()

func _on_checkin() -> void:
	_show_toast("Local preview · checked in" if model.check_in() else "Check-in is not available")
	_refresh()

func _on_extend() -> void:
	_show_toast("Local preview · extended by 15 minutes" if model.extend_current() else "Extension blocked by the next booking")
	_refresh()

func _on_end() -> void:
	_show_toast("Local preview · room released" if model.end_current() else "There is no meeting to end")
	_refresh()

func _on_book_now() -> void:
	_show_toast("Local preview · booked for 30 minutes" if model.book_now() else "That time is unavailable")
	_refresh()

func _on_book_slot(start_min: int) -> void:
	_show_toast("Local preview · booked at %s" % model.format_time(start_min) if model.book_at(start_min) else "That slot is unavailable")
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

func _build_clock_timer() -> void:
	clock_timer = Timer.new()
	clock_timer.wait_time = 8.0
	clock_timer.connect("timeout", self, "_on_clock_tick")
	add_child(clock_timer)
	clock_timer.start()

func _on_clock_tick() -> void:
	var calendar_changed: bool = model.reload_runtime_day()
	var clock_changed: bool = model.sync_clock()
	_request_web_calendar()
	if calendar_changed:
		_show_toast("Google Calendar updated")
	if calendar_changed or clock_changed:
		_refresh()

func _build_web_calendar_feed() -> void:
	if not OS.has_feature("HTML5"):
		return
	calendar_request = HTTPRequest.new()
	calendar_request.connect("request_completed", self, "_on_web_calendar_received")
	add_child(calendar_request)
	var href := str(JavaScript.eval("window.location.href", true)).split("#")[0].split("?")[0]
	calendar_feed_url = href.get_base_dir().plus_file("calendar_day.json")
	call_deferred("_request_web_calendar")

func _request_web_calendar() -> void:
	if calendar_request == null or model.offline or calendar_feed_url == "":
		return
	calendar_request.request(calendar_feed_url + "?t=" + str(OS.get_unix_time()))

func _on_web_calendar_received(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return
	var before: String = to_json(model.bookings) + model.schedule_day
	if not model.apply_day(parsed.result):
		return
	model.sync_clock()
	var changed: bool = to_json(model.bookings) + model.schedule_day != before
	if changed:
		_show_toast("Google Calendar updated")
	_refresh()

func _show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.show()
	toast_timer.start()
