extends Reference
class_name BookingModel

const BEATS := [535, 540, 580, 605, 610]
const CHECKIN_GRACE := 10

var room_name := "Atlas · 2.14"
var floor_name := "Second floor · East wing"
var now_min := 535
var offline := false
var beat_index := 0
var bookings := []

func load_day(path: String) -> bool:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return false
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return false
	room_name = str(parsed.result.get("room", room_name))
	floor_name = str(parsed.result.get("floor", floor_name))
	bookings = parsed.result.get("bookings", []).duplicate(true)
	return true

func reset() -> void:
	beat_index = 0
	now_min = BEATS[0]
	offline = false
	load_day("res://data/mock_day.json")

func next_beat() -> void:
	beat_index = (beat_index + 1) % BEATS.size()
	now_min = BEATS[beat_index]
	apply_noshow(false)

func snapshot() -> Dictionary:
	var current = null
	var upcoming = null
	for booking in bookings:
		if now_min >= int(booking.start) and now_min < int(booking.end):
			current = booking
		elif int(booking.start) > now_min and (upcoming == null or int(booking.start) < int(upcoming.start)):
			upcoming = booking
	var state := "free"
	if current != null:
		state = "busy"
	elif upcoming != null and int(upcoming.start) - now_min <= 10:
		state = "reserved"
	return {"current": current, "upcoming": upcoming, "state": state}

func check_in() -> bool:
	var current = snapshot().current
	if current == null or bool(current.checked_in):
		return false
	current.checked_in = true
	return true

func extend_current(extra: int = 15) -> bool:
	var current = snapshot().current
	if current == null:
		return false
	var proposed := int(current.end) + extra
	for booking in bookings:
		if booking != current and int(booking.start) < proposed and int(booking.end) > int(current.end):
			return false
	current.end = proposed
	return true

func end_current() -> bool:
	var current = snapshot().current
	if current == null:
		return false
	bookings.erase(current)
	return true

func book_at(start_min: int, duration: int = 30) -> bool:
	var finish := start_min + duration
	for booking in bookings:
		if start_min < int(booking.end) and finish > int(booking.start):
			return false
	bookings.append({"id":"walkup", "start":start_min, "end":finish, "title":"Walk-up booking", "host":"Booked at the room", "checked_in":true})
	bookings.sort_custom(self, "_sort_booking")
	return true

func book_now() -> bool:
	var start_min := int(ceil(float(now_min) / 5.0) * 5.0)
	return book_at(start_min, 30)

func apply_noshow(force: bool) -> bool:
	var current = snapshot().current
	if current == null or bool(current.checked_in):
		return false
	if force or now_min >= int(current.start) + CHECKIN_GRACE:
		bookings.erase(current)
		return true
	return false

func demo_noshow() -> bool:
	var snap := snapshot()
	if snap.current == null and snap.upcoming != null:
		now_min = int(snap.upcoming.start) + CHECKIN_GRACE
	return apply_noshow(true)

func free_slots() -> Array:
	var rows := []
	var cursor := 8 * 60
	for booking in bookings:
		if int(booking.start) > cursor:
			rows.append({"free":true, "start":cursor, "end":int(booking.start)})
		rows.append({"free":false, "booking":booking})
		cursor = max(cursor, int(booking.end))
	if cursor < 17 * 60:
		rows.append({"free":true, "start":cursor, "end":17 * 60})
	return rows

func format_time(value: int) -> String:
	return "%02d:%02d" % [int(value / 60), value % 60]

func _sort_booking(a: Dictionary, b: Dictionary) -> bool:
	return int(a.start) < int(b.start)

