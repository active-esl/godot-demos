extends Control

const ScenarioModel = preload("res://scripts/scenario_model.gd")
const BG := Color("0a0e0d")
const PANEL := Color("141b18")
const PANEL_ALT := Color("1d2723")
const INK := Color("eef3f0")
const MUTED := Color("a5b1ab")
const GREEN := Color("64d8a4")
const AMBER := Color("e9b35c")
const RED := Color("ee6268")
const CYAN := Color("68bfe8")

const TEXT := {
	"en": {
		"title":"MAX TABLET", "subtitle":"RESILIENT TACTICAL PICTURE // EXERCISE ORION",
		"map_title":"LIVE OPERATIONAL VIEW", "team":"TEAM ALPHA", "online":"05 ONLINE",
		"incident":"INCIDENT STATUS", "reset":"RESET", "previous":"‹ PREVIOUS", "next":"NEXT EVENT  ›",
		"simulated":"● EXERCISE • SIMULATED", "position":"POSITION", "bearer":"BEARER", "battery":"BATTERY",
		"updated":"UPDATED", "source":"SOURCE", "seconds":"s ago", "profile":"UK PROFILE",
		"team_lead":"TEAM LEAD", "medic":"MEDIC", "comms":"COMMS", "specialist":"SPECIALIST", "support":"SUPPORT",
		"row_active":"ACTIVE", "row_man_down":"MAN DOWN", "row_evacuation":"EVAC",
		"bearer_ready":"MESH 05  •  UWB 05  •  PRIMARY READY  •  QUEUE 00",
		"bearer_lost":"PRIMARY LOST  •  LOCAL ACTIVE  •  QUEUE 03",
		"bearer_restored":"PRIMARY RESTORED  •  SYNC COMPLETE  •  QUEUE 00",
		"fusion_normal":"LOCAL FUSION  •  1.8 m MEDIAN", "fusion_low":"LOCAL FUSION  •  6.8 m CONFIDENCE", "fusion_improving":"LOCAL FUSION  •  3.4 m CONFIDENCE",
		"confidence":"radius", "hours":"h", "active":"ACTIVE", "man_down":"MAN DOWN", "evacuation":"EVACUATION",
		"fused":"FUSED", "estimated":"ESTIMATED",
		"deployment":["TEAM DEPLOYED", "5 personnel tracked • all systems nominal", "DEPLOYMENT"],
		"mesh_ready":["MESH ESTABLISHED", "Ad-hoc network formed in 42 seconds", "MESH FORMATION"],
		"link_degraded":["PRIMARY LINK DEGRADED", "Local picture maintained • alternate bearers active", "COMMS DEGRADATION"],
		"indoor_tracking":["GNSS LOST — RAVEN 4", "UWB mesh estimate active • confidence 6.8 m", "INDOOR TRACKING"],
		"casualty_alert":["MAN DOWN — RAVEN 4", "Priority alert received • location confidence improving", "PRIORITY ALERT"],
		"extraction":["EXTRACTION ASSIGNED", "Route shared locally • team acknowledged", "CASUALTY EVACUATION"],
		"sync_restored":["LINK RESTORED", "Incident record synchronised • no events lost", "RECOVERY & SYNC"]
	},
	"fr": {
		"title":"MAX TABLET", "subtitle":"SITUATION TACTIQUE RÉSILIENTE // EXERCICE ORION",
		"map_title":"VUE OPÉRATIONNELLE EN DIRECT", "team":"ÉQUIPE ALPHA", "online":"05 EN LIGNE",
		"incident":"ÉTAT DE L’INCIDENT", "reset":"RÉINITIALISER", "previous":"‹ PRÉCÉDENT", "next":"ÉVÉNEMENT SUIVANT  ›",
		"simulated":"● EXERCICE • DONNÉES SIMULÉES", "position":"POSITION", "bearer":"LIAISON", "battery":"BATTERIE",
		"updated":"ACTUALISÉ", "source":"SOURCE", "seconds":"s", "profile":"PROFIL FRANCE",
		"team_lead":"CHEF D’ÉQUIPE", "medic":"AUXILIAIRE SANITAIRE", "comms":"TRANSMISSIONS", "specialist":"SPÉCIALISTE", "support":"APPUI",
		"row_active":"ACTIF", "row_man_down":"À TERRE", "row_evacuation":"ÉVAC.",
		"bearer_ready":"MAILLE 05  •  UWB 05  •  LIAISON PRÊTE  •  FILE 00",
		"bearer_lost":"LIAISON PERDUE  •  LOCAL ACTIF  •  FILE 03",
		"bearer_restored":"LIAISON RÉTABLIE  •  SYNCHRO TERMINÉE  •  FILE 00",
		"fusion_normal":"FUSION LOCALE  •  MÉDIANE 1,8 m", "fusion_low":"FUSION LOCALE  •  FIABILITÉ 6,8 m", "fusion_improving":"FUSION LOCALE  •  FIABILITÉ 3,4 m",
		"confidence":"de rayon", "hours":"h", "active":"ACTIF", "man_down":"HOMME À TERRE", "evacuation":"ÉVACUATION",
		"fused":"FUSIONNÉE", "estimated":"ESTIMÉE",
		"deployment":["ÉQUIPE DÉPLOYÉE", "5 personnes suivies • systèmes opérationnels", "DÉPLOIEMENT"],
		"mesh_ready":["RÉSEAU MAILLÉ ÉTABLI", "Réseau ad hoc formé en 42 secondes", "FORMATION DU RÉSEAU"],
		"link_degraded":["LIAISON PRINCIPALE DÉGRADÉE", "Vue locale maintenue • liaisons alternatives actives", "DÉGRADATION DES COMMS"],
		"indoor_tracking":["GNSS PERDU — RAVEN 4", "Estimation UWB active • fiabilité 6,8 m", "LOCALISATION INTÉRIEURE"],
		"casualty_alert":["HOMME À TERRE — RAVEN 4", "Alerte prioritaire reçue • fiabilité en amélioration", "ALERTE PRIORITAIRE"],
		"extraction":["ÉVACUATION AFFECTÉE", "Itinéraire partagé localement • équipe informée", "ÉVACUATION DU BLESSÉ"],
		"sync_restored":["LIAISON RÉTABLIE", "Journal synchronisé • aucun événement perdu", "REPRISE ET SYNCHRONISATION"]
	}
}

