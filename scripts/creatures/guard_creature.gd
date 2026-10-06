@tool
extends BaseCreature
class_name GuardCreature

# Project T - Köy ve Vadi Muhafızı (GuardCreature)
# Davranışlar:
# 1. Devriye / Nöbet (PATROL / IDLE)
# 2. Uyarma (WARN): Şüpheli veya kural ihlali yapan oyuncuya yaklaşır, uyarır
# 3. Takip Etme (CHASE): Düşman veya suçlu oyuncuyu yakalamaya çalışır
# 4. Saldırma (ATTACK): Kılıçla asayişi sağlar
# 5. Geri Çekilme (RETREAT): Kendi nöbet mevkiine döner

enum GuardBehavior { PATROL, WARN, CHASE, ATTACK, RETREAT }
var guard_state: GuardBehavior = GuardBehavior.PATROL

@export var guard_id: String = "guard_01"
@export var guard_title: String = "Vadi Muhafızı"
@export var warning_distance: float = 160.0
@export var patrol_radius: float = 80.0

var warning_cooldown: float = 0.0
var warning_dialogue_active: bool = false
var has_warned_player: bool = false
var current_alert_level: String = "none" # "none", "warn", "hostile"

func _ready() -> void:
	creature_name = "Vadi Muhafızı"
	category = CreatureCategory.HOSTILE # Savaş altyapısını kullanabilmesi için
	max_health = 75
	attack_damage = 15
	base_speed = 50.0
	flee_or_chase_speed = 100.0
	detection_range = 180.0
	attack_range = 26.0
	max_chase_distance_from_origin = 320.0
	loot_table = [
		{"item_id": "cooper_coins", "amount": 20, "chance": 0.9},
		{"item_id": "rusted_sword", "amount": 1, "chance": 0.4}
	]
	
	add_to_group("guard")
	add_to_group("interactable")
	super._ready()
	_setup_interaction()
	queue_redraw()

func _setup_interaction() -> void:
	var area = get_node_or_null("InteractionArea")
	if not area:
		area = Area2D.new()
		area.name = "InteractionArea"
		area.collision_layer = 0
		area.collision_mask = 2
		var col = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 28.0
		col.shape = circle
		area.add_child(col)
		add_child(area)

func get_action_prompt_text() -> String:
	return "Konuş"

func interact_with(player: CharacterBody2D) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	var qm = get_node_or_null("/root/QuestManager")
	if not dm or not qm:
		return

	var inv = player.get_inventory() if player and player.has_method("get_inventory") else null
	var q_valley = qm.get_quest("silence_of_the_valley")

	# Eğer oyuncunun elinde bandit_ledger varsa ve görev aktifse: Muhafızlara teslim et seçeneği!
	if q_valley and q_valley.is_active() and inv and inv.has_item("bandit_ledger", 1):
		qm.resolve_valley_quest("guards", inv)
		dm.start_dialogue(guard_title, "Bu... Bu haydutların baskın kayıt defteri değil mi?! Tüm pusu mevkilerini ve kervanları tek tek yazmışlar! Hemen müfrezeyi topluyorum, dağ yolunu temizleyeceğiz. Al şu 150 bakır sikke ödülünü, vadi sana minnettar!")
		return

	if q_valley and q_valley.is_completed():
		if qm.valley_quest_choice == "guards":
			dm.start_dialogue(guard_title, "Getirdiğin deliller sayesinde haydut kampı dağıtıldı! Kervan yolu artık güven altında, tebrikler kahraman.")
		else:
			dm.start_dialogue(guard_title, "Dağ yolunda hala haydut kalıntıları olduğu söyleniyor... Gözümüzü dört açtık.")
		return

	if q_valley and q_valley.is_available():
		dm.start_dialogue(guard_title, "Kervan yolu günlerdir tekinsiz yabancı. Doğu dağ yolundan geçen tüccarlardan haber alamıyoruz. Şüpheli bir şey görürsen bize bildir.")
		return

	dm.start_dialogue(guard_title, "Köy meydanı nizamı ve asayişi kontrolümüz altında.")

func _physics_process(delta: float) -> void:
	if current_state == CreatureState.DEAD:
		return

	if warning_cooldown > 0.0:
		warning_cooldown -= delta

	# Fraksiyon itibar durumuna göre anlık algılama
	_evaluate_guard_behavior(delta)
	super._physics_process(delta)

