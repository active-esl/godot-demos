extends SceneTree

var frames := 0

func _init() -> void:
	connect("idle_frame", self, "_on_idle_frame")
	call_deferred("_load_main")

func _load_main() -> void:
	var packed = load("res://Main.tscn")
	assert(packed != null)
	var main = packed.instance()
	assert(main != null)
	get_root().add_child(main)

func _on_idle_frame() -> void:
	frames += 1
	if frames < 3:
		return
	var main = get_root().get_node_or_null("Main")
	assert(main != null)
	assert(main.screen != null)
	assert(main.telemetry.text.find("FRAMEBUFFER") >= 0)
	print("FREEDOOM_POE_UI_SMOKE_OK")
	quit()