onready var top_bar := $Layout/TopBar
onready var content := $Layout/ContentMargin/Content
onready var map_column := $Layout/ContentMargin/Content/MapColumn
onready var side_panel := $Layout/ContentMargin/Content/SidePanel
onready var map = $Layout/ContentMargin/Content/MapColumn/Map
onready var team_list := $Layout/ContentMargin/Content/SidePanel/TeamList
onready var incident_card := $Layout/ContentMargin/Content/SidePanel/IncidentCard
onready var selected_card := $Layout/ContentMargin/Content/SidePanel/SelectedCard
onready var language_button := $Layout/TopBar/Language
onready var next_button := $Layout/BottomBar/Next
onready var previous_button := $Layout/BottomBar/Previous
onready var reset_button := $Layout/BottomBar/Reset

var model
var regular: DynamicFont
var bold: DynamicFont
var clock_seconds := 52328
var clock_timer: Timer
var layout_mode := "landscape"
var responsive_scale := 1.0
var last_window_size := Vector2.ZERO

func _ready() -> void:
	model = ScenarioModel.new()
	model.reset()
	_apply_demo_overrides()
	_build_fonts()
	_apply_layout_style()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_apply_responsive_layout(OS.get_window_size())
	map.connect("person_selected", self, "_on_person_selected")
	language_button.connect("pressed", self, "_toggle_language")
	next_button.connect("pressed", self, "_next")
	previous_button.connect("pressed", self, "_previous")
	reset_button.connect("pressed", self, "_reset")
	clock_timer = Timer.new()
	clock_timer.wait_time = 1.0
	clock_timer.connect("timeout", self, "_tick")
	add_child(clock_timer)
	clock_timer.start()
	_refresh()
	print("RESILIENT_TACTICAL_PICTURE_READY")

func _on_viewport_size_changed() -> void:
	_apply_responsive_layout(OS.get_window_size())

