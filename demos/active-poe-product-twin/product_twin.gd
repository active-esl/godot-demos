extends Spatial

const UX_SIZE := Vector2(1280, 800)
const INSPECT_ROTATION := Vector2(deg2rad(-8.0), deg2rad(-18.0))
const USE_ROTATION := Vector2.ZERO

onready var product_pivot: Spatial = $ProductPivot
onready var camera: Camera = $Camera
onready var ux_viewport: Viewport = $UXViewport
onready var hint: Label = $Chrome/Hint

var use_mode := false
var dragging := false
var rotation_now := INSPECT_ROTATION
var rotation_target := INSPECT_ROTATION
var camera_distance := 0.36
var camera_distance_target := 0.36

func _ready() -> void:
	_apply_live_display_texture()
	_apply_pose()
	print("ACTIVE_POE_PRODUCT_TWIN_READY")

func _process(delta: float) -> void:
	var weight := min(1.0, delta * 8.0)
	rotation_now = rotation_now.linear_interpolate(rotation_target, weight)
	camera_distance = lerp(camera_distance, camera_distance_target, weight)
	_apply_pose()

func _apply_pose() -> void:
	product_pivot.rotation = Vector3(rotation_now.x, 0.0, rotation_now.y)
	camera.translation = Vector3(0.0, camera_distance, 0.0)

func _apply_live_display_texture() -> void:
	var glass := _find_mesh($ProductPivot, "LCD")
	if glass == null:
		push_error("Active POE GLB has no LCD mesh")
		return
	var material := SpatialMaterial.new()
	material.flags_unshaded = true
	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	material.albedo_texture = ux_viewport.get_texture()
	glass.material_override = material

func _find_mesh(node: Node, wanted_name: String) -> MeshInstance:
	if node is MeshInstance and node.name == wanted_name:
		return node as MeshInstance
	for child in node.get_children():
		var found := _find_mesh(child, wanted_name)
		if found != null:
			return found as MeshInstance
	return null

func _on_inspect_pressed() -> void:
	set_use_mode(false)

func _on_use_pressed() -> void:
	set_use_mode(true)

func set_use_mode(enabled: bool) -> void:
	use_mode = enabled
	dragging = false
	rotation_target = USE_ROTATION if enabled else INSPECT_ROTATION
	camera_distance_target = 0.285 if enabled else 0.36
	hint.text = "Tap and swipe the display · choose Inspect product to orbit" if enabled else "Drag to inspect · choose Use display to operate the real room-booking UX"
	$Chrome/ModePanel/Margin/Buttons/Inspect.pressed = not enabled
	$Chrome/ModePanel/Margin/Buttons/Use.pressed = enabled

func _input(event: InputEvent) -> void:
	if _is_chrome_event(event):
		return
	if use_mode:
		_forward_to_ux(event)
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		rotation_target.y += event.relative.x * 0.006
		rotation_target.x = clamp(rotation_target.x + event.relative.y * 0.004, deg2rad(-28.0), deg2rad(24.0))
	elif event is InputEventScreenTouch:
		dragging = event.pressed
	elif event is InputEventScreenDrag and dragging:
		rotation_target.y += event.relative.x * 0.006
		rotation_target.x = clamp(rotation_target.x + event.relative.y * 0.004, deg2rad(-28.0), deg2rad(24.0))

func _is_chrome_event(event: InputEvent) -> bool:
	var position := _event_position(event)
	return position.y >= 0.0 and position.y < 86.0

func _forward_to_ux(event: InputEvent) -> void:
	if not (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):
		ux_viewport.input(event)
		return
	var source_position := _event_position(event)
	var display_rect := _display_rect()
	if not display_rect.has_point(source_position):
		return
	var forwarded := event.duplicate()
	var mapped := (source_position - display_rect.position) / display_rect.size * UX_SIZE
	forwarded.position = mapped
	if forwarded is InputEventMouse:
		forwarded.global_position = mapped
	ux_viewport.input(forwarded)
	get_tree().set_input_as_handled()

func _event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return event.position
	return Vector2(-1.0, -1.0)

func _display_rect() -> Rect2:
	var half_width := 0.1218
	var half_height := 0.0833
	var corners := [
		Vector3(-half_width, 0.012, -half_height),
		Vector3(half_width, 0.012, -half_height),
		Vector3(-half_width, 0.012, half_height),
		Vector3(half_width, 0.012, half_height),
	]
	var first := camera.unproject_position(product_pivot.to_global(corners[0]))
	var minimum := first
	var maximum := first
	for corner in corners:
		var projected := camera.unproject_position(product_pivot.to_global(corner))
		minimum.x = min(minimum.x, projected.x)
		minimum.y = min(minimum.y, projected.y)
		maximum.x = max(maximum.x, projected.x)
		maximum.y = max(maximum.y, projected.y)
	return Rect2(minimum, maximum - minimum)
