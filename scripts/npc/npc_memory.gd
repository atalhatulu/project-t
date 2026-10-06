extends Node
class_name NPCMemory

# Project T - Gelişmiş NPC Hafıza ve Bilgi Paylaşım Sistemi
# Yakın geçmişte yaşanan olayları, oyuncu etkileşimlerini ve diğer NPC'lerden öğrenilen dedikoduları/bilgileri saklar.

# memory_entry = { "type": String, "timestamp_day": int, "timestamp_hour": int, "details": Dictionary }
var events: Array[Dictionary] = []

# Bilgi bankası: key -> { "id": String, "source_npc_id": String, "content": String, "timestamp_hour": int }
var known_information: Dictionary = {}

var talk_count_with_player: int = 0
var last_talk_hour: int = -1
var last_talk_day: int = -1

func record_event(event_type: String, details: Dictionary = {}) -> void:
	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	var cur_day = tm.current_day if tm else 1
	var cur_hour = tm.current_hour if tm else 8

	events.append({
		"type": event_type,
		"day": cur_day,
		"hour": cur_hour,
		"details": details
	})

	if events.size() > 25:
		events.pop_front()

# Bilgi öğrenme ve paylaşma fonksiyonu
func learn_info(info_id: String, source_id: String, content: String) -> bool:
	if known_information.has(info_id):
		return false # Zaten biliniyor

	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	var cur_hour = tm.current_hour if tm else 8

	known_information[info_id] = {
		"id": info_id,
		"source_npc_id": source_id,
		"content": content,
		"hour": cur_hour
	}
	record_event("learned_info", { "info_id": info_id, "from": source_id })
	return true

func has_info(info_id: String) -> bool:
	return known_information.has(info_id)

func get_info(info_id: String) -> Dictionary:
	return known_information.get(info_id, {})

func get_shareable_info() -> Array:
	return known_information.values()

func on_talked_with_player() -> void:
	talk_count_with_player += 1
	var tm = get_node_or_null("/root/TimeManager")
	last_talk_day = tm.current_day if tm else 1
	last_talk_hour = tm.current_hour if tm else 8
	record_event("player_talk", { "count": talk_count_with_player })

func has_met_player() -> bool:
	return talk_count_with_player > 0

func has_talked_recently() -> bool:
	if not has_met_player():
		return false
	var tm = get_node_or_null("/root/TimeManager")
	if not tm:
		return false
	if tm.current_day == last_talk_day and (tm.current_hour - last_talk_hour) < 2:
		return true
	return false
