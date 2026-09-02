extends Node2D

# Elanco-inspired concept UI using simulated values only.
# Designed for Godot 3.6 GLES2 and a compositor-provided landscape output.

const DESIGN_SIZE = Vector2(1920, 1200)
const NAV_HEIGHT = 132.0
const PAGE_NAMES = ["PROCESS", "ASSET", "QUALITY"]

const INK = Color("172033")
const MUTED = Color("657087")
const PAPER = Color("f4f6f8")
const WHITE = Color("ffffff")
const PURPLE = Color("5b2b82")
const PURPLE_DARK = Color("35164f")
const AQUA = Color("00a6a6")
const GREEN = Color("57a773")
const AMBER = Color("f3a712")
const RED = Color("d94b4b")
const BLUE = Color("2878b5")
const LINE = Color("d8dee8")

var fonts_regular = {}
var fonts_bold = {}
var page = 0
var elapsed = 0.0
var drag_active = false
var drag_start = Vector2()
var drag_last = Vector2()
var drag_offset = 0.0
var mouse_drag = false
var selected_asset = 1
var temperature_setpoint = 37.0
var mixing_enabled = true
var batch_progress = 0.64
var touch_points = {}
var last_interaction = 0.0

func _ready():
    var sizes = [16, 17, 18, 20, 21, 22, 23, 24, 25, 30, 32, 36, 38, 42, 52]
    for size in sizes:
        fonts_regular[size] = make_font(size, false)
        fonts_bold[size] = make_font(size, true)
    set_process(true)
    set_process_input(true)
    print("ELANCO_TWIN_READY screen=%s window=%s" % [OS.get_screen_size(), OS.window_size])

func make_font(size, bold):
    var filename = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    var data = load("res://fonts/" + filename)
    var result = DynamicFont.new()
    result.font_data = data
    result.size = size
    result.use_filter = true
    return result

func _process(delta):
    elapsed += delta
    if mixing_enabled:
        batch_progress = fmod(batch_progress + delta * 0.0016, 1.0)
    if not drag_active:
        drag_offset = lerp(drag_offset, 0.0, min(1.0, delta * 12.0))
    update()

func to_design(position):
    var viewport_size = get_viewport_rect().size
    return Vector2(position.x * DESIGN_SIZE.x / viewport_size.x,
                   position.y * DESIGN_SIZE.y / viewport_size.y)

func _input(event):
    if event is InputEventScreenTouch:
        var p = to_design(event.position)
        if event.pressed:
            touch_points[event.index] = p
            print("ELANCO_TOUCH_DOWN index=%d position=%s" % [event.index, p])
            begin_drag(p)
        else:
            touch_points.erase(event.index)
            end_drag(p)
            print("ELANCO_TOUCH_UP index=%d page=%d" % [event.index, page])
        get_tree().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var p = to_design(event.position)
        touch_points[event.index] = p
        update_drag(p)
        get_tree().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
        var p = to_design(event.position)
        mouse_drag = event.pressed
        if event.pressed:
            begin_drag(p)
        else:
            end_drag(p)
    elif event is InputEventMouseMotion and mouse_drag:
        update_drag(to_design(event.position))

func begin_drag(p):
    last_interaction = elapsed
    drag_active = true
    drag_start = p
    drag_last = p
    drag_offset = 0.0

func update_drag(p):
    drag_last = p
    var dx = p.x - drag_start.x
    var dy = p.y - drag_start.y
    if abs(dx) > abs(dy):
        drag_offset = dx
    if page == 1 and abs(dx) < 60.0 and p.y > 880.0 and p.y < 990.0:
        temperature_setpoint = clamp(32.0 + (p.x - 420.0) / 1020.0 * 10.0, 32.0, 42.0)

func end_drag(p):
    var delta = p - drag_start
    drag_active = false
    if abs(delta.x) > 170.0 and abs(delta.x) > abs(delta.y):
        if delta.x < 0.0:
            page = min(page + 1, PAGE_NAMES.size() - 1)
        else:
            page = max(page - 1, 0)
    elif delta.length() < 45.0:
        handle_tap(p)
    drag_offset = 0.0

func handle_tap(p):
    if p.y > DESIGN_SIZE.y - NAV_HEIGHT:
        page = int(clamp(floor(p.x / (DESIGN_SIZE.x / 3.0)), 0, 2))
        return
    if page == 0:
        if p.x > 120.0 and p.x < 1740.0 and p.y > 390.0 and p.y < 875.0:
            selected_asset = int(clamp(floor((p.x - 120.0) / 540.0), 0, 2))
            page = 1
    elif page == 1:
        if Rect2(1500, 870, 250, 100).has_point(p):
            mixing_enabled = not mixing_enabled

