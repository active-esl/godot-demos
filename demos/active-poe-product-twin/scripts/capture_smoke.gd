extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://Main.tscn").instance()
	root.add_child(scene)
	for _frame in range(12):
		yield(self, "idle_frame")
	var image := root.get_texture().get_data()
	image.flip_y()
	var output := OS.get_environment("ACTIVE_POE_CAPTURE")
	if output == "":
		output = "/tmp/active-poe-product-twin.png"
	assert(image.save_png(output) == OK)
	print("ACTIVE_POE_PRODUCT_TWIN_CAPTURE_OK " + output)
	quit()

