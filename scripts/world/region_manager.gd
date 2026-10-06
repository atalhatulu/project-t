@tool
extends Node

# Project T - Bölgesel Yükleme ve Akış Yöneticisi (RegionManager)
# Autoload Singleton: RegionManager
#
# Mimari: World -> Region -> Location
# Hedef:
# 1. Oyuncunun konumuna göre yakın bölgeleri yükleme, uzak bölgeleri boşaltma
# 2. Bölge boşaltılırken dinamik dünya değişikliklerini (sandıklar, kırılan nesneler, toplanan bitkiler) önbelleğe alma
# 3. Yüklü olmayan bölgelerdeki NPC'ler için hafifletilmiş (lightweight) zaman simülasyonu
# 4. Kamera ve hareket sürekliliğini bozmadan kesintisiz bölge akışı
# 5. SaveManager entegrasyonu ile tüm bölgelerin durumunu tutarlı saklama

signal region_loaded(region_id: String)
signal region_unloaded(region_id: String)
signal active_region_changed(old_region_id: String, new_region_id: String)

# Kayıtlı Bölge Tanımları
# region_id -> Dictionary { name, scene_path, bounds: Rect2, center: Vector2 }
var registered_regions: Dictionary = {
	"region_01_greenwood": {
		"name": "Kızıl Vadi ve Orman",
		"scene_path": "res://scenes/world/region.tscn",
		"bounds": Rect2(0, 0, 1920, 1280),
		"center": Vector2(960, 640)
	},
	"region_02_mountain_valley": {
		"name": "Dağ Eteği Vadisi",
		"scene_path": "res://scenes/world/region_mountain_valley.tscn",
		"bounds": Rect2(1920, 0, 1920, 1280),
		"center": Vector2(2880, 640)
	}
}

# Şu an bellekte / sahne ağacında yüklü olan bölgeler: region_id -> Region (Node2D)
var loaded_regions: Dictionary = {}

# Şu an oyuncunun içinde bulunduğu aktif bölge kimliği
var active_region_id: String = "region_01_greenwood"

# Yüklü olmayan / boşaltılmış bölgelerdeki kalıcı nesne değişiklikleri önbelleği
# region_id -> { interactable_id -> state_dict }
var unloaded_interactables_cache: Dictionary = {}

# Yüklü olmayan NPC'lerin simülasyon verileri
# npc_id -> { "region_id": String, "position": Vector2, "state": int, "hunger": float, "energy": float, "social": float }
var unloaded_npcs_cache: Dictionary = {}

# Yükleme ve boşaltma mesafe eşikleri (Piksel cinsinden)
# Eğer oyuncu bölgenin sınırından bu mesafe kadar uzaktaysa boşaltılabilir
@export var unload_distance_threshold: float = 1400.0
@export var load_distance_threshold: float = 1100.0

var _streaming_update_timer: float = 0.0
const STREAMING_INTERVAL: float = 1.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Zaman değişiminde uzaktaki NPC'lerin simülasyonu
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		if not tm.hour_changed.is_connected(_on_time_hour_changed):
			tm.hour_changed.connect(_on_time_hour_changed)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_streaming_update_timer += delta
	if _streaming_update_timer >= STREAMING_INTERVAL:
		_streaming_update_timer = 0.0
		update_regional_streaming()

# 1. AKIŞ VE YÜKLEME KONTROLÜ (Streaming Update)
func update_regional_streaming() -> void:
	var player = _get_player()
	if not player:
		return
	
	var player_pos: Vector2 = player.global_position
	var new_active_id = get_region_id_at_position(player_pos)
	
	if new_active_id != "" and new_active_id != active_region_id:
		var old_id = active_region_id
		active_region_id = new_active_id
		active_region_changed.emit(old_id, new_active_id)
		
		# Harita sistemini de bilgilendir
		var mm = get_node_or_null("/root/MapManager")
		if mm and mm.has_method("reveal_fog_around_world_pos"):
			mm.reveal_fog_around_world_pos(player_pos, 160.0)

	# Mesafeye göre yükleme / boşaltma kararları
	for r_id in registered_regions:
		var reg_info = registered_regions[r_id]
		var dist = _distance_to_rect(player_pos, reg_info["bounds"])
		
		var is_loaded = loaded_regions.has(r_id)
		if not is_loaded:
			# Oyuncuya yakın mı? (Aktif bölge veya eşik içinde mi?)
			if r_id == active_region_id or dist <= load_distance_threshold:
				load_region(r_id)
		else:
			# Oyuncudan çok uzak mı ve aktif bölge değil mi?
			if r_id != active_region_id and dist > unload_distance_threshold:
				unload_region(r_id)

