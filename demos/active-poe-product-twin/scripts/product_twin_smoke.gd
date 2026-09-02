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
	scene.set_use_mode(false)
	assert(not scene.use_mode)
	print("ACTIVE_POE_PRODUCT_TWIN_SMOKE_OK")
	quit()

