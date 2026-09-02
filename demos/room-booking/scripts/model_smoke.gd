extends SceneTree

const BookingModelClass = preload("res://scripts/booking_model.gd")

func _init() -> void:
	var model = BookingModelClass.new()
	assert(model.load_day("res://data/mock_day.json"))
	assert(model.snapshot().state == "reserved")
	model.next_beat()
	assert(model.snapshot().state == "busy")
	assert(model.check_in())
	assert(model.extend_current(15))
	assert(model.end_current())
	assert(model.snapshot().state == "free")
	assert(model.book_now())
	model.reset()
	assert(model.demo_noshow())
	assert(model.snapshot().state == "free")
	print("ROOM_BOOKING_MODEL_SMOKE_OK")
	quit()