func _distance_to_rect(pos: Vector2, rect: Rect2) -> float:
	var dx = max(0.0, max(rect.position.x - pos.x, pos.x - rect.end.x))
	var dy = max(0.0, max(rect.position.y - pos.y, pos.y - rect.end.y))
	return sqrt(dx * dx + dy * dy)

func get_region_id_at_position(pos: Vector2) -> String:
	for r_id in registered_regions:
		var bounds: Rect2 = registered_regions[r_id]["bounds"]
		if bounds.has_point(pos):
			return r_id
	return active_region_id

# 2. BÖLGE YÜKLEME (Load Region)
func load_region(r_id: String) -> Node2D:
	if loaded_regions.has(r_id):
		return loaded_regions[r_id]
	
	if not registered_regions.has(r_id):
		push_warning("Bilinmeyen bölge yüklenmeye çalışıldı: " + r_id)
		return null
	
	var reg_info = registered_regions[r_id]
	var scene_path: String = reg_info["scene_path"]
	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		push_error("Bölge sahnesi bulunamadı: " + scene_path)
		return null
	
	var region_instance = packed_scene.instantiate() as Node2D
	region_instance.name = "Region_" + r_id
	
	# Bölgenin dünya konumunu ayarla
	region_instance.position = reg_info["bounds"].position
	
	# Sahne ağacına ekle (World düğümü altına veya mevcut aktif kök altına)
	var world_node = _get_world_node()
	if world_node:
		world_node.add_child(region_instance)
	else:
		if get_tree() and get_tree().current_scene:
			get_tree().current_scene.add_child(region_instance)
	
	loaded_regions[r_id] = region_instance
	
	# Önbellekteki değişiklikleri bu bölgenin nesnelerine uygula
	_apply_cached_changes_to_region(r_id, region_instance)
	
	# Önbellekteki simüle edilmiş NPC'leri geri konumlandır
	_restore_cached_npcs_in_region(r_id, region_instance)
	
	region_loaded.emit(r_id)
	return region_instance

func resync_world_state() -> void:
	# Açık dünyaya dönüldüğünde mevcut sahnede var olan Region'ları yeniden tespit et
	var world_node = _get_world_node()
	if not world_node:
		# İç mekândayız veya açık dünya henüz yüklü değil
		loaded_regions.clear()
		return

	# Sahne ağacında var olan hazır bölgeleri loaded_regions'a geri bağla
	if is_inside_tree():
		for r in get_tree().get_nodes_in_group("region"):
			if r is Region:
				loaded_regions[r.region_id] = r
				# Önbellekteki değişiklikleri bu bölgeye uygula
				_apply_cached_changes_to_region(r.region_id, r)
				_restore_cached_npcs_in_region(r.region_id, r)

	# Oyuncunun konumuna göre aktif bölgeyi ve akışı güncelle
	update_regional_streaming()

# 3. BÖLGE BOŞALTMA (Unload Region)
func unload_region(r_id: String) -> void:
	if not loaded_regions.has(r_id):
		return
	
	var region_node = loaded_regions[r_id]
	
	# Bölgedeki nesnelerin durumunu önbelleğe al
	_cache_changes_from_region(r_id, region_node)
	
	# Bölgedeki NPC'leri önbelleğe kaydet
	_cache_npcs_from_region(r_id, region_node)
	
	loaded_regions.erase(r_id)
	
	if is_instance_valid(region_node):
		region_node.queue_free()
	
	region_unloaded.emit(r_id)

# 4. NESNE VE NPC ÖNBELLEKLEME / GERİ YÜKLEME
func _cache_changes_from_region(r_id: String, region_node: Node) -> void:
	if not unloaded_interactables_cache.has(r_id):
		unloaded_interactables_cache[r_id] = {}
	
	var interactables = region_node.find_children("", "BaseInteractable", true, false)
	for item in interactables:
		if item.has_method("get_save_data") and item.interactable_id != "":
			unloaded_interactables_cache[r_id][item.interactable_id] = item.get_save_data()

func _apply_cached_changes_to_region(r_id: String, region_node: Node) -> void:
	if not unloaded_interactables_cache.has(r_id):
		return
	
	var r_cache: Dictionary = unloaded_interactables_cache[r_id]
	var interactables = region_node.find_children("", "BaseInteractable", true, false)
	for item in interactables:
		if item.interactable_id != "" and r_cache.has(item.interactable_id):
			if item.has_method("load_save_data"):
				item.load_save_data(r_cache[item.interactable_id])

func _cache_npcs_from_region(r_id: String, region_node: Node) -> void:
	var npcs = region_node.find_children("", "BaseNPC", true, false)
	for npc in npcs:
		var entry: Dictionary = {
			"region_id": r_id,
			"position": npc.global_position,
			"state": npc.current_state
		}
		if npc.needs:
			entry["hunger"] = npc.needs.hunger
			entry["energy"] = npc.needs.energy
			entry["social"] = npc.needs.social
		if npc.memory:
			entry["talk_count"] = npc.memory.talk_count_with_player
			entry["known_info"] = npc.memory.known_information.duplicate(true)
		unloaded_npcs_cache[npc.npc_id] = entry

