@tool
extends Node

# Project T - Veri Odaklı Fraksiyon & İtibar Yöneticisi (FactionManager)
# Autoload Singleton: FactionManager
#
# Gruplar (Factions):
# 1. "villagers" (Köylüler)
# 2. "guards" (Muhafızlar)
# 3. "bandits" (Haydutlar)
#
# İtibar Aralığı: -100 ile +100 arası
# Eşik Değerleri:
#  < -40: Düşman (Hostile)
#  -40 .. -10: Şüpheli / Soğuk (Suspicious / Unfriendly)
#  -10 .. +10: Nötr (Neutral)
#  +10 .. +40: Dostane (Friendly)
#  > +40: Saygın / Müttefik (Honored / Allied)

signal reputation_changed(faction_id: String, new_val: int, change_delta: int)
signal crime_witnessed(crime_type: String, victim_faction: String, witness_id: String, location: Vector2)
signal guard_alerted(guard_node: Node, target: CharacterBody2D, alert_level: String)

enum RelationLevel { HOSTILE, SUSPICIOUS, NEUTRAL, FRIENDLY, ALLIED }

# Fraksiyon Veri Havuzu
# faction_id -> { "name": String, "reputation": int, "base_relation_with_player": int }
var factions: Dictionary = {
	"villagers": {
		"name": "Köylüler",
		"description": "Kızıl Vadi'nin barışçıl sakinleri, çiftçiler ve zanaatkârlar.",
		"reputation": 0
	},
	"guards": {
		"name": "Muhafızlar",
		"description": "Köy meydanını ve nizamı koruyan silahlı vadi muhafızları.",
		"reputation": 0
	},
	"bandits": {
		"name": "Haydutlar",
		"description": "Bozkır ve dağ yollarında pusu kuran kanunsuz çeteler.",
		"reputation": -50 # Başlangıçta düşmanca
	}
}

# Aktif suçlar ve arananlar (bounty/crime state)
var active_bounties: Dictionary = {
	"guards": 0, # Muhafızların oyuncuya kestiği suç puanı
	"villagers": 0
}

func _ready() -> void:
	add_to_group("faction_manager")

# 1. İTİBAR ERİŞİM VE DEĞİŞTİRME
func get_reputation(faction_id: String) -> int:
	if factions.has(faction_id):
		return factions[faction_id].get("reputation", 0)
	return 0

func set_reputation(faction_id: String, value: int) -> void:
	if not factions.has(faction_id):
		return
	var clamped_val = clampi(value, -100, 100)
	var prev_val = factions[faction_id]["reputation"]
	var delta = clamped_val - prev_val
	factions[faction_id]["reputation"] = clamped_val
	reputation_changed.emit(faction_id, clamped_val, delta)

func modify_reputation(faction_id: String, delta: int) -> int:
	if not factions.has(faction_id):
		return 0
	var current = factions[faction_id].get("reputation", 0)
	var new_val = clampi(current + delta, -100, 100)
	var actual_delta = new_val - current
	factions[faction_id]["reputation"] = new_val
	reputation_changed.emit(faction_id, new_val, actual_delta)
	return new_val

func get_relation_level(faction_id: String) -> RelationLevel:
	var rep = get_reputation(faction_id)
	if rep <= -40:
		return RelationLevel.HOSTILE
	elif rep <= -10:
		return RelationLevel.SUSPICIOUS
	elif rep < 10:
		return RelationLevel.NEUTRAL
	elif rep < 40:
		return RelationLevel.FRIENDLY
	else:
		return RelationLevel.ALLIED

# 2. SUÇ & GÖRGÜ TANIĞI SİSTEMİ (Witness & Detection)
# crime_type: "theft", "assault", "murder"
# victim_faction: "villagers", "guards", vb.
# crime_pos: Olay mahalli
func report_crime(crime_type: String, victim_faction: String, crime_pos: Vector2, perpetrator: CharacterBody2D = null) -> bool:
	var witness = find_witness_for_crime(crime_pos, perpetrator)
	if witness != null:
		# Suç bir görgü tanığı tarafından fark edildi!
		var witness_id = witness.get("npc_id") if "npc_id" in witness else witness.name
		record_crime_effects(crime_type, victim_faction, witness_id, crime_pos, perpetrator)
		return true
	return false # Kimse görmedi, suç cezasız kaldı (gizli eylem)

