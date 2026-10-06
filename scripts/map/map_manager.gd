@tool
extends Node

# Project T - Dünya Haritası ve Seyahat Yöneticisi (MapManager)
# Autoload Singleton: MapManager
#
# Koordinat Sistemi:
# Gerçek Dünya Boyutu: 1920 x 1280 piksel (120 x 80 karo)
# Mini Harita / UI Boyutu: 384 x 256 piksel (Ölçek: 0.20 / 1 piksel harita = 5 piksel dünya)
#
# Özellikler:
# 1. Keşfedilen bölgeler & POI (Önemli Yerler)
# 2. Hücresel Sis Sistemi (Fog of War): 24 x 16 hücreli grid (her hücre 80x80 piksel dünya alanı)
# 3. Oyuncu özel işaretleri (Custom Map Markers)
# 4. Hızlı seyahat (Fast Travel) & Zaman ilerleme hesaplaması

signal map_updated
signal fast_traveled(destination_id: String, hours_passed: float)
signal marker_added(marker_id: String, world_pos: Vector2)
signal marker_removed(marker_id: String)

const WORLD_WIDTH: float = 1920.0
const WORLD_HEIGHT: float = 1280.0
const MAP_UI_WIDTH: float = 384.0
const MAP_UI_HEIGHT: float = 256.0
const WORLD_TO_MAP_SCALE: float = 0.20 # 384 / 1920

# Sis Sistemi Izgarası (Fog of War Grid): 24 sütun x 16 satır
const FOG_COLS: int = 24
const FOG_ROWS: int = 16
const FOG_CELL_SIZE: float = 80.0 # 1920 / 24 = 80 piksel

# Açılmış sis hücreleri (Örn: "x_y" -> true)
var revealed_fog_cells: Dictionary = {}

# Keşfedilmiş Önemli Noktalar (Points of Interest / Fast Travel Points)
# poi_id -> { "name": String, "world_pos": Vector2, "discovered": bool, "can_fast_travel": bool, "icon": String }
var pois: Dictionary = {
	"village_square": {
		"name": "Kızıl Köy Meydanı",
		"world_pos": Vector2(480, 320),
		"discovered": true,
		"can_fast_travel": true,
		"icon": "village",
		"region": "Kızıl Vadi"
	},
	"red_inn": {
		"name": "Kızıl Han",
		"world_pos": Vector2(380, 265),
		"discovered": true,
		"can_fast_travel": true,
		"icon": "inn",
		"region": "Kızıl Vadi"
	},
	"watchtower": {
		"name": "Eski Gözetleme Kulesi",
		"world_pos": Vector2(1460, 260),
		"discovered": false,
		"can_fast_travel": true,
		"icon": "tower",
		"region": "Kuzey Kayalıkları"
	},
	"cave_entrance": {
		"name": "Yankılı Mağara Girişi",
		"world_pos": Vector2(1650, 180),
		"discovered": false,
		"can_fast_travel": false,
		"icon": "cave",
		"region": "Kuzey Kayalıkları"
	},
	"glade": {
		"name": "Gizli Orman Açıklığı",
		"world_pos": Vector2(250, 310),
		"discovered": false,
		"can_fast_travel": false,
		"icon": "tree",
		"region": "Batı Ormanı"
	},
	"lake_shore": {
		"name": "Sazlık Gölet & Tarla",
		"world_pos": Vector2(680, 420),
		"discovered": false,
		"can_fast_travel": false,
		"icon": "lake",
		"region": "Kızıl Vadi"
	},
	"bandit_camp": {
		"name": "Haydut Sığınağı",
		"world_pos": Vector2(1650, 420),
		"discovered": false,
		"can_fast_travel": false,
		"icon": "skull",
		"region": "Doğu Çoraklığı"
	},
	"hunter_cabin": {
		"name": "Dağ Avcı Kulübesi",
		"world_pos": Vector2(2320, 750),
		"discovered": false,
		"can_fast_travel": true,
		"icon": "inn",
		"region": "Dağ Eteği Vadisi"
	},
	"mountain_canyon_peak": {
		"name": "Sarp Kanyon Zirvesi",
		"world_pos": Vector2(3100, 520),
		"discovered": false,
		"can_fast_travel": false,
		"icon": "tower",
		"region": "Dağ Eteği Vadisi"
	}
}