func _evaluate_guard_behavior(_delta: float) -> void:
	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	var dist_to_player = 9999.0
	if target_player != null and is_instance_valid(target_player):
		dist_to_player = global_position.distance_to(target_player.global_position)

	var fm = get_node_or_null("/root/FactionManager") if is_inside_tree() else null
	var relation: FactionManager.RelationLevel = FactionManager.RelationLevel.NEUTRAL
	if fm:
		relation = fm.get_relation_level("guards")

	# Eğer oyuncu muhafızlara karşı düşmansa (veya aktif suç/hostile alarmı varsa): Takip et & saldır
	if relation == FactionManager.RelationLevel.HOSTILE or current_alert_level == "hostile":
		if dist_to_player < detection_range:
			if current_state != CreatureState.ATTACK and current_state != CreatureState.CHASE:
				current_state = CreatureState.CHASE
				guard_state = GuardBehavior.CHASE
		return

	# Eğer oyuncu şüpheliyse (-40 ile -10 arası itibar): Yaklaş ve uyar
	if relation == FactionManager.RelationLevel.SUSPICIOUS or current_alert_level == "warn":
		if dist_to_player < warning_distance and dist_to_player > attack_range + 20.0:
			if warning_cooldown <= 0.0:
				trigger_warning(target_player)
				guard_state = GuardBehavior.WARN
		return

	# Normal durumda muhafız oyuncuya düşman değildir (barışçıl devriye)
	if current_state == CreatureState.CHASE and (relation == FactionManager.RelationLevel.NEUTRAL or relation == FactionManager.RelationLevel.FRIENDLY or relation == FactionManager.RelationLevel.ALLIED):
		if current_alert_level == "none":
			current_state = CreatureState.RETREAT
			guard_state = GuardBehavior.RETREAT

func trigger_warning(player: CharacterBody2D) -> void:
	warning_cooldown = 10.0 # 10 saniye arayla uyar
	has_warned_player = true
	if is_inside_tree():
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(guard_title, "Dur orada yabancı! Adımlarına dikkat et, köy nizamını bozanları kılıçtan geçiririz.")

func receive_crime_alert(target: CharacterBody2D, alert_level: String) -> void:
	current_alert_level = alert_level
	target_player = target
	if alert_level == "hostile":
		current_state = CreatureState.CHASE
		guard_state = GuardBehavior.CHASE
	elif alert_level == "warn":
		guard_state = GuardBehavior.WARN
		trigger_warning(target)

func _draw() -> void:
	var flash_mod = Color(1, 1, 1, 1) if hit_flash_timer <= 0.0 else Color(1, 0.3, 0.3, 1)

	# Taban gölgesi
	draw_circle(Vector2(0, 6), 9.0, Color(0, 0, 0, 0.4))

	# Gövde (Zırhlı muhafız: Mavi tunik, çelik göğüslük)
	draw_rect(Rect2(-7, -8, 14, 15), Color("1e3a8a") * flash_mod) # Mavi tunik
	draw_rect(Rect2(-5, -6, 10, 10), Color("94a3b8") * flash_mod) # Çelik zırh
	
	# Miğfer & Yüz
	draw_circle(Vector2(0, -12), 5.5, Color("64748b") * flash_mod) # Çelik miğfer
	draw_rect(Rect2(-2, -13, 4, 3), Color("f1f5f9")) # Miğfer siperliği
	draw_line(Vector2(0, -17), Vector2(0, -19), Color("dc2626"), 2.0) # Kırmızı miğfer tüyü

	# Kalkan (Sol el)
	draw_rect(Rect2(-10, -5, 4, 10), Color("475569"))
	draw_rect(Rect2(-9, -3, 2, 6), Color("e2e8f0"))

	# Kılıç (Sağ el)
	draw_line(Vector2(7, -3), Vector2(13, 2), Color("cbd5e1"), 2.0)
	draw_circle(Vector2(7, -3), 1.5, Color("d4af37")) # Altın kabza

	# Zırhlı Çizmeler
	draw_rect(Rect2(-5, 7, 3, 5), Color("334155"))
	draw_rect(Rect2(2, 7, 3, 5), Color("334155"))