# Yakındaki bir NPC veya Muhafız suç mahallini görebiliyor mu?
func find_witness_for_crime(crime_pos: Vector2, perpetrator: CharacterBody2D = null, sight_radius: float = 240.0) -> Node:
	if not is_inside_tree():
		return null
	
	# Görgü tanığı olabilecek varlıklar: Köylüler (BaseNPC) ve Muhafızlar (GuardCreature)
	var candidates: Array[Node] = []
	candidates.append_array(get_tree().get_nodes_in_group("npc"))
	candidates.append_array(get_tree().get_nodes_in_group("guard"))

	for node in candidates:
		if not (node is Node2D):
			continue
		var n2d = node as Node2D
		# Suçu işleyen kişi kendisi tanık olamaz
		if perpetrator != null and n2d == perpetrator:
			continue
		
		# Mesafe kontrolü
		var dist = n2d.global_position.distance_to(crime_pos)
		if dist <= sight_radius:
			# NPC uyuyorsa göremez
			if "current_state" in n2d and str(n2d.current_state) == "SLEEP":
				continue
			return n2d
			
	return null

func record_crime_effects(crime_type: String, victim_faction: String, witness_id: String, crime_pos: Vector2, perpetrator: CharacterBody2D) -> void:
	match crime_type:
		"theft":
			modify_reputation("villagers", -15)
			modify_reputation("guards", -10)
			active_bounties["guards"] = active_bounties.get("guards", 0) + 15
		"assault":
			if victim_faction == "guards":
				modify_reputation("guards", -30)
				active_bounties["guards"] = active_bounties.get("guards", 0) + 35
			else:
				modify_reputation("villagers", -25)
				modify_reputation("guards", -20)
				active_bounties["guards"] = active_bounties.get("guards", 0) + 25
		"murder":
			modify_reputation("villagers", -50)
			modify_reputation("guards", -45)
			active_bounties["guards"] = active_bounties.get("guards", 0) + 60

	crime_witnessed.emit(crime_type, victim_faction, witness_id, crime_pos)
	alert_nearby_guards(crime_pos, perpetrator)

# Muhafızları uyar
func alert_nearby_guards(crime_pos: Vector2, target: CharacterBody2D, alert_radius: float = 400.0) -> void:
	if not is_inside_tree():
		return
	for guard in get_tree().get_nodes_in_group("guard"):
		if guard is Node2D:
			var d = guard.global_position.distance_to(crime_pos)
			if d <= alert_radius:
				if guard.has_method("receive_crime_alert"):
					guard.receive_crime_alert(target, "hostile")
				guard_alerted.emit(guard, target, "hostile")

# 3. YARDIM VE GÖREV ETKİLERİ
func on_quest_completed(quest_id: String) -> void:
	match quest_id:
		"kemal_lost_sickle":
			modify_reputation("villagers", 20)
			modify_reputation("guards", 5)
		"caravan_defense":
			modify_reputation("villagers", 25)
			modify_reputation("guards", 25)
			modify_reputation("bandits", -20)

func on_enemy_defeated(enemy_type: String) -> void:
	if enemy_type == "bandit":
		modify_reputation("villagers", 5)
		modify_reputation("guards", 8)
		modify_reputation("bandits", -10)

# 4. KAYIT & YÜKLEME UYUMLULUĞU
func get_save_data() -> Dictionary:
	var rep_data: Dictionary = {}
	for f_id in factions:
		rep_data[f_id] = factions[f_id].get("reputation", 0)
	return {
		"reputations": rep_data,
		"bounties": active_bounties.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("reputations") and data["reputations"] is Dictionary:
		for f_id in data["reputations"]:
			if factions.has(f_id):
				factions[f_id]["reputation"] = data["reputations"][f_id]
	if data.has("bounties") and data["bounties"] is Dictionary:
		active_bounties = data["bounties"].duplicate(true)
