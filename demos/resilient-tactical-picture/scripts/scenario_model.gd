extends Reference
class_name TacticalScenarioModel

const PEOPLE := [
	{"id":"raven_1", "call":"RAVEN 1", "role_key":"team_lead", "battery":94, "pos":Vector2(0.25, 0.71)},
	{"id":"raven_2", "call":"RAVEN 2", "role_key":"medic", "battery":91, "pos":Vector2(0.40, 0.59)},
	{"id":"raven_3", "call":"RAVEN 3", "role_key":"comms", "battery":88, "pos":Vector2(0.52, 0.66)},
	{"id":"raven_4", "call":"RAVEN 4", "role_key":"specialist", "battery":86, "pos":Vector2(0.62, 0.43)},
	{"id":"raven_5", "call":"RAVEN 5", "role_key":"support", "battery":96, "pos":Vector2(0.76, 0.73)}
]

const BEATS := [
	{"key":"deployment", "primary":"online", "selected":"raven_2"},
	{"key":"mesh_ready", "primary":"online", "selected":"raven_3"},
	{"key":"link_degraded", "primary":"degraded", "selected":"raven_3"},
	{"key":"indoor_tracking", "primary":"degraded", "selected":"raven_4"},
	{"key":"casualty_alert", "primary":"degraded", "selected":"raven_4"},
	{"key":"extraction", "primary":"degraded", "selected":"raven_4"},
	{"key":"sync_restored", "primary":"online", "selected":"raven_4"}
]

var beat := 0
var selected_id := "raven_2"
var profile := "uk"

func reset() -> void:
	beat = 0
	selected_id = BEATS[0].selected

func next() -> void:
	beat = min(beat + 1, BEATS.size() - 1)
	selected_id = BEATS[beat].selected

func previous() -> void:
	beat = max(beat - 1, 0)
	selected_id = BEATS[beat].selected

func current() -> Dictionary:
	return BEATS[beat]

func person(person_id: String) -> Dictionary:
	for item in PEOPLE:
		if item.id == person_id:
			return item
	return PEOPLE[0]

func person_state(person_id: String) -> Dictionary:
	var p := person(person_id).duplicate()
	p.status = "active"
	p.bearer = "UWB + GNSS"
	p.confidence = 1.2
	p.age_seconds = 1
	p.source = "FUSED"
	if beat >= 2:
		p.pos += Vector2(0.012 * beat, -0.008 * beat)
	if person_id == "raven_4" and beat >= 3:
		p.bearer = "UWB MESH"
		p.confidence = 6.8 if beat == 3 else 3.4
		p.age_seconds = 7 if beat == 3 else 3
		p.source = "ESTIMATED"
	if person_id == "raven_4" and beat >= 4:
		p.status = "man_down" if beat == 4 else "evacuation"
	if beat == 6:
		p.bearer = "UWB + GNSS"
		p.confidence = 1.6
		p.age_seconds = 1
		p.source = "FUSED"
	return p

func all_people() -> Array:
	var result := []
	for p in PEOPLE:
		result.append(person_state(p.id))
	return result
