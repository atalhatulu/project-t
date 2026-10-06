@tool
extends Node

# Project T - Merkezi Kayıt & Yükleme Yöneticisi (SaveManager)
# Autoload Singleton: SaveManager
# Sürüm kontrollü JSON formatı (user://saves/slot_X.json)
# 3 Kayıt Slotu, güvenli hata yakalama, sahne geçişi veri sürekliliği

signal game_saved(slot_index: int, success: bool)
signal game_loaded(slot_index: int, success: bool)
signal save_error(message: String)

const CURRENT_SAVE_VERSION: int = 1
const MAX_SLOTS: int = 3
const SAVE_DIR: String = "user://saves"

# Sahne geçişleri ve geçici hafıza için önbellek
var runtime_world_cache: Dictionary = {}

func _ready() -> void:
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	var da = DirAccess.open("user://")
	if da:
		if not da.dir_exists("saves"):
			da.make_dir("saves")

func get_slot_path(slot_index: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot_index, 1, MAX_SLOTS)]

func save_slot_exists(slot_index: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_index))

func get_slot_metadata(slot_index: int) -> Dictionary:
	var path = get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"exists": false, "corrupted": true}
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		return {"exists": true, "corrupted": true}
	
	var data = json.data
	if data is Dictionary:
		return {
			"exists": true,
			"corrupted": false,
			"version": data.get("version", 0),
			"timestamp": data.get("timestamp", ""),
			"player_health": data.get("player", {}).get("current_health", 100),
			"day": data.get("time", {}).get("current_day", 1),
			"hour": data.get("time", {}).get("current_hour", 8),
			"region_name": data.get("world", {}).get("region_name", "Kızıl Vadi")
		}
	return {"exists": true, "corrupted": true}

# 1. TÜM OYUN DÜNYASINI KAYDET (Save Game)
func save_game(slot_index: int) -> bool:
	var path = get_slot_path(slot_index)
	_ensure_save_directory()
	
	var full_data = _collect_game_data()
	full_data["version"] = CURRENT_SAVE_VERSION
	full_data["timestamp"] = Time.get_datetime_string_from_system()
	
	var json_string = JSON.stringify(full_data, "  ")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err_msg = "Kayıt dosyası yazılamadı: " + path
		push_error(err_msg)
		save_error.emit(err_msg)
		game_saved.emit(slot_index, false)
		return false
	
	file.store_string(json_string)
	file.close()
	
	game_saved.emit(slot_index, true)
	return true

# 2. KAYITTAN OYUNU GERİ YÜKLE (Load Game)
func load_game(slot_index: int) -> bool:
	var path = get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		var err_msg = "Kayıt dosyası bulunamadı: " + path
		push_warning(err_msg)
		save_error.emit(err_msg)
		game_loaded.emit(slot_index, false)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		var err_msg = "Kayıt dosyası açılamadı: " + path
		save_error.emit(err_msg)
		game_loaded.emit(slot_index, false)
		return false
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		var err_msg = "Bozuk veya geçersiz kayıt dosyası: " + json.get_error_message()
		push_error(err_msg)
		save_error.emit(err_msg)
		game_loaded.emit(slot_index, false)
		return false
	
	var data = json.data
	if not (data is Dictionary):
		save_error.emit("Kayıt formatı JSON nesnesi değil.")
		game_loaded.emit(slot_index, false)
		return false
	
	# Verileri dünyaya uygula
	_apply_game_data(data)
	game_loaded.emit(slot_index, true)
	return true

