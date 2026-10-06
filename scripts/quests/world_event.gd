@tool
extends Node2D
class_name WorldEvent

# Project T - Dinamik Dünya Olayı (WorldEvent)
# Oyuncunun kabul etmesini beklemeden dünyada bağımsız başlar.
# Oyuncu müdahale ederse veya görmezden gelirse kalıcı sonuçlar doğurur.

signal event_started(event_id: String)
signal event_resolved(event_id: String, player_intervened: bool)

enum EventStatus { PENDING, ACTIVE, RESOLVED_SUCCESS, RESOLVED_IGNORED }

@export var event_id: String = "caravan_ambush"
@export var event_title: String = "Haydut Kervan Baskını"
@export var status: EventStatus = EventStatus.PENDING
@export var trigger_hour: int = 12 # Olayın tetikleneceği saat
@export var expiration_hours: int = 4 # Görmezden gelinirse bu kadar saat sonra haydutlar kervanı yağmalar
@export var event_zone_radius: float = 160.0

var elapsed_hours: int = 0
var start_hour: int = -1
var start_day: int = -1

# Olay nesneleri (Kervan arabası, tüccar ve haydutlar)
var bandits: Array[EnemyCreature] = []
var merchant_body: CharacterBody2D = null
var crate_loot: Node2D = null

func _ready() -> void:
	add_to_group("world_event")
	if is_inside_tree():
		var tm = get_node_or_null("/root/TimeManager")
		if tm:
			tm.hour_changed.connect(_on_hour_changed)
	_build_visuals()

func _build_visuals() -> void:
	queue_redraw()

func _draw() -> void:
	if status == EventStatus.PENDING:
		return
	
	# Ahşap kırık kervan arabası ve tekerlekleri
	var wagon_col = Color("5c3a1c")
	var iron_col = Color("383e47")
	
	# Gövde
	draw_rect(Rect2(-24, -14, 48, 28), wagon_col, true)
	draw_rect(Rect2(-24, -14, 48, 28), Color("382210"), false, 1.5)
	
	# Tente
	var tent_col = Color("d97706") if status == EventStatus.ACTIVE else (Color("4b5563") if status == EventStatus.RESOLVED_IGNORED else Color("22c55e"))
	draw_rect(Rect2(-20, -10, 40, 20), tent_col, true)
	
	# Kırık tekerlekler
	draw_circle(Vector2(-18, 14), 6.0, iron_col)
	draw_circle(Vector2(18, 14), 6.0, iron_col)
	draw_circle(Vector2(-18, -14), 6.0, iron_col)
	draw_circle(Vector2(18, -14), 6.0, iron_col)
	
	# Kan/yağma veya zafer kalıntısı
	if status == EventStatus.RESOLVED_IGNORED:
		draw_line(Vector2(-15, -5), Vector2(25, 12), Color("7f1d1d"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-40, -22), "Yağmalanmış Kervan", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("ef4444"))
	elif status == EventStatus.RESOLVED_SUCCESS:
		draw_string(ThemeDB.fallback_font, Vector2(-35, -22), "Kurtarılmış Kervan", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("4ade80"))
	elif status == EventStatus.ACTIVE:
		draw_string(ThemeDB.fallback_font, Vector2(-30, -22), "Kervan Baskını!", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("facc15"))

func _on_hour_changed(new_hour: int) -> void:
	var tm = get_node_or_null("/root/TimeManager") if is_inside_tree() else null
	var current_day = tm.current_day if tm else 1

	# 1. Beklemedeyse ve saat geldiyse olayı dünyada başlat
	if status == EventStatus.PENDING:
		if new_hour >= trigger_hour:
			start_event(new_hour, current_day)
		return

	# 2. Olay aktifse süre aşımını kontrol et (Oyuncunun görmezden gelmesi durumu)
	if status == EventStatus.ACTIVE:
		elapsed_hours += 1
		if elapsed_hours >= expiration_hours:
			# Oyuncu müdahale etmedi, kervan yağmalandı!
			resolve_ignored()

func start_event(hour: int, day: int) -> void:
	status = EventStatus.ACTIVE
	start_hour = hour
	start_day = day
	elapsed_hours = 0
	
	# Haydutları konuşlandır
	_spawn_event_actors()
	event_started.emit(event_id)
	
	# NPC Hafızasına dedikodu olarak düşer
	_propagate_rumor_to_npcs("Kervan bozkır yolunda haydutlarca kuşatıldı!")
	queue_redraw()

func _spawn_event_actors() -> void:
	# 2 Tane Haydut oluştur
	for i in range(2):
		var bandit = preload("res://scenes/creatures/enemy_creature.tscn").instantiate()
		bandit.enemy_type = "bandit"
		bandit.position = Vector2(30.0 * (i + 1), -10.0 + (i * 25.0))
		add_child(bandit)
		bandits.append(bandit)
		bandit.died.connect(_on_bandit_killed)

func _on_bandit_killed(_killer: Node) -> void:
	# Haydutların tümü temizlendi mi kontrol et
	var all_dead = true
	for b in bandits:
		if is_instance_valid(b) and b.current_state != BaseCreature.CreatureState.DEAD:
			all_dead = false
			break
	
	if all_dead:
		resolve_intervened()

func resolve_intervened() -> void:
	if status != EventStatus.ACTIVE: return
	status = EventStatus.RESOLVED_SUCCESS
	event_resolved.emit(event_id, true)
	
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if not qm and get_parent() != null:
		qm = get_parent().get_node_or_null("QuestManager")
	if qm:
		qm.advance_quest_condition(QuestData.ConditionType.EVENT_TRIGGER, event_id)
		qm.add_journal_note("Kervanı haydutların pençesinden kurtardın! Tüccarlar minnettar kaldı.")
	_propagate_rumor_to_npcs("Cesur bir yolcu kervanı haydutlardan kurtarmış!")
	queue_redraw()

func resolve_ignored() -> void:
	if status != EventStatus.ACTIVE: return
	status = EventStatus.RESOLVED_IGNORED
	event_resolved.emit(event_id, false)
	
	# Haydutlar işini bitirip kaçar
	for b in bandits:
		if is_instance_valid(b):
			b.queue_free()
	bandits.clear()
	
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if not qm and get_parent() != null:
		qm = get_parent().get_node_or_null("QuestManager")
	if qm:
		qm.fail_quest("caravan_defense")
		qm.add_journal_note("Kervan haydutlarca tamamen yağmalandı. Vadi halkı tedirgin.")
	_propagate_rumor_to_npcs("Dağ yolundaki kervan yağmalanmış, kimse yardıma gitmemiş...")
	queue_redraw()

func _propagate_rumor_to_npcs(rumor_text: String) -> void:
	if not is_inside_tree(): return
	var npcs = get_tree().get_nodes_in_group("npc")
	for n in npcs:
		if n is BaseNPC and n.memory:
			n.memory.learn_info("rumor_" + event_id, "world", rumor_text)
