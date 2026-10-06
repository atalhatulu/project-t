@tool
extends Resource
class_name QuestData

# Project T - Veri Odaklı Görev Kaynağı (QuestData)
# Görev Aşamaları: AVAILABLE, ACTIVE, COMPLETED, FAILED
# Koşullar: DIALOGUE, DISCOVERY, ITEM_COLLECT, ENEMY_KILL

enum QuestStage { AVAILABLE, ACTIVE, COMPLETED, FAILED }
enum ConditionType { DIALOGUE, DISCOVERY, ITEM_COLLECT, ENEMY_KILL, EVENT_TRIGGER }

@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var stage: QuestStage = QuestStage.AVAILABLE

# Hedefler ve İpuçları (Harita işaretçisi yerine söylenti ve ipuçları)
@export var rumor_source: String = "" # Örn: "Kızıl Han'da konuşulanlar"
@export var objective_text: String = ""
@export var condition_type: ConditionType = ConditionType.ITEM_COLLECT
@export var target_id: String = "" # Eşya id, NPC id, Keşif id veya Düşman türü
@export var target_count: int = 1
@export var current_progress: int = 0

# Görev Ödülleri
@export var reward_items: Array[Dictionary] = [] # [{"item_id": "cooper_coins", "amount": 20}]
@export var completion_dialogue: String = ""
@export var log_entries: Array[String] = [] # Oyuncu günlüğü notları

func is_completed() -> bool:
	return stage == QuestStage.COMPLETED

func is_active() -> bool:
	return stage == QuestStage.ACTIVE

func is_available() -> bool:
	return stage == QuestStage.AVAILABLE

func is_failed() -> bool:
	return stage == QuestStage.FAILED

func update_progress(amount: int = 1) -> bool:
	if stage != QuestStage.ACTIVE:
		return false
	current_progress += amount
	if current_progress >= target_count:
		current_progress = target_count
		return true
	return false

func to_dict() -> Dictionary:
	return {
		"quest_id": quest_id,
		"title": title,
		"description": description,
		"stage": stage,
		"rumor_source": rumor_source,
		"objective_text": objective_text,
		"condition_type": condition_type,
		"target_id": target_id,
		"target_count": target_count,
		"current_progress": current_progress,
		"log_entries": log_entries.duplicate()
	}

func from_dict(d: Dictionary) -> void:
	if d.has("quest_id"): quest_id = d["quest_id"]
	if d.has("title"): title = d["title"]
	if d.has("description"): description = d["description"]
	if d.has("stage"): stage = d["stage"]
	if d.has("rumor_source"): rumor_source = d["rumor_source"]
	if d.has("objective_text"): objective_text = d["objective_text"]
	if d.has("condition_type"): condition_type = d["condition_type"]
	if d.has("target_id"): target_id = d["target_id"]
	if d.has("target_count"): target_count = d["target_count"]
	if d.has("current_progress"): current_progress = d["current_progress"]
	if d.has("log_entries"): log_entries = Array(d["log_entries"], TYPE_STRING, &"", null)