# 3. VERİ TOPLAMA (Collect)
func _collect_game_data() -> Dictionary:
	var data: Dictionary = {}
	
	# Oyuncu Verileri
	var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if not player and get_parent() != null:
		player = get_parent().get_node_or_null("Player")
	if not player and is_inside_tree() and get_tree().root != null:
		player = get_tree().root.get_node_or_null("Player")
	if player:
		var inv = player.get_inventory() if player.has_method("get_inventory") else null
		data["player"] = {
			"position": [player.global_position.x, player.global_position.y],
			"current_health": player.current_health,
			"max_health": player.max_health,
			"elevation_level": player.elevation_level,
			"inventory": inv.get_save_data() if inv and inv.has_method("get_save_data") else []
		}
	
	# Zaman Verileri
	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	if tm:
		data["time"] = {
			"current_day": tm.current_day,
			"current_hour": tm.current_hour,
			"current_minute": tm.current_minute,
			"total_game_seconds": tm.total_game_seconds
		}
	
	# Hava Durumu Verileri
	var wm = get_tree().get_first_node_in_group("weather_manager") if is_inside_tree() else null
	if wm:
		data["weather"] = {
			"current_weather": wm.current_weather,
			"weather_timer_hours": wm.weather_timer_hours
		}
	
	# Görev ve Olay Verileri
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if qm:
		var q_dict: Dictionary = {}
		for q_id in qm.quests:
			var q: QuestData = qm.quests[q_id]
			q_dict[q_id] = q.to_dict()
		data["quests"] = {
			"quests": q_dict,
			"notes": qm.general_journal_notes.duplicate(),
			"valley_quest_choice": qm.valley_quest_choice
		}
	
	# İtibar ve Fraksiyon Verileri
	var fm = get_node_or_null("/root/FactionManager") if is_inside_tree() else null
	if fm and fm.has_method("get_save_data"):
		data["factions"] = fm.get_save_data()
	
	# Harita ve Seyahat Verileri
	var mm = get_node_or_null("/root/MapManager") if is_inside_tree() else null
	if mm and mm.has_method("get_save_data"):
		data["map"] = mm.get_save_data()
	
	# Bölgesel Yükleme Verileri (RegionManager)
	var rm = get_node_or_null("/root/RegionManager") if is_inside_tree() else null
	if rm and rm.has_method("get_save_data"):
		data["regional_data"] = rm.get_save_data()
	
	# NPC Hafızaları ve İhtiyaçları
	var npc_data: Dictionary = {}
	if is_inside_tree():
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc is BaseNPC:
				var entry: Dictionary = {
					"position": [npc.global_position.x, npc.global_position.y],
					"state": npc.current_state
				}
				if npc.needs:
					entry["needs"] = {
						"hunger": npc.needs.hunger,
						"energy": npc.needs.energy,
						"social": npc.needs.social
					}
				if npc.memory:
					entry["memory"] = {
						"talk_count": npc.memory.talk_count_with_player,
						"known_info": npc.memory.known_information.duplicate(true)
					}
				npc_data[npc.npc_id] = entry
	data["npcs"] = npc_data
	
	# Çevresel Etkileşimli Nesneler (Sandık, Kasa, Bitki, Harabe, vb.)
	var interactables_data: Dictionary = {}
	if is_inside_tree():
		for item in get_tree().get_nodes_in_group("interactable"):
			if item is BaseInteractable and item.interactable_id != "":
				interactables_data[item.interactable_id] = item.get_save_data()
	data["interactables"] = interactables_data
	
	# Dünya Olayları (WorldEvent)
	var events_data: Dictionary = {}
	if is_inside_tree():
		for ev in get_tree().get_nodes_in_group("world_event"):
			if ev is WorldEvent:
				events_data[ev.event_id] = {
					"status": ev.status,
					"elapsed_hours": ev.elapsed_hours,
					"start_hour": ev.start_hour,
					"start_day": ev.start_day
				}
	data["world_events"] = events_data
	
	return data

