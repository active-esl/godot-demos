extends SceneTree

const ScenarioModel = preload("res://scripts/scenario_model.gd")

func _init() -> void:
	var model = ScenarioModel.new()
	model.reset()
	assert(model.all_people().size() == 5)
	assert(model.current().key == "deployment")
	for _step in range(6): model.next()
	assert(model.current().key == "sync_restored")
	assert(model.person_state("raven_4").bearer == "UWB + GNSS")
	assert(model.person_state("raven_4").age_seconds == 1)
	model.profile = "fr"
	assert(model.profile == "fr")
	model.previous()
	assert(model.current().key == "extraction")
	print("RESILIENT_TACTICAL_MODEL_SMOKE_OK")
	quit()
