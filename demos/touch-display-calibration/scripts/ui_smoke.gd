extends SceneTree

func _init():
	var scene = load("res://Main.tscn").instance()
	get_root().add_child(scene)
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	assert(scene.pages.size() == 4)
	assert(scene.nav_buttons.size() == 4)
	assert(scene.target_points.size() == 5)
	assert(scene.dts_properties("invert_xy").size() == 2)
	assert(scene.dts_properties("swap_invert_xy").size() == 3)
	assert(scene.udev_matrix("swap_invert_xy") == "0 -1 1 -1 0 1")
	for target in scene.target_points:
		scene.samples.append({"expected": target, "actual": Vector2(1.0 - target.x, target.y), "source": "smoke"})
	var result = scene.analyse()
	assert(result.ready)
	assert(result.mode == "invert_x")
	assert(result.error < 0.001)
	print("TOUCH_DISPLAY_CALIBRATION_SMOKE_OK")
	quit()