# 4. VERİLERİ DÜNYAYA UYGULA (Apply)
func _apply_game_data(data: Dictionary) -> void:
	if not is_inside_tree():
		return
	
	# Oyuncu
	if data.has("player"):
		var pdata = data["player"]
		var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		if not player and get_parent() != null:
			player = get_parent().get_node_or_null("Player")
		if not player and is_inside_tree() and get_tree().root != null:
			player = get_tree().root.get_node_or_null("Player")
		if player:
			if pdata.has("position") and pdata["position"].size() >= 2:
				player.global_position = Vector2(pdata["position"][0], pdata["position"][1])
			if pdata.has("current_health"): player.current_health = pdata["current_health"]
			if pdata.has("max_health"): player.max_health = pdata["max_health"]
			if pdata.has("elevation_level"): player.elevation_level = pdata["elevation_level"]
			if pdata.has("inventory") and player.has_method("get_inventory"):
				var inv = player.get_inventory()
				if inv and inv.has_method("load_save_data"):
					inv.load_save_data(pdata["inventory"])
	
	# Zaman
	if data.has("time"):
		var tdata = data["time"]
		var tm = get_node_or_null("/root/TimeManager")
		if tm:
			if tdata.has("current_day"): tm.current_day = tdata["current_day"]
			if tdata.has("current_hour"): tm.current_hour = tdata["current_hour"]
			if tdata.has("current_minute"): tm.current_minute = tdata["current_minute"]
			if tdata.has("total_game_seconds"): tm.total_game_seconds = tdata["total_game_seconds"]
			tm._update_time_values(true)
	
	# Hava Durumu
	if data.has("weather"):
		var wdata = data["weather"]
		var wm = get_tree().get_first_node_in_group("weather_manager")
		if wm:
			if wdata.has("current_weather"):
				wm.set_weather(wdata["current_weather"])
			if wdata.has("weather_timer_hours"):
				wm.weather_timer_hours = wdata["weather_timer_hours"]
	
	# Görevler
	if data.has("quests"):
		var qdata = data["quests"]
		var qm = get_node_or_null("/root/QuestManager")
		if qm:
			if qdata.has("quests") and qdata["quests"] is Dictionary:
				for q_id in qdata["quests"]:
					var q_dict = qdata["quests"][q_id]
					var q: QuestData = qm.get_quest(q_id)
					if q:
						q.from_dict(q_dict)
			if qdata.has("notes"):
				qm.general_journal_notes = Array(qdata["notes"], TYPE_STRING, &"", null)
			if qdata.has("valley_quest_choice"):
				qm.valley_quest_choice = qdata["valley_quest_choice"]
			qm.journal_updated.emit()
	
	# İtibar ve Fraksiyonlar
	if data.has("factions"):
		var fm = get_node_or_null("/root/FactionManager")
		if fm and fm.has_method("load_save_data"):
			fm.load_save_data(data["factions"])
	
	# Harita ve Seyahat
	if data.has("map"):
		var mm = get_node_or_null("/root/MapManager")
		if mm and mm.has_method("load_save_data"):
			mm.load_save_data(data["map"])
	
	# Bölgesel Yükleme Verileri (RegionManager)
	if data.has("regional_data"):
		var rm = get_node_or_null("/root/RegionManager")
		if rm and rm.has_method("load_save_data"):
			rm.load_save_data(data["regional_data"])
	
	# NPC Hafıza ve İhtiyaçları
	if data.has("npcs") and data["npcs"] is Dictionary:
		var ndata = data["npcs"]
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc is BaseNPC and ndata.has(npc.npc_id):
				var n_entry = ndata[npc.npc_id]
				if n_entry.has("position") and n_entry["position"].size() >= 2:
					npc.global_position = Vector2(n_entry["position"][0], n_entry["position"][1])
				if n_entry.has("needs") and npc.needs:
					npc.needs.hunger = n_entry["needs"].get("hunger", 80.0)
					npc.needs.energy = n_entry["needs"].get("energy", 80.0)
					npc.needs.social = n_entry["needs"].get("social", 80.0)
				if n_entry.has("memory") and npc.memory:
					npc.memory.talk_count_with_player = n_entry["memory"].get("talk_count", 0)
					if n_entry["memory"].has("known_info"):
						npc.memory.known_information = n_entry["memory"]["known_info"].duplicate(true)
	
	# Etkileşimli Nesneler
	if data.has("interactables") and data["interactables"] is Dictionary:
		var idata = data["interactables"]
		for item in get_tree().get_nodes_in_group("interactable"):
			if item is BaseInteractable and idata.has(item.interactable_id):
				item.load_save_data(idata[item.interactable_id])
	
	# Dünya Olayları
	if data.has("world_events") and data["world_events"] is Dictionary:
		var edata = data["world_events"]
		for ev in get_tree().get_nodes_in_group("world_event"):
			if ev is WorldEvent and edata.has(ev.event_id):
				var ev_info = edata[ev.event_id]
				ev.status = ev_info.get("status", ev.status)
				ev.elapsed_hours = ev_info.get("elapsed_hours", 0)
				ev.start_hour = ev_info.get("start_hour", -1)
				ev.start_day = ev_info.get("start_day", -1)
				ev.queue_redraw()
