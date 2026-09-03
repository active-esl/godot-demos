extends Reference
class_name PoeRaycaster

const MAP := [
	"111111111111",
	"100000000001",
	"102000000001",
	"100001110001",
	"100001000001",
	"100001003001",
	"100000000001",
	"100011100001",
	"100000000001",
	"100000020001",
	"100000000001",
	"111111111111",
]
const WIDTH := 256
const HEIGHT := 160
const FOV := 1.0472

var position := Vector2(2.5, 2.5)
var heading := 0.18
var elapsed := 0.0
var shots := 0
var doors := 0

func step(delta: float, forward: float, turn: float, strafe: float) -> void:
	elapsed += delta
	heading += turn * delta * 1.7
	var direction := Vector2(cos(heading), sin(heading))
	var side := Vector2(-direction.y, direction.x)
	var candidate := position + (direction * forward + side * strafe) * delta * 2.2
	if _open(candidate):
		position = candidate

func fire() -> void:
	shots += 1

func use() -> void:
	doors += 1

func snapshot() -> Dictionary:
	return {"x": position.x, "y": position.y, "heading": heading, "shots": shots, "doors": doors}

func render_frame() -> Image:
	var image := Image.new()
	image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	image.lock()
	for y in range(HEIGHT):
		var shade := int(18 + abs(y - HEIGHT / 2) * 0.20)
		var colour := Color8(7, 17 + shade / 3, 31 + shade, 255) if y < HEIGHT / 2 else Color8(25 + shade / 4, 18, 28, 255)
		for x in range(WIDTH):
			image.set_pixel(x, y, colour)
	for x in range(WIDTH):
		var ray_angle := heading - FOV * 0.5 + FOV * float(x) / float(WIDTH)
		var hit := _cast(ray_angle)
		var corrected := max(0.08, hit.distance * cos(ray_angle - heading))
		var wall_height := min(HEIGHT, int(HEIGHT / corrected))
		var start := max(0, HEIGHT / 2 - wall_height / 2)
		var finish := min(HEIGHT - 1, HEIGHT / 2 + wall_height / 2)
		var pulse := 0.86 + sin(elapsed * 2.0 + hit.distance) * 0.08
		var base := Color("20d6d2") if hit.tile == "2" else Color("7557ff") if hit.tile == "3" else Color("72839a")
		base = base.darkened(clamp(hit.distance / 11.0, 0.05, 0.72)) * pulse
		for y in range(start, finish):
			image.set_pixel(x, y, base)
	# Crosshair lives in the framebuffer; application chrome remains Controls.
	for n in range(-5, 6):
		image.set_pixel(WIDTH / 2 + n, HEIGHT / 2, Color("b6f23b"))
		image.set_pixel(WIDTH / 2, HEIGHT / 2 + n, Color("b6f23b"))
	image.unlock()
	return image

func _cast(angle: float) -> Dictionary:
	var distance := 0.04
	var tile := "1"
	var direction := Vector2(cos(angle), sin(angle))
	while distance < 16.0:
		var sample := position + direction * distance
		var mx := int(sample.x)
		var my := int(sample.y)
		if my < 0 or my >= MAP.size() or mx < 0 or mx >= MAP[my].length():
			break
		tile = MAP[my].substr(mx, 1)
		if tile != "0":
			break
		distance += 0.04
	return {"distance": distance, "tile": tile}

func _open(point: Vector2) -> bool:
	var x := int(point.x)
	var y := int(point.y)
	return y >= 0 and y < MAP.size() and x >= 0 and x < MAP[y].length() and MAP[y].substr(x, 1) == "0"