# Oyuncunun Koyduğu Harita İşaretleri
# Array of Dictionary: { "id": String, "world_pos": Vector2, "label": String, "color": Color }
var custom_markers: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("map_manager")
	# Başlangıçta köy çevresindeki sisleri otomatik aç
	reveal_fog_around_world_pos(Vector2(480, 320), 180.0)
	_connect_discovery_manager()

func _connect_discovery_manager() -> void:
	if not is_inside_tree():
		return
	var dm = get_node_or_null("/root/DiscoveryManager")
	if dm:
		if not dm.location_discovered.is_connected(_on_location_discovered):
			dm.location_discovered.connect(_on_location_discovered)

func _on_location_discovered(loc_id: String, _title: String) -> void:
	# Discovery trigger ID eşleşmesi
	match loc_id:
		"glade":
			discover_poi("glade")
		"tower":
			discover_poi("watchtower")
		"cave":
			discover_poi("cave_entrance")

# 1. KOORDİNAT DÖNÜŞÜMLERİ
func world_to_map_coords(world_pos: Vector2) -> Vector2:
	return world_pos * WORLD_TO_MAP_SCALE

func map_to_world_coords(map_pos: Vector2) -> Vector2:
	return map_pos / WORLD_TO_MAP_SCALE

# 2. SIS SİSTEMİ (Fog of War)
func get_fog_cell_coord(world_pos: Vector2) -> Vector2i:
	var cx = clampi(int(world_pos.x / FOG_CELL_SIZE), 0, FOG_COLS - 1)
	var cy = clampi(int(world_pos.y / FOG_CELL_SIZE), 0, FOG_ROWS - 1)
	return Vector2i(cx, cy)

func is_fog_revealed(cell: Vector2i) -> bool:
	return revealed_fog_cells.has("%d_%d" % [cell.x, cell.y])

func reveal_fog_cell(cell: Vector2i) -> void:
	var key = "%d_%d" % [cell.x, cell.y]
	if not revealed_fog_cells.has(key):
		revealed_fog_cells[key] = true
		map_updated.emit()

func reveal_fog_around_world_pos(world_pos: Vector2, radius: float = 140.0) -> void:
	var min_c = get_fog_cell_coord(world_pos - Vector2(radius, radius))
	var max_c = get_fog_cell_coord(world_pos + Vector2(radius, radius))
	var changed = false

	for x in range(min_c.x, max_c.x + 1):
		for y in range(min_c.y, max_c.y + 1):
			var cell_world_center = Vector2((x + 0.5) * FOG_CELL_SIZE, (y + 0.5) * FOG_CELL_SIZE)
			if cell_world_center.distance_to(world_pos) <= radius + (FOG_CELL_SIZE * 0.5):
				var key = "%d_%d" % [x, y]
				if not revealed_fog_cells.has(key):
					revealed_fog_cells[key] = true
					changed = true

	if changed:
		map_updated.emit()

# 3. ÖNEMLİ YERLER (POIs) & KEŞİF
func discover_poi(poi_id: String) -> bool:
	if pois.has(poi_id):
		if not pois[poi_id]["discovered"]:
			pois[poi_id]["discovered"] = true
			# POI etrafındaki sisi de aç
			reveal_fog_around_world_pos(pois[poi_id]["world_pos"], 160.0)
			map_updated.emit()
			return true
	return false

func is_poi_discovered(poi_id: String) -> bool:
	if pois.has(poi_id):
		return pois[poi_id].get("discovered", false)
	return false

# 4. ÖZEL İŞARETÇİLER (Custom Markers)
func add_marker(world_pos: Vector2, label: String = "İşaret", color: Color = Color("eab308")) -> String:
	var m_id = "marker_%d" % [Time.get_ticks_msec()]
	var entry: Dictionary = {
		"id": m_id,
		"world_pos": world_pos,
		"label": label,
		"color": color
	}
	custom_markers.append(entry)
	marker_added.emit(m_id, world_pos)
	map_updated.emit()
	return m_id

