extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed = load("res://Main.tscn")
	assert(packed != null)
	var scene = packed.instance()
	root.add_child(scene)
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	assert(scene.get_node("UXViewport/RoomBooking") != null)
	assert(scene.get_node("ProductPivot/ActivePOE") != null)
	scene.set_use_mode(true)
	assert(scene.use_mode)
	scene.rotation_now = Vector2.ZERO
	scene.camera_distance = 0.285
	scene._apply_pose()
	var booking = scene.get_node("UXViewport/RoomBooking")
	var before: int = booking.model.bookings.size()
	var button: Button = booking.meeting_card.book_button
	assert(button.visible)
	var ux_position := button.rect_global_position + button.rect_size * 0.5
	var display: Rect2 = scene._display_rect()
	var screen_position: Vector2 = display.position + ux_position / scene.UX_SIZE * display.size
	var press := InputEventMouseButton.new()
	press.button_index = BUTTON_LEFT
	press.position = screen_position
	press.global_position = screen_position
	press.pressed = true
	scene._input(press)
	var release: InputEventMouseButton = press.duplicate() as InputEventMouseButton
	release.pressed = false
	scene._input(release)
	yield(self, "idle_frame")
	assert(booking.model.bookings.size() == before + 1)
	scene.set_use_mode(false)
	assert(not scene.use_mode)
	print("ACTIVE_POE_PRODUCT_TWIN_SMOKE_OK")
	quit()
