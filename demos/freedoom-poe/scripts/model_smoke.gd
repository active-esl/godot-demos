extends SceneTree

const Raycaster = preload("res://scripts/raycaster.gd")

func _init() -> void:
	var engine = Raycaster.new()
	var before = engine.position
	engine.step(0.25, 1.0, 0.0, 0.0)
	assert(engine.position != before)
	engine.fire()
	engine.use()
	assert(engine.snapshot().shots == 1)
	assert(engine.snapshot().doors == 1)
	var image = engine.render_frame()
	assert(image.get_width() == engine.WIDTH)
	assert(image.get_height() == engine.HEIGHT)
	print("FREEDOOM_POE_MODEL_SMOKE_OK")
	quit()
