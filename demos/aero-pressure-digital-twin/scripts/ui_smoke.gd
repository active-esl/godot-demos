extends SceneTree

func _init():
	var scene = load("res://Main.tscn").instance()
	get_root().add_child(scene)
	yield(self, "idle_frame")
	yield(self, "idle_frame")

	if not check(scene.sensor_buttons.size() == 8, "expected eight pressure-zone buttons"):
		return
	var model = scene.car.get_node_or_null("CC0RacingCar")
	if not check(model != null, "CC0 car model was not instantiated"):
		return
	if not check(abs(model.translation.y - 0.06) < 0.001, "incorrect car ride height: %s" % model.translation.y):
		return
	scene.sensor_buttons[3].emit_signal("button_down")
	if not check(scene.selected_sensor == 3, "pressure-zone control did not select zone 4"):
		return
	if not check(scene.distance == scene.focus_from_distance, "pressure-zone focus did not start"):
		return

	if not check(scene.view_buttons.size() == 3, "expected three camera buttons"):
		return
	scene.view_buttons[1].emit_signal("button_down")
	if not check(scene.selected_sensor == -1, "camera control did not clear zone selection"):
		return
	if not check(abs(scene.yaw - -3.14159) < 0.001, "front camera control did not move"):
		return

	if not check(scene.flow_enabled, "airflow did not start enabled"):
		return
	scene.airflow_button.emit_signal("button_down")
	if not check(not scene.flow_enabled, "airflow control did not pause"):
		return
	if not check(scene.airflow_button.text == "RESUME AIRFLOW", "airflow control label did not update"):
		return

	print("AERO_UI_SMOKE_OK controls=12 authored_material_colours=true ride_height=true")
	quit()

func check(condition, message):
	if condition:
		return true
	printerr("AERO_UI_SMOKE_FAILED: %s" % message)
	quit(1)
	return false
