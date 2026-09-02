extends SceneTree

const ScenarioModel = preload("res://scripts/scenario_model.gd")

func _init() -> void:
	var model = ScenarioModel.new()
	model.reset()
	assert(model.all_nodes().size() == 5)
	assert(model.all_links().size() == 7)
	assert(model.current().key == "nodes_discovered")
	assert(model.route().path == ["hq_7", "relay_2", "relay_5", "team_alpha"])
	model.beat = 2
	assert(model.route().path == ["hq_7", "relay_2", "vehicle_4", "relay_5", "team_alpha"])
	model.beat = 3
	assert(model.node_state("relay_2").status == "offline")
	assert(model.route().path == ["hq_7", "vehicle_4", "relay_5", "team_alpha"])
	model.beat = 4
	assert(model.route().path == ["hq_7", "vehicle_4", "team_alpha"])
	model.reset()
	model.select_route_node("vehicle_4")
	assert(model.awaiting_destination)
	model.select_route_node("relay_5")
	assert(not model.awaiting_destination)
	assert(model.route().path == ["vehicle_4", "relay_5"])
	model.reset()
	for _step in range(6): model.next()
	assert(model.current().key == "route_restored")
	assert(model.node_state("relay_2").status == "active")
	model.profile = "fr"
	assert(model.profile == "fr")
	model.previous()
	assert(model.current().key == "store_forward")
	print("RESILIENT_TACTICAL_MODEL_SMOKE_OK")
	quit()