func _draw():
    var viewport_size = get_viewport_rect().size
    var scale = Vector2(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
    draw_set_transform(Vector2(), 0.0, scale)
    draw_rect(Rect2(Vector2(), DESIGN_SIZE), PAPER)
    draw_header()
    draw_page(page, drag_offset)
    if drag_offset < 0.0 and page < 2:
        draw_page(page + 1, DESIGN_SIZE.x + drag_offset)
    elif drag_offset > 0.0 and page > 0:
        draw_page(page - 1, -DESIGN_SIZE.x + drag_offset)
    draw_navigation()
    draw_touch_feedback()

func draw_header():
    draw_rect(Rect2(0, 0, 1920, 154), WHITE)
    draw_rect(Rect2(0, 150, 1920, 4), PURPLE)
    draw_rect(Rect2(54, 38, 14, 72), AMBER)
    draw_rect(Rect2(72, 38, 14, 72), GREEN)
    draw_rect(Rect2(90, 38, 14, 72), AQUA)
    text("elanco", Vector2(128, 92), 52, PURPLE_DARK, true)
    text("MANUFACTURING DIGITAL TWIN", Vector2(380, 88), 32, INK, true)
    text("CONCEPT DEMONSTRATION  •  SIMULATED DATA", Vector2(380, 124), 21, MUTED, false)
    pill(Rect2(1570, 46, 290, 62), "●  LINE HEALTHY", GREEN, WHITE)

func draw_page(which, offset_x):
    if which == 0:
        draw_process_page(offset_x)
    elif which == 1:
        draw_asset_page(offset_x)
    else:
        draw_quality_page(offset_x)

func draw_process_page(x):
    section_title(x, "Speke Site  •  Batch A24-0902", "Live process overview")
    var y = 344.0
    draw_pipe(Vector2(x + 340, y + 255), Vector2(x + 760, y + 255), AQUA)
    draw_pipe(Vector2(x + 1125, y + 255), Vector2(x + 1510, y + 255), AQUA)
    process_card(Rect2(x + 100, y, 430, 510), 0, "RAW MATERIAL", "Feed vessel V-101")
    process_card(Rect2(x + 745, y, 430, 510), 1, "BIOREACTOR", "Reactor R-204")
    process_card(Rect2(x + 1390, y, 430, 510), 2, "FILL & FINISH", "Line FL-03")
    metric_strip(x, 900)

func process_card(rect, index, title, subtitle):
    card(rect, selected_asset == index)
    text(title, rect.position + Vector2(30, 54), 25, PURPLE_DARK, true)
    text(subtitle, rect.position + Vector2(30, 91), 21, MUTED, false)
    var center = rect.position + Vector2(rect.size.x / 2.0, 245)
    if index < 2:
        draw_vessel(center, 115.0, index == 1)
    else:
        draw_filling_line(center)
    var value = 0.0
    var unit = ""
    if index == 0:
        value = 72.0 + sin(elapsed * 0.45) * 2.0
        unit = "% LEVEL"
    elif index == 1:
        value = temperature_setpoint + sin(elapsed * 0.7) * 0.3
        unit = "°C"
    else:
        value = 118.0 + sin(elapsed * 0.8) * 4.0
        unit = "VIALS/MIN"
    var maximum = 100.0 if index == 0 else (45.0 if index == 1 else 150.0)
    gauge(center + Vector2(0, 143), 74, value, maximum, unit)
    text("TOUCH FOR DETAIL", rect.position + Vector2(30, rect.size.y - 24), 18, AQUA, true)

func draw_vessel(center, radius, agitator):
    draw_rect(Rect2(center.x - radius, center.y - 115, radius * 2, 220), Color("e4edf1"))
    draw_circle(Vector2(center.x, center.y - 115), radius, Color("e4edf1"))
    draw_circle(Vector2(center.x, center.y + 105), radius, Color("c9dde3"))
    draw_rect(Rect2(center.x - radius + 12, center.y + 25, radius * 2 - 24, 80), Color(0.0, 0.65, 0.65, 0.35))
    draw_line(Vector2(center.x, center.y - 188), Vector2(center.x, center.y + 58), PURPLE, 10)
    if agitator:
        var angle = elapsed * (3.0 if mixing_enabled else 0.0)
        var arm = Vector2(cos(angle), sin(angle)) * 70.0
        draw_line(Vector2(center.x, center.y + 40) - arm, Vector2(center.x, center.y + 40) + arm, PURPLE, 12)
    draw_line(Vector2(center.x - 60, center.y + 190), Vector2(center.x - 40, center.y + 105), INK, 10)
    draw_line(Vector2(center.x + 60, center.y + 190), Vector2(center.x + 40, center.y + 105), INK, 10)

func draw_filling_line(center):
    draw_rect(Rect2(center.x - 160, center.y + 80, 320, 22), INK)
    for i in range(4):
        var bx = center.x - 135 + i * 90 + fmod(elapsed * 35.0, 80.0)
        draw_rect(Rect2(bx, center.y + 20, 34, 60), Color("dce9f2"))
        draw_rect(Rect2(bx + 5, center.y + 8, 24, 14), AQUA)
    draw_rect(Rect2(center.x - 95, center.y - 118, 190, 90), PURPLE)
    for i in range(3):
        draw_line(Vector2(center.x - 65 + i * 65, center.y - 28), Vector2(center.x - 65 + i * 65, center.y + 12), AMBER, 8)

func metric_strip(x, y):
    var labels = ["BATCH COMPLETE", "QUALITY SCORE", "OEE", "NEXT SAMPLE"]
    var values = ["%d%%" % int(batch_progress * 100.0), "98.7%", "91.4%", "08:42"]
    for i in range(4):
        var r = Rect2(x + 100 + i * 430, y, 390, 104)
        card(r, false)
        text(labels[i], r.position + Vector2(22, 35), 18, MUTED, true)
        text(values[i], r.position + Vector2(22, 82), 36, PURPLE_DARK, true)

func draw_asset_page(x):
    section_title(x, "Reactor R-204", "Asset detail  •  swipe or drag the setpoint")
    card(Rect2(x + 90, 320, 570, 670), false)
    text("LIVE DIGITAL ASSET", Vector2(x + 130, 375), 22, MUTED, true)
    draw_vessel(Vector2(x + 375, 610), 160, true)
    pill(Rect2(x + 180, 875, 390, 62), "AGITATOR  •  RUNNING" if mixing_enabled else "AGITATOR  •  PAUSED", GREEN if mixing_enabled else AMBER, WHITE)
    card(Rect2(x + 700, 320, 1120, 500), false)
    text("PROCESS TREND  •  LAST 30 MIN", Vector2(x + 750, 375), 22, MUTED, true)
    draw_trend(Rect2(x + 760, 420, 1000, 320))
    card(Rect2(x + 700, 850, 1120, 140), false)
    text("TEMPERATURE SETPOINT", Vector2(x + 750, 902), 21, MUTED, true)
    draw_line(Vector2(x + 850, 952), Vector2(x + 1440, 952), LINE, 18)
    var knob_x = x + 850 + (temperature_setpoint - 32.0) / 10.0 * 590.0
    draw_line(Vector2(x + 850, 952), Vector2(knob_x, 952), AQUA, 18)
    draw_circle(Vector2(knob_x, 952), 30, WHITE)
    draw_circle(Vector2(knob_x, 952), 22, PURPLE)
    text("%.1f °C" % temperature_setpoint, Vector2(x + 1510, 966), 38, PURPLE_DARK, true)
    pill(Rect2(x + 1500, 870, 250, 100), "PAUSE" if mixing_enabled else "START", PURPLE, WHITE)

func draw_trend(rect):
    for i in range(5):
        var gy = rect.position.y + i * rect.size.y / 4.0
        draw_line(Vector2(rect.position.x, gy), Vector2(rect.end.x, gy), LINE, 2)
    var temp_points = PoolVector2Array()
    var pressure_points = PoolVector2Array()
    for i in range(80):
        var px = rect.position.x + float(i) / 79.0 * rect.size.x
        temp_points.append(Vector2(px, rect.position.y + 115 + sin(float(i) * 0.18 + elapsed * 0.7) * 28))
        pressure_points.append(Vector2(px, rect.position.y + 225 + sin(float(i) * 0.13 + elapsed * 0.45) * 34))
    draw_polyline(temp_points, PURPLE, 7, true)
    draw_polyline(pressure_points, AQUA, 7, true)
    text("Temperature  %.1f °C" % (temperature_setpoint + sin(elapsed * 0.7) * 0.3), rect.position + Vector2(20, 42), 22, PURPLE, true)
    text("Pressure  %.2f bar" % (1.82 + sin(elapsed * 0.45) * 0.04), rect.position + Vector2(610, 42), 22, AQUA, true)

func draw_quality_page(x):
    section_title(x, "Quality & Resource Performance", "Manufacturing insight  •  simulated site data")
    kpi_card(Rect2(x + 90, 320, 400, 240), "RIGHT FIRST TIME", "98.7%", "+0.8%", GREEN)
    kpi_card(Rect2(x + 530, 320, 400, 240), "ENERGY / BATCH", "1.42 MWh", "−6.2%", AQUA)
    kpi_card(Rect2(x + 970, 320, 400, 240), "WATER / BATCH", "18.6 m³", "−4.1%", BLUE)
    kpi_card(Rect2(x + 1410, 320, 400, 240), "BATCH YIELD", "96.8%", "+1.3%", PURPLE)
    card(Rect2(x + 90, 610, 1060, 370), false)
    text("BATCH QUALITY GATE", Vector2(x + 140, 675), 25, PURPLE_DARK, true)
    quality_row(x + 140, 740, "Identity & potency", 0.99)
    quality_row(x + 140, 815, "Sterility assurance", 0.97)
    quality_row(x + 140, 890, "Fill-weight conformity", 0.94)
    card(Rect2(x + 1190, 610, 620, 370), false)
    text("OPERATIONAL INSIGHT", Vector2(x + 1240, 675), 25, PURPLE_DARK, true)
    draw_circle(Vector2(x + 1270, 750), 12, GREEN)
    text("All critical parameters in control", Vector2(x + 1300, 760), 22, INK, false)
    draw_circle(Vector2(x + 1270, 825), 12, AMBER)
    text("CIP water use trending above plan", Vector2(x + 1300, 835), 22, INK, false)
    draw_circle(Vector2(x + 1270, 900), 12, AQUA)
    text("Suggested: optimise rinse stage 3", Vector2(x + 1300, 910), 22, INK, false)

func kpi_card(rect, label, value, change, accent):
    card(rect, false)
    draw_rect(Rect2(rect.position, Vector2(12, rect.size.y)), accent)
    text(label, rect.position + Vector2(36, 58), 20, MUTED, true)
    text(value, rect.position + Vector2(36, 132), 42, PURPLE_DARK, true)
    pill(Rect2(rect.position + Vector2(36, 164), Vector2(145, 52)), change, accent, WHITE)

func quality_row(x, y, label, value):
    text(label, Vector2(x, y), 22, INK, false)
    draw_rect(Rect2(x + 390, y - 24, 520, 24), LINE)
    draw_rect(Rect2(x + 390, y - 24, 520 * value, 24), GREEN if value > 0.96 else AQUA)
    text("%d%%" % int(value * 100.0), Vector2(x + 930, y), 22, PURPLE_DARK, true)

func draw_navigation():
    draw_rect(Rect2(0, DESIGN_SIZE.y - NAV_HEIGHT, DESIGN_SIZE.x, NAV_HEIGHT), WHITE)
    draw_line(Vector2(0, DESIGN_SIZE.y - NAV_HEIGHT), Vector2(DESIGN_SIZE.x, DESIGN_SIZE.y - NAV_HEIGHT), LINE, 3)
    for i in range(3):
        var x = i * DESIGN_SIZE.x / 3.0
        if i == page:
            draw_rect(Rect2(x + 70, DESIGN_SIZE.y - 12, DESIGN_SIZE.x / 3.0 - 140, 8), PURPLE)
        text(PAGE_NAMES[i], Vector2(x + 245, DESIGN_SIZE.y - 54), 23, PURPLE if i == page else MUTED, true)
    text("‹  SWIPE  ›", Vector2(860, DESIGN_SIZE.y - 96), 17, MUTED, true)

func draw_touch_feedback():
    for key in touch_points:
        var p = touch_points[key]
        draw_circle(p, 38, Color(0.0, 0.65, 0.65, 0.18))
        draw_arc(p, 38, 0, PI * 2, 40, AQUA, 4)

func section_title(x, title, subtitle):
    text(title, Vector2(x + 90, 230), 42, PURPLE_DARK, true)
    text(subtitle, Vector2(x + 90, 278), 24, MUTED, false)

func card(rect, selected):
    draw_rect(Rect2(rect.position + Vector2(0, 8), rect.size), Color(0.1, 0.12, 0.18, 0.08))
    draw_rect(rect, WHITE)
    if selected:
        draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), AQUA)

func draw_pipe(a, b, color):
    draw_line(a, b, Color("b9c5d1"), 30)
    draw_line(a, b, color, 12)
    var t = fmod(elapsed * 0.22, 1.0)
    draw_circle(a.linear_interpolate(b, t), 15, WHITE)

func gauge(center, radius, value, maximum, unit):
    draw_arc(center, radius, PI * 0.75, PI * 2.25, 54, LINE, 16)
    var fraction = clamp(value / maximum, 0.0, 1.0)
    draw_arc(center, radius, PI * 0.75, PI * (0.75 + 1.5 * fraction), 54, AQUA, 16)
    text("%.1f" % value, center + Vector2(-62, 10), 30, PURPLE_DARK, true)
    text(unit, center + Vector2(-58, 40), 16, MUTED, true)

func pill(rect, label, color, foreground):
    draw_rect(rect, color)
    var size = fonts_bold[22].get_string_size(label)
    text(label, Vector2(rect.position.x + (rect.size.x - size.x) / 2.0, rect.position.y + rect.size.y / 2.0 + 11), 22, foreground, true)

func text(value, position, size, color, bold):
    var font = fonts_bold[size] if bold else fonts_regular[size]
    draw_string(font, position, value, color)
