extends Node
class_name NPCSocial

# Project T - NPC Sosyal İlişki ve Sohbet Yöneticisi
# -100 ile +100 arası ilişki skorları, konuşma kilidi (cooldown) ve bilgi paylaşımı.

# relationships = { "target_npc_id": float (-100.0 .. 100.0) }
var relationships: Dictionary = {}

# Konuşma zamanlayıcıları
var chat_cooldown_timer: float = 0.0
const CHAT_COOLDOWN_TIME: float = 20.0 # Bir sohbet bittikten sonra en az 20 saniye yeni sohbet başlatma

var is_chatting: bool = false
var chat_partner: BaseNPC = null
var chat_duration_timer: float = 0.0

func _process(delta: float) -> void:
	if chat_cooldown_timer > 0.0:
		chat_cooldown_timer -= delta

	if is_chatting:
		chat_duration_timer -= delta
		if chat_duration_timer <= 0.0:
			end_chat()

func get_relationship(target_id: String) -> float:
	return relationships.get(target_id, 0.0) # Varsayılan nötr (0)

func set_relationship(target_id: String, val: float) -> void:
	relationships[target_id] = clamp(val, -100.0, 100.0)

func modify_relationship(target_id: String, delta_val: float) -> void:
	var cur = get_relationship(target_id)
	set_relationship(target_id, cur + delta_val)

func can_initiate_chat() -> bool:
	return (not is_chatting) and (chat_cooldown_timer <= 0.0)

func start_chat_with(partner: BaseNPC, duration: float = 4.0) -> void:
	is_chatting = true
	chat_partner = partner
	chat_duration_timer = duration

	# İlişkiyi hafifçe artır (+2)
	modify_relationship(partner.npc_id, 2.0)

	# Bilgi paylaşımı yap
	var parent_npc = get_parent() as BaseNPC
	if parent_npc and parent_npc.memory and partner.memory:
		_exchange_knowledge(parent_npc, partner)

func _exchange_knowledge(speaker: BaseNPC, listener: BaseNPC) -> void:
	var speaker_info = speaker.memory.get_shareable_info()
	for info in speaker_info:
		# Dinleyiciye bu bilgiyi aktar
		listener.memory.learn_info(info["id"], speaker.npc_id, info["content"])

func end_chat() -> void:
	is_chatting = false
	chat_partner = null
	chat_cooldown_timer = CHAT_COOLDOWN_TIME
