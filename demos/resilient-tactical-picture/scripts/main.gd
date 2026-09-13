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
		"title":"MAX Tablet", "subtitle":"RESILIENT NETWORK ROUTING // EXERCISE ORION",
		"map_title":"NETWORK TOPOLOGY / TACTICAL MAP", "nodes":"NETWORK NODES", "online":"%02d ONLINE",
		"route_status":"ROUTE STATUS", "reset":"RESET", "previous":"‹ PREVIOUS", "next":"NEXT EVENT  ›",
		"simulated":"● EXERCISE • SIMULATED", "node_type":"NODE TYPE", "bearers":"BEARERS", "battery":"BATTERY",
		"updated":"UPDATED", "seconds":"s ago", "command":"COMMAND", "relay":"RELAY", "vehicle":"VEHICLE", "dismounted":"DISMOUNTED",
		"active":"ACTIVE", "offline":"OFFLINE", "constrained":"CONSTRAINED", "select_destination":"SELECT DESTINATION",
		"select_detail":"Source %s selected • tap another node", "no_route":"NO ROUTE AVAILABLE", "hops":"HOPS", "quality":"Q",
		"summary_ready":"NODES 05  •  LINKS 07  •  AUTO ROUTING  •  QUEUE 00",
		"summary_degraded":"LINK DEGRADED  •  AUTO REROUTE ACTIVE  •  QUEUE 03",
		"summary_offline":"RELAY-2 OFFLINE  •  ALTERNATE PATH ACTIVE  •  QUEUE 03",
		"summary_constrained":"PATH CONSTRAINED  •  STORE-FORWARD READY  •  QUEUE 07",
		"summary_restored":"PRIMARY RESTORED  •  ROUTE OPTIMISED  •  QUEUE 00",
		"nodes_discovered":["NETWORK DISCOVERED", "5 fictional nodes discovered • tap source, then destination", "NODE DISCOVERY"],
		"route_computed":["ROUTE COMPUTED", "HQ-7 to TEAM-ALPHA • lowest-cost available path", "ROUTE SELECTION"],
		"link_degraded":["LINK DEGRADED", "Quality loss detected • route recalculated automatically", "AUTOMATIC REROUTE"],
		"relay_offline":["RELAY-2 OFFLINE", "Traffic moved to HF and vehicle relay • service maintained", "NODE LOSS"],
		"route_constrained":["PATH CONSTRAINED", "Direct UHF path selected • reduced route quality", "CONSTRAINED NETWORK"],
		"store_forward":["STORE-FORWARD READY", "Messages queued locally until a stronger path returns", "DISCONNECTED OPERATION"],
		"route_restored":["PRIMARY ROUTE RESTORED", "Best path selected • queued traffic synchronised", "RECOVERY & SYNC"]
	},
	"fr": {
		"title":"MAX Tablet", "subtitle":"ROUTAGE RÉSEAU RÉSILIENT // EXERCICE ORION",
		"map_title":"TOPOLOGIE RÉSEAU / CARTE TACTIQUE", "nodes":"NŒUDS RÉSEAU", "online":"%02d EN LIGNE",
		"route_status":"ÉTAT DE L’ITINÉRAIRE", "reset":"RÉINITIALISER", "previous":"‹ PRÉCÉDENT", "next":"ÉVÉNEMENT SUIVANT  ›",
		"simulated":"● EXERCICE • DONNÉES SIMULÉES", "node_type":"TYPE DE NŒUD", "bearers":"LIAISONS", "battery":"BATTERIE",
		"updated":"ACTUALISÉ", "seconds":"s", "command":"COMMANDEMENT", "relay":"RELAIS", "vehicle":"VÉHICULE", "dismounted":"ÉQUIPE À PIED",
		"active":"ACTIF", "offline":"HORS LIGNE", "constrained":"CONTRAINT", "select_destination":"SÉLECTIONNER LA DESTINATION",
		"select_detail":"Source %s sélectionnée • toucher un autre nœud", "no_route":"AUCUN ITINÉRAIRE", "hops":"SAUTS", "quality":"Q",
		"summary_ready":"NŒUDS 05  •  LIENS 07  •  ROUTAGE AUTO  •  FILE 00",
		"summary_degraded":"LIEN DÉGRADÉ  •  DÉROUTAGE AUTO ACTIF  •  FILE 03",
		"summary_offline":"RELAY-2 HORS LIGNE  •  ITINÉRAIRE BIS ACTIF  •  FILE 03",
		"summary_constrained":"ITINÉRAIRE CONTRAINT  •  STOCKAGE-RELAIS PRÊT  •  FILE 07",
		"summary_restored":"LIAISON RÉTABLIE  •  ITINÉRAIRE OPTIMISÉ  •  FILE 00",
		"nodes_discovered":["RÉSEAU DÉCOUVERT", "5 nœuds fictifs détectés • toucher la source puis la destination", "DÉCOUVERTE DES NŒUDS"],
		"route_computed":["ITINÉRAIRE CALCULÉ", "HQ-7 vers TEAM-ALPHA • meilleur chemin disponible", "SÉLECTION D’ITINÉRAIRE"],
		"link_degraded":["LIEN DÉGRADÉ", "Perte de qualité détectée • itinéraire recalculé automatiquement", "DÉROUTAGE AUTOMATIQUE"],
		"relay_offline":["RELAY-2 HORS LIGNE", "Trafic transféré vers HF et relais véhicule • service maintenu", "PERTE D’UN NŒUD"],
		"route_constrained":["ITINÉRAIRE CONTRAINT", "Liaison UHF directe sélectionnée • qualité réduite", "RÉSEAU CONTRAINT"],
		"store_forward":["STOCKAGE-RELAIS PRÊT", "Messages stockés localement en attente d’un meilleur chemin", "FONCTIONNEMENT DÉCONNECTÉ"],
		"route_restored":["ITINÉRAIRE PRINCIPAL RÉTABLI", "Meilleur chemin sélectionné • file synchronisée", "REPRISE ET SYNCHRONISATION"]
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
	map.connect("node_selected", self, "_on_node_selected")
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
	_refresh_nodes()
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

func _scaled(value: int) -> int:
	return int(round(float(value) * responsive_scale))

func _apply_demo_overrides() -> void:
	var requested_profile := OS.get_environment("TACTICAL_DEMO_PROFILE")
	if requested_profile == "uk" or requested_profile == "fr":
		model.profile = requested_profile
	var requested_beat := OS.get_environment("TACTICAL_DEMO_BEAT")
	if requested_beat.is_valid_integer():
		model.beat = clamp(int(requested_beat), 0, model.BEATS.size() - 1)
		model.selected_id = model.BEATS[model.beat].selected

func _build_fonts() -> void:
	regular = _font(23, false)
	bold = _font(23, true)
	add_font_override("font", regular)

func _apply_layout_style() -> void:
	$Layout/TopBar/Brand/Title.add_color_override("font_color", INK)
	$Layout/TopBar/Brand/Subtitle.add_color_override("font_color", GREEN)
	$Layout/TopBar/BearerSummary.add_color_override("font_color", GREEN)
	$Layout/TopBar/Clock.add_color_override("font_color", INK)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.add_color_override("font_color", INK)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.add_color_override("font_color", CYAN)
	for card in [incident_card, selected_card]:
		card.add_stylebox_override("panel", _box(PANEL_ALT, Color("234b43"), 10))
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.add_color_override("font_color", MUTED)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.add_color_override("font_color", MUTED)
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamCount.add_color_override("font_color", GREEN)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_color_override("font_color", GREEN)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.add_color_override("font_color", MUTED)
	$Layout/BottomBar/ScenarioLabel.add_color_override("font_color", MUTED)
	$Layout/BottomBar/SimulationBadge.add_color_override("font_color", CYAN)
	for button in [language_button, next_button, previous_button, reset_button]:
		_style_button(button)
	next_button.add_stylebox_override("normal", _box(GREEN, GREEN, 8))
	next_button.add_color_override("font_color", BG)

func _refresh() -> void:
	var t: Dictionary = TEXT[_language()]
	var story: Array = t[model.current().key]
	var current_route: Dictionary = model.route()
	$Layout/TopBar/Brand/Title.text = t.title
	$Layout/TopBar/Brand/Subtitle.text = t.subtitle
	language_button.text = "FR · FR" if model.profile == "uk" else "UK · EN"
	$Layout/TopBar/BearerSummary.text = _network_summary()
	$Layout/TopBar/BearerSummary.add_color_override("font_color", AMBER if model.beat >= 2 and model.beat < 6 else GREEN)
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapTitle.text = t.map_title
	$Layout/ContentMargin/Content/MapColumn/MapHeader/MapMode.text = _route_summary(current_route)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentLabel.text = t.route_status
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.text = t.select_destination if model.awaiting_destination else story[0]
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentState.add_color_override("font_color", RED if model.beat == 3 else AMBER if model.beat >= 2 and model.beat < 6 else INK)
	$Layout/ContentMargin/Content/SidePanel/IncidentCard/IncidentDetail.text = t.select_detail % model.node(model.route_source).call if model.awaiting_destination else story[1]
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamTitle.text = t.nodes
	$Layout/ContentMargin/Content/SidePanel/TeamHeader/TeamCount.text = t.online % _online_count()
	$Layout/BottomBar/ScenarioLabel.text = "%02d / %02d  •  %s" % [model.beat + 1, model.BEATS.size(), story[2]]
	$Layout/BottomBar/SimulationBadge.text = t.simulated
	reset_button.text = t.reset
	previous_button.text = t.previous
	next_button.text = t.next
	previous_button.disabled = model.beat == 0
	next_button.disabled = model.beat == model.BEATS.size() - 1
	_refresh_nodes()
	_refresh_selected()
	map.configure(model.all_nodes(), model.all_links(), current_route, model.selected_id, model.route_source, model.route_destination, model.profile)

func _refresh_nodes() -> void:
	if not is_instance_valid(team_list) or model == null:
		return
	var t: Dictionary = TEXT[_language()]
	for child in team_list.get_children():
		child.queue_free()
	for item in model.all_nodes():
		var button := Button.new()
		button.rect_min_size = Vector2(0, _scaled(70))
		button.align = Button.ALIGN_LEFT
		button.text = "  ●  %s     %s     %d%%" % [item.call, t[item.status], item.battery]
		button.add_font_override("font", _font(_scaled(18), true))
		var color: Color = RED if item.status == "offline" else AMBER if item.status == "constrained" else GREEN
		button.add_color_override("font_color", color if item.id == model.selected_id else INK)
		button.add_stylebox_override("normal", _box(PANEL_ALT if item.id == model.selected_id else PANEL, color if item.id == model.selected_id else Color("1d3934"), 7))
		button.connect("pressed", self, "_on_node_selected", [item.id])
		team_list.add_child(button)

func _refresh_selected() -> void:
	var t: Dictionary = TEXT[_language()]
	var item: Dictionary = model.node_state(model.selected_id)
	var color: Color = RED if item.status == "offline" else AMBER if item.status == "constrained" else GREEN
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedName.text = item.call
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.text = "%s  •  %s" % [t[item.role_key], t[item.status]]
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedRole.add_color_override("font_color", color)
	$Layout/ContentMargin/Content/SidePanel/SelectedCard/SelectedMetrics.text = "%s   %s\n%s     %s\n%s    %d%%\n%s    %d %s" % [t.node_type, t[item.role_key], t.bearers, PoolStringArray(item.bearers).join(" + "), t.battery, item.battery, t.updated, item.age_seconds, t.seconds]

func _network_summary() -> String:
	var t: Dictionary = TEXT[_language()]
	if model.beat == 2: return t.summary_degraded
	if model.beat == 3: return t.summary_offline
	if model.beat >= 4 and model.beat <= 5: return t.summary_constrained
	if model.beat == 6: return t.summary_restored
	return t.summary_ready

func _route_summary(current_route: Dictionary) -> String:
	var t: Dictionary = TEXT[_language()]
	if not current_route.available:
		return t.no_route
	var source_call: String = model.node(current_route.path[0]).call
	var destination_call: String = model.node(current_route.path[current_route.path.size() - 1]).call
	return "%s → %s  •  %d %s  •  %d ms  •  %s %d%%" % [source_call, destination_call, current_route.path.size() - 1, t.hops, current_route.latency, t.quality, current_route.quality]

func _online_count() -> int:
	var count := 0
	for item in model.all_nodes():
		if item.status != "offline":
			count += 1
	return count

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

func _on_node_selected(node_id: String) -> void:
	model.select_route_node(node_id)
	_refresh()

func _tick() -> void:
	clock_seconds += 1
	$Layout/TopBar/Clock.text = "%02d:%02d:%02dZ" % [int(clock_seconds / 3600) % 24, int(clock_seconds / 60) % 60, clock_seconds % 60]

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

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.scancode:
		KEY_RIGHT, KEY_N: _next()
		KEY_LEFT, KEY_P: _previous()
		KEY_L: _toggle_language()
		KEY_R: _reset()
