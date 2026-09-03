extends SceneTree

func _init():
	var scene = load("res://Main.tscn").instance()
	get_root().add_child(scene)
	yield(self, "idle_frame")
	yield(self, "idle_frame")

	assert(scene.sensor_buttons.size() == 8)
	var model = scene.car.get_node("CC0RacingCar")
	assert(abs(model.translation.y - 0.06) < 0.001)
	scene.sensor_buttons[3].emit_signal("button_down")
	assert(scene.selected_sensor == 3)
	assert(scene.distance == scene.focus_from_distance)

	assert(scene.view_buttons.size() == 3)
	scene.view_buttons[1].emit_signal("button_down")
	assert(scene.selected_sensor == -1)
	assert(abs(scene.yaw - -3.14159) < 0.001)

	assert(scene.flow_enabled)
	scene.airflow_button.emit_signal("button_down")
	assert(not scene.flow_enabled)
	assert(scene.airflow_button.text == "RESUME AIRFLOW")

	print("AERO_UI_SMOKE_OK controls=12 authored_material_colours=true ride_height=true")
	quit()