func remove_marker(marker_id: String) -> bool:
	for i in range(custom_markers.size()):
		if custom_markers[i]["id"] == marker_id:
			custom_markers.remove_at(i)
			marker_removed.emit(marker_id)
			map_updated.emit()
			return true
	return false

func remove_marker_near(world_pos: Vector2, tolerance: float = 30.0) -> bool:
	for i in range(custom_markers.size() - 1, -1, -1):
		if custom_markers[i]["world_pos"].distance_to(world_pos) <= tolerance:
			var m_id = custom_markers[i]["id"]
			custom_markers.remove_at(i)
			marker_removed.emit(m_id)
			map_updated.emit()
			return true
	return false

# 5. SINIRLI HIZLI SEYAHAT (Fast Travel)
# Mesafe formülü: 1000 piksel = 1 oyun saati yolculuk (minimum 0.5 saat)
func can_fast_travel_to(poi_id: String) -> bool:
	if not pois.has(poi_id):
		return false
	var poi = pois[poi_id]
	return poi.get("discovered", false) and poi.get("can_fast_travel", false)

func calculate_travel_hours(from_pos: Vector2, to_pos: Vector2) -> float:
	var dist = from_pos.distance_to(to_pos)
	# 1000 piksel ~ 1.0 saat
	var hours = maxf(0.5, dist / 800.0)
	return snappedf(hours, 0.1)

func fast_travel(poi_id: String, player: CharacterBody2D) -> bool:
	if not can_fast_travel_to(poi_id) or player == null:
		return false

	var dest_pos: Vector2 = pois[poi_id]["world_pos"]
	var hours = calculate_travel_hours(player.global_position, dest_pos)

	# Oyuncuyu taşı
	player.global_position = dest_pos
	player.velocity = Vector2.ZERO

	# Dünya saatini ilerlet
	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	if tm and tm.has_method("advance_time"):
		tm.advance_time(hours)

	# Hedef çevresindeki sisi aç
	reveal_fog_around_world_pos(dest_pos, 160.0)

	fast_traveled.emit(poi_id, hours)
	map_updated.emit()
	return true

# 6. KAYIT & YÜKLEME
func get_save_data() -> Dictionary:
	var discovered_dict: Dictionary = {}
	for p_id in pois:
		discovered_dict[p_id] = pois[p_id]["discovered"]

	var serialized_markers: Array = []
	for m in custom_markers:
		serialized_markers.append({
			"id": m.get("id", ""),
			"world_pos": [m.get("world_pos", Vector2.ZERO).x, m.get("world_pos", Vector2.ZERO).y],
			"label": m.get("label", ""),
			"color": m.get("color", Color.WHITE).to_html()
		})

	return {
		"revealed_fog": revealed_fog_cells.duplicate(true),
		"discovered_pois": discovered_dict,
		"markers": serialized_markers
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("revealed_fog") and data["revealed_fog"] is Dictionary:
		revealed_fog_cells = data["revealed_fog"].duplicate(true)
	if data.has("discovered_pois") and data["discovered_pois"] is Dictionary:
		for p_id in data["discovered_pois"]:
			if pois.has(p_id):
				pois[p_id]["discovered"] = data["discovered_pois"][p_id]
	if data.has("markers") and data["markers"] is Array:
		custom_markers.clear()
		for item in data["markers"]:
			if item is Dictionary:
				var m_obj: Dictionary = {
					"id": item.get("id", ""),
					"label": item.get("label", "")
				}
				var wp = item.get("world_pos")
				if wp is Array and wp.size() >= 2:
					m_obj["world_pos"] = Vector2(wp[0], wp[1])
				elif wp is Dictionary:
					m_obj["world_pos"] = Vector2(wp.get("x", 0.0), wp.get("y", 0.0))
				else:
					m_obj["world_pos"] = Vector2.ZERO
				
				var c_val = item.get("color")
				if c_val is String:
					m_obj["color"] = Color.from_string(c_val, Color.WHITE)
				elif c_val is Color:
					m_obj["color"] = c_val
				else:
					m_obj["color"] = Color.WHITE
				custom_markers.append(m_obj)
	map_updated.emit()