func _restore_cached_npcs_in_region(_r_id: String, region_node: Node) -> void:
	var npcs = region_node.find_children("", "BaseNPC", true, false)
	for npc in npcs:
		if unloaded_npcs_cache.has(npc.npc_id):
			var data = unloaded_npcs_cache[npc.npc_id]
			npc.global_position = data.get("position", npc.global_position)
			npc.current_state = data.get("state", npc.current_state)
			if npc.needs:
				npc.needs.hunger = data.get("hunger", npc.needs.hunger)
				npc.needs.energy = data.get("energy", npc.needs.energy)
				npc.needs.social = data.get("social", npc.needs.social)
			if npc.memory:
				npc.memory.talk_count_with_player = data.get("talk_count", 0)
				if data.has("known_info") and data["known_info"] is Dictionary:
					npc.memory.known_information = data["known_info"].duplicate(true)
			unloaded_npcs_cache.erase(npc.npc_id)

# 5. UZAKTAKİ NPC SİMÜLASYONU (Lightweight NPC Simulation Tick)
func _on_time_hour_changed(current_hour: int) -> void:
	# Yüklü olmayan tüm NPC'lerin durumlarını basit kurallarla güncelle
	for npc_id in unloaded_npcs_cache:
		var npc_data: Dictionary = unloaded_npcs_cache[npc_id]
		# Açlık ve enerji simülasyonu
		var cur_hunger: float = npc_data.get("hunger", 20.0)
		var cur_energy: float = npc_data.get("energy", 80.0)
		
		# Saat 22 ile 06 arası uyku saatleri
		if current_hour >= 22 or current_hour < 6:
			cur_energy = min(100.0, cur_energy + 15.0)
			cur_hunger = min(100.0, cur_hunger + 2.0)
			npc_data["state"] = 4 # SLEEP
		else:
			cur_energy = max(0.0, cur_energy - 3.5)
			cur_hunger = min(100.0, cur_hunger + 5.0)
			npc_data["state"] = 2 # WORK / IDLE
		
		npc_data["hunger"] = cur_hunger
		npc_data["energy"] = cur_energy

# 6. YARDIMCI VE ERİŞİM METOTLARI
func _get_player() -> Node2D:
	if not is_inside_tree():
		return null
	var p = get_tree().get_first_node_in_group("player")
	return p as Node2D

func _get_world_node() -> Node:
	if not is_inside_tree():
		return null
	var w = get_tree().get_first_node_in_group("world")
	if w:
		return w
	if get_tree().current_scene and get_tree().current_scene is World:
		return get_tree().current_scene
	return null

# 7. SAVE / LOAD ENTEGRASYONU
func get_save_data() -> Dictionary:
	# Şu an yüklü olan bölgelerdeki nesneleri de önbelleğe alıp birleştir
	for r_id in loaded_regions:
		var r_node = loaded_regions[r_id]
		if is_instance_valid(r_node):
			_cache_changes_from_region(r_id, r_node)
			_cache_npcs_from_region(r_id, r_node)
	
	# Serileştirilebilir veri sözlüğü
	var serialized_npcs: Dictionary = {}
	for npc_id in unloaded_npcs_cache:
		var entry = unloaded_npcs_cache[npc_id].duplicate(true)
		var pos = entry.get("position", Vector2.ZERO)
		if pos is Vector2:
			entry["position"] = [pos.x, pos.y]
		serialized_npcs[npc_id] = entry
	
	return {
		"active_region_id": active_region_id,
		"interactables_cache": unloaded_interactables_cache.duplicate(true),
		"unloaded_npcs": serialized_npcs
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("active_region_id") and data["active_region_id"] is String:
		active_region_id = data["active_region_id"]
	if data.has("interactables_cache") and data["interactables_cache"] is Dictionary:
		unloaded_interactables_cache = data["interactables_cache"].duplicate(true)
	if data.has("unloaded_npcs") and data["unloaded_npcs"] is Dictionary:
		unloaded_npcs_cache.clear()
		for npc_id in data["unloaded_npcs"]:
			var entry = data["unloaded_npcs"][npc_id].duplicate(true)
			if entry.has("position") and entry["position"] is Array and entry["position"].size() >= 2:
				entry["position"] = Vector2(entry["position"][0], entry["position"][1])
			unloaded_npcs_cache[npc_id] = entry
	
	# Yüklü bölgelere hemen uygula
	for r_id in loaded_regions:
		var r_node = loaded_regions[r_id]
		if is_instance_valid(r_node):
			_apply_cached_changes_to_region(r_id, r_node)
			_restore_cached_npcs_in_region(r_id, r_node)
