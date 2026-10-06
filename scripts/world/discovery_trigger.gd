extends Area2D

# Project T - Keşif Tetikleme Alanı (DiscoveryTrigger)
# Oyuncu bölgeye girdiğinde DiscoveryManager aracılığıyla tek seferlik konum bildirimi açar.

@export var location_id: String = "secret_glade"
@export var location_title: String = "Gizli Orman Açıklığı"
@export var location_subtitle: String = "Kadim Ağaç Çemberi"

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Sadece Player (Layer 2)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		var dm = get_node_or_null("/root/DiscoveryManager")
		if dm:
			dm.discover_location(location_id, location_title, location_subtitle)
		var qm = get_node_or_null("/root/QuestManager")
		if qm:
			qm.advance_quest_condition(QuestData.ConditionType.DISCOVERY, location_id)
