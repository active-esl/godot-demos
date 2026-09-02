extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://Main.tscn")
	var main = packed.instance()
	get_root().add_child(main)
	yield(self, "idle_frame")
	yield(self, "idle_frame")
	assert(main.model.beat == 0)
	assert(main.get_node("Layout/TopBar/Brand/Title").text == "RESILIENT TACTICAL PICTURE")
	main._next()
	assert(main.model.beat == 1)
	main._toggle_language()
	assert(main.model.profile == "fr")
	assert(main.get_node("Layout/TopBar/Brand/Title").text == "SITUATION TACTIQUE RÉSILIENTE")
	assert(main.map.profile == "fr")
	print("RESILIENT_TACTICAL_UI_SMOKE_OK")
	quit()