func _apply_responsive_layout(window_size: Vector2) -> void:
	if window_size == last_window_size:
		return
	last_window_size = window_size
	# The project preserves its 1920-wide logical canvas when the browser or
	# native window narrows. Compensate so type and controls retain a useful
	# physical size instead of shrinking with that canvas.
	responsive_scale = max(1.0, 1920.0 / max(window_size.x, 1.0))
	var portrait := window_size.y > window_size.x
	var narrow := window_size.x < 900.0
	var compact := narrow or window_size.y < 1000.0
	layout_mode = "portrait_compact" if portrait and compact else "portrait" if portrait else "landscape_compact" if compact else "landscape"
	content.columns = 1 if portrait else 2
	content.add_constant_override("hseparation", _scaled(20))
	content.add_constant_override("vseparation", _scaled(14))
	map_column.rect_min_size = Vector2(0, _scaled(470 if compact and portrait else 620 if portrait else 0))
	side_panel.rect_min_size = Vector2(0 if portrait else _scaled(390 if compact else 505), _scaled(350) if compact and portrait else 0)
	team_list.visible = not compact
	$Layout/ContentMargin/Content/SidePanel/TeamHeader.visible = not compact
	$Layout/TopBar/BearerSummary.visible = not narrow
	$Layout/TopBar/Clock.visible = not portrait
	$Layout/BottomBar/ScenarioLabel.visible = not narrow
	$Layout/BottomBar/SimulationBadge.visible = not portrait and not compact
	top_bar.rect_min_size.y = _scaled(92 if compact else 116)
	$Layout/BottomBar.rect_min_size.y = _scaled(92 if compact else 112)
	$Layout/TopBar/Brand.rect_min_size.x = 0 if narrow else _scaled(360 if portrait else 540)
	$Layout/TopBar/BearerSummary.rect_min_size.x = _scaled(360 if portrait else 520 if compact else 620)
	language_button.rect_min_size = Vector2(_scaled(112 if narrow else 132), _scaled(60 if compact else 68))
	reset_button.rect_min_size = Vector2(_scaled(112 if narrow else 150), _scaled(64 if compact else 72))
	previous_button.rect_min_size = Vector2(_scaled(145 if narrow else 180), _scaled(64 if compact else 72))
	next_button.rect_min_size = Vector2(_scaled(195 if narrow else 250), _scaled(64 if compact else 72))
	$Layout/BottomBar/ScenarioLabel.rect_min_size.x = _scaled(300)
	$Layout/ContentMargin.add_constant_override("margin_left", _scaled(14 if compact else 26))
	$Layout/ContentMargin.add_constant_override("margin_right", _scaled(14 if compact else 26))
	$Layout/ContentMargin.add_constant_override("margin_top", _scaled(10 if compact else 18))
	$Layout/ContentMargin.add_constant_override("margin_bottom", _scaled(10 if compact else 18))
	$Layout/TopBar/Brand/Title.add_font_override("font", _font(_scaled(22 if narrow else 27 if portrait else 31), true))
	$Layout/TopBar/Brand/Subtitle.add_font_override("font", _font(_scaled(14 if compact else 17), true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard.rect_min_size.y = _scaled(150 if compact else 164)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard.rect_min_size.y = _scaled(180 if compact else 196)
	_apply_responsive_typography(compact)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.visible = not narrow
	for button in [language_button, next_button, previous_button, reset_button]:
		button.add_font_override("font", _font(_scaled(14 if narrow else 16 if compact else 18), true))
	_refresh_team()
	map.set_ui_scale(responsive_scale)

func _apply_responsive_typography(compact: bool) -> void:
	$Layout/TopBar/BearerSummary.add_font_override("font", _font(_scaled(16 if compact else 18), true))
	$Layout/TopBar/Clock.add_font_override("font", _font(_scaled(18 if compact else 22), true))
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.add_font_override("font", _font(_scaled(16 if compact else 19), true))
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.add_font_override("font", _font(_scaled(14 if compact else 17), true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.add_font_override("font", _font(_scaled(13 if compact else 15), true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.add_font_override("font", _font(_scaled(22 if compact else 27), true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.add_font_override("font", _font(_scaled(15 if compact else 17), false))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedName.add_font_override("font", _font(_scaled(23 if compact else 28), true))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_font_override("font", _font(_scaled(15 if compact else 17), true))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.add_font_override("font", _font(_scaled(15 if compact else 18), false))
	$Layout/BottomBar/ScenarioLabel.add_font_override("font", _font(_scaled(16 if compact else 18), true))
	$Layout/BottomBar/SimulationBadge.add_font_override("font", _font(_scaled(14 if compact else 16), true))

func _scaled(value: int) -> int:
	return int(round(float(value) * responsive_scale))

func _apply_demo_overrides() -> void:
	# Optional deterministic state for review captures and automated visual checks.
	var requested_profile := OS.get_environment("TACTICAL_DEMO_PROFILE")
	if requested_profile == "uk" or requested_profile == "fr":
		model.profile = requested_profile
	var requested_beat := OS.get_environment("TACTICAL_DEMO_BEAT")
	if requested_beat.is_valid_integer():
		model.beat = clamp(int(requested_beat), 0, model.BEATS.size() - 1)
		model.selected_id = model.BEATS[model.beat].selected

func _build_fonts() -> void:
	regular = DynamicFont.new()
	regular.font_data = load("res://fonts/DejaVuSans.ttf")
	regular.size = 23
	bold = DynamicFont.new()
	bold.font_data = load("res://fonts/DejaVuSans-Bold.ttf")
	bold.size = 23
	add_font_override("font", regular)

func _apply_layout_style() -> void:
	_set_margins(top_bar, 28, 20)
	_set_margins($Layout/BottomBar, 28, 20)
	$Layout/TopBar/Brand/Title.add_font_override("font", _font(31, true))
	$Layout/TopBar/Brand/Title.add_color_override("font_color", INK)
	$Layout/TopBar/Brand/Subtitle.add_font_override("font", _font(17, true))
	$Layout/TopBar/Brand/Subtitle.add_color_override("font_color", GREEN)
	$Layout/TopBar/BearerSummary.add_font_override("font", _font(18, true))
	$Layout/TopBar/BearerSummary.add_color_override("font_color", GREEN)
	$Layout/TopBar/Clock.add_font_override("font", _font(22, true))
	$Layout/TopBar/Clock.add_color_override("font_color", INK)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.add_font_override("font", _font(19, true))
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.add_color_override("font_color", INK)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.add_font_override("font", _font(17, true))
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.add_color_override("font_color", CYAN)
	for card in [incident_card, selected_card]:
		card.add_stylebox_override("panel", _box(PANEL_ALT, Color("234b43"), 10))
		_set_margins(card, 18, 16)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.add_font_override("font", _font(15, true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.add_color_override("font_color", MUTED)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.add_font_override("font", _font(27, true))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.add_font_override("font", _font(17, false))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.add_color_override("font_color", MUTED)
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamTitle.add_font_override("font", _font(19, true))
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamCount.add_font_override("font", _font(16, true))
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamCount.add_color_override("font_color", GREEN)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedName.add_font_override("font", _font(28, true))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_font_override("font", _font(17, true))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_color_override("font_color", GREEN)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.add_font_override("font", _font(18, false))
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.add_color_override("font_color", MUTED)
	$Layout/BottomBar/ScenarioLabel.add_font_override("font", _font(18, true))
	$Layout/BottomBar/ScenarioLabel.add_color_override("font_color", MUTED)
	$Layout/BottomBar/SimulationBadge.add_font_override("font", _font(16, true))
	$Layout/BottomBar/SimulationBadge.add_color_override("font_color", CYAN)
	for button in [language_button, next_button, previous_button, reset_button]: _style_button(button)
	next_button.add_stylebox_override("normal", _box(GREEN, GREEN, 8))
	next_button.add_color_override("font_color", BG)

func _refresh() -> void:
	var t: Dictionary = TEXT[_language()]
	var beat: Dictionary = model.current()
	var story: Array = t[beat.key]
	$Layout/TopBar/Brand/Title.text = t.title
	$Layout/TopBar/Brand/Subtitle.text = t.subtitle
	$Layout/TopBar/Language.text = "FR · FR" if model.profile == "uk" else "UK · EN"
	$Layout/TopBar/BearerSummary.text = _bearer_summary()
	$Layout/TopBar/BearerSummary.add_color_override("font_color", AMBER if model.beat >= 2 and model.beat < 6 else GREEN)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.text = t.map_title
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.text = _map_mode()
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.text = t.incident
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.text = story[0]
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.add_color_override("font_color", RED if model.beat == 4 else AMBER if model.beat >= 2 and model.beat < 6 else INK)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.text = story[1]
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamTitle.text = t.team
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamCount.text = t.online
	$Layout/BottomBar/ScenarioLabel.text = "%02d / %02d  •  %s" % [model.beat + 1, model.BEATS.size(), story[2]]
	$Layout/BottomBar/SimulationBadge.text = t.simulated
	reset_button.text = t.reset
	previous_button.text = t.previous
	next_button.text = t.next
	previous_button.disabled = model.beat == 0
	next_button.disabled = model.beat == model.BEATS.size() - 1
	_refresh_team()
	_refresh_selected()
	map.configure(model.all_people(), model.selected_id, model.beat, model.profile)

func _refresh_team() -> void:
	var t: Dictionary = TEXT[_language()]
	for child in team_list.get_children(): child.queue_free()
	for person in model.all_people():
		var button := Button.new()
		button.rect_min_size = Vector2(0, _scaled(70))
		button.align = Button.ALIGN_LEFT
		var status_key: String = "row_%s" % person.status
		button.text = "  ●  %s     %s     %d%%" % [person.call, t[status_key], person.battery]
		button.add_font_override("font", _font(_scaled(18), true))
		var color: Color = RED if person.status == "man_down" else AMBER if person.status == "evacuation" else GREEN
		button.add_color_override("font_color", color if person.id == model.selected_id else INK)
		button.add_stylebox_override("normal", _box(PANEL_ALT if person.id == model.selected_id else PANEL, color if person.id == model.selected_id else Color("1d3934"), 7))
		button.connect("pressed", self, "_on_person_selected", [person.id])
		team_list.add_child(button)

func _refresh_selected() -> void:
	var t: Dictionary = TEXT[_language()]
	var p: Dictionary = model.person_state(model.selected_id)
	var status_key: String = p.status
	var status: String = t[status_key]
	var decimal: String = ("%.1f" % p.confidence).replace(".", ",") if _language() == "fr" else "%.1f" % p.confidence
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedName.text = p.call
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.text = "%s  •  %s" % [t[p.role_key], status]
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_color_override("font_color", RED if p.status == "man_down" else AMBER if p.status == "evacuation" else GREEN)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.text = "%s   %s m %s\n%s     %s\n%s    %d%%  •  %d %s\n%s    %d %s  •  %s %s" % [t.position, decimal, t.confidence, t.bearer, p.bearer, t.battery, p.battery, 12 + int(p.battery / 16), t.hours, t.updated, p.age_seconds, t.seconds, t.source, t[p.source.to_lower()]]

func _bearer_summary() -> String:
	var t: Dictionary = TEXT[_language()]
	if model.beat >= 2 and model.beat < 6: return t.bearer_lost
	if model.beat == 6: return t.bearer_restored
	return t.bearer_ready

func _map_mode() -> String:
	var t: Dictionary = TEXT[_language()]
	if model.beat == 3: return t.fusion_low
	if model.beat >= 4 and model.beat < 6: return t.fusion_improving
	return t.fusion_normal

func _toggle_language() -> void:
	model.profile = "fr" if model.profile == "uk" else "uk"
	_refresh()

func _language() -> String:
	return "fr" if model.profile == "fr" else "en"

func _next() -> void:
	model.next()
	_refresh()

func _previous() -> void:
	model.previous()
	_refresh()

func _reset() -> void:
	model.reset()
	_refresh()

func _on_person_selected(person_id: String) -> void:
	model.selected_id = person_id
	_refresh()

func _tick() -> void:
	clock_seconds += 1
	var hours := int(clock_seconds / 3600) % 24
	var minutes := int(clock_seconds / 60) % 60
	var seconds := clock_seconds % 60
	$Layout/TopBar/Clock.text = "%02d:%02d:%02dZ" % [hours, minutes, seconds]

func _font(size: int, is_bold: bool) -> DynamicFont:
	var result := DynamicFont.new()
	result.font_data = load("res://fonts/DejaVuSans-Bold.ttf" if is_bold else "res://fonts/DejaVuSans.ttf")
	result.size = size
	return result

func _box(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func _style_button(button: Button) -> void:
	button.add_font_override("font", _font(18, true))
	button.add_color_override("font_color", INK)
	button.add_stylebox_override("normal", _box(PANEL_ALT, Color("2b524a"), 8))
	button.add_stylebox_override("hover", _box(Color("173b34"), GREEN, 8))
	button.add_stylebox_override("pressed", _box(Color("204a41"), GREEN, 8))
	button.add_stylebox_override("disabled", _box(Color("081613"), Color("162a26"), 8))
	button.add_color_override("font_color_disabled", Color("435751"))

func _set_margins(control: Control, horizontal: int, vertical: int) -> void:
	control.add_constant_override("separation", 20)
	# Container padding is supplied by each child style; retain a consistent edge gap.
	control.rect_clip_content = false

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.scancode:
		KEY_RIGHT, KEY_N: _next()
		KEY_LEFT, KEY_P: _previous()
		KEY_L: _toggle_language()
		KEY_R: _reset()
