extends Reference
class_name TacticalScenarioModel

const NODES := [
	{"id":"hq_7", "call":"HQ-7", "role_key":"command", "battery":100, "pos":Vector2(0.14, 0.70), "bearers":["SAT", "HF", "IP"]},
	{"id":"relay_2", "call":"RELAY-2", "role_key":"relay", "battery":84, "pos":Vector2(0.35, 0.46), "bearers":["MESH", "LOS"]},
	{"id":"vehicle_4", "call":"VEHICLE-4", "role_key":"vehicle", "battery":93, "pos":Vector2(0.52, 0.69), "bearers":["HF", "MESH", "UHF"]},
	{"id":"relay_5", "call":"RELAY-5", "role_key":"relay", "battery":78, "pos":Vector2(0.66, 0.32), "bearers":["MESH", "LOS"]},
	{"id":"team_alpha", "call":"TEAM-ALPHA", "role_key":"dismounted", "battery":89, "pos":Vector2(0.84, 0.60), "bearers":["UHF", "MESH"]}
]

const LINKS := [
	{"id":"hq_r2", "from":"hq_7", "to":"relay_2", "bearer":"SAT/IP", "cost":10, "latency":42, "quality":88},
	{"id":"r2_r5", "from":"relay_2", "to":"relay_5", "bearer":"LOS", "cost":10, "latency":18, "quality":91},
	{"id":"r5_team", "from":"relay_5", "to":"team_alpha", "bearer":"MESH", "cost":10, "latency":24, "quality":86},
	{"id":"r2_vehicle", "from":"relay_2", "to":"vehicle_4", "bearer":"MESH", "cost":12, "latency":27, "quality":82},
	{"id":"vehicle_r5", "from":"vehicle_4", "to":"relay_5", "bearer":"MESH", "cost":12, "latency":31, "quality":79},
	{"id":"hq_vehicle", "from":"hq_7", "to":"vehicle_4", "bearer":"HF", "cost":28, "latency":94, "quality":61},
	{"id":"vehicle_team", "from":"vehicle_4", "to":"team_alpha", "bearer":"UHF", "cost":35, "latency":71, "quality":55}
]

const BEATS := [
	{"key":"nodes_discovered", "selected":"hq_7"},
	{"key":"route_computed", "selected":"relay_2"},
	{"key":"link_degraded", "selected":"relay_5"},
	{"key":"relay_offline", "selected":"relay_2"},
	{"key":"route_constrained", "selected":"vehicle_4"},
	{"key":"store_forward", "selected":"team_alpha"},
	{"key":"route_restored", "selected":"relay_5"}
]

var beat := 0
var selected_id := "hq_7"
var route_source := "hq_7"
var route_destination := "team_alpha"
var awaiting_destination := false
var profile := "uk"

func reset() -> void:
	beat = 0
	selected_id = BEATS[0].selected
	route_source = "hq_7"
	route_destination = "team_alpha"
	awaiting_destination = false

func next() -> void:
	beat = min(beat + 1, BEATS.size() - 1)
	selected_id = BEATS[beat].selected

func previous() -> void:
	beat = max(beat - 1, 0)
	selected_id = BEATS[beat].selected

func current() -> Dictionary:
	return BEATS[beat]

func node(node_id: String) -> Dictionary:
	for item in NODES:
		if item.id == node_id:
			return item
	return NODES[0]

func node_state(node_id: String) -> Dictionary:
	var item := node(node_id).duplicate(true)
	item.status = "active"
	item.age_seconds = 1
	if node_id == "relay_2" and beat >= 3 and beat <= 5:
		item.status = "offline"
		item.age_seconds = 37
	elif node_id == "vehicle_4" and beat >= 4 and beat <= 5:
		item.status = "constrained"
		item.age_seconds = 8
	return item

func all_nodes() -> Array:
	var result := []
	for item in NODES:
		result.append(node_state(item.id))
	return result

func all_links() -> Array:
	var result := []
	for item in LINKS:
		result.append(link_state(item))
	return result

func link_state(link: Dictionary) -> Dictionary:
	var item := link.duplicate(true)
	item.status = "active"
	if beat >= 3 and beat <= 5 and (item.from == "relay_2" or item.to == "relay_2"):
		item.status = "offline"
	elif item.id == "r2_r5" and beat >= 2 and beat <= 5:
		item.status = "degraded"
	elif item.id == "vehicle_r5" and beat >= 4 and beat <= 5:
		item.status = "degraded"
	return item

func route() -> Dictionary:
	if route_source == "" or route_destination == "" or route_source == route_destination:
		return {"available":false, "path":[], "link_ids":[], "cost":0, "latency":0, "quality":0}
	var distance := {}
	var previous_node := {}
	var previous_link := {}
	var unvisited := []
	for item in NODES:
		distance[item.id] = 1000000
		unvisited.append(item.id)
	distance[route_source] = 0
	while unvisited.size() > 0:
		var current_id := ""
		var current_distance := 1000001
		for candidate in unvisited:
			if int(distance[candidate]) < current_distance:
				current_id = candidate
				current_distance = int(distance[candidate])
		if current_id == "" or current_distance >= 1000000:
			break
		unvisited.erase(current_id)
		if current_id == route_destination:
			break
		for link in all_links():
			if link.status == "offline":
				continue
			var neighbour := ""
			if link.from == current_id:
				neighbour = link.to
			elif link.to == current_id:
				neighbour = link.from
			if neighbour == "" or not unvisited.has(neighbour):
				continue
			var weight: int = int(link.cost) + (30 if link.status == "degraded" else 0)
			var alternative: int = current_distance + weight
			if alternative < int(distance[neighbour]):
				distance[neighbour] = alternative
				previous_node[neighbour] = current_id
				previous_link[neighbour] = link.id
	if not previous_node.has(route_destination):
		return {"available":false, "path":[], "link_ids":[], "cost":0, "latency":0, "quality":0}
	var path := [route_destination]
	var link_ids := []
	var cursor: String = route_destination
	while cursor != route_source:
		link_ids.push_front(previous_link[cursor])
		cursor = previous_node[cursor]
		path.push_front(cursor)
	var latency := 0
	var quality := 100
	for link in all_links():
		if link_ids.has(link.id):
			latency += int(link.latency) + (35 if link.status == "degraded" else 0)
			quality = min(quality, int(link.quality) - (25 if link.status == "degraded" else 0))
	return {"available":true, "path":path, "link_ids":link_ids, "cost":int(distance[route_destination]), "latency":latency, "quality":quality}

func select_route_node(node_id: String) -> void:
	selected_id = node_id
	if not awaiting_destination:
		route_source = node_id
		route_destination = ""
		awaiting_destination = true
	elif node_id != route_source:
		route_destination = node_id
		awaiting_destination = false
