@tool
extends CharacterBody2D
class_name BanditLeader

# Project T - Haydut Kampı Elebaşı (BanditLeader)
# Haydut kampında bekler. Oyuncu onunla savaşıp yenebilir veya kanıtı ele geçirip gizlice anlaşma yapabilir.

signal interacted(player: CharacterBody2D)

@export var leader_name: String = "Haydut Reisi Demirpençe"
@export var is_allied: bool = false
@export var current_health: int = 80
@export var max_health: int = 80

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("bandit_leader")
	collision_layer = 4 # NPC / Object
	collision_mask = 1 | 2 # Solid & Player
	
	var col = get_node_or_null("CollisionShape2D")
	if not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var box = RectangleShape2D.new()
		box.size = Vector2(18, 22)
		col.shape = box
		add_child(col)

	var area = get_node_or_null("InteractionArea")
	if not area:
		area = Area2D.new()
		area.name = "InteractionArea"
		area.collision_layer = 0
		area.collision_mask = 2 # Player
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 32.0
		shape.shape = circle
		area.add_child(shape)
		add_child(area)

	queue_redraw()

func get_action_prompt_text() -> String:
	return "Konuş (Pazarlık Et)"

func interact_with(player: CharacterBody2D) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	var qm = get_node_or_null("/root/QuestManager")
	if not dm or not qm:
		return

	var inv = player.get_inventory() if player and player.has_method("get_inventory") else null
	var q_valley = qm.get_quest("silence_of_the_valley")

	# Eğer görev tamamlanmışsa
	if q_valley and q_valley.is_completed():
		if qm.valley_quest_choice == "bandits":
			dm.start_dialogue(leader_name, "Dostum! Sözünü tuttun ve defteri köy muhafızlarına vermedin. Bozkırın yolları artık senin için güvenli. Bizimle ters düşmediğin sürece arkandayız.")
		else:
			dm.start_dialogue(leader_name, "Bizi muhafızlara sattın demek ha! Vadi sana dar gelecek yolcu!")
		return

	# Eğer oyuncuda kanıt (bandit_ledger) varsa: Anlaşma Teklifi
	if q_valley and q_valley.is_active() and inv and inv.has_item("bandit_ledger", 1):
		qm.resolve_valley_quest("bandits", inv)
		dm.start_dialogue(leader_name, "Vay canına... Kampımızın gizli baskın defterini ele geçirmişsin. Seni tebrik ederim yolcu. Ama bunu muhafızlara götürmek yerine bana teslim etmeyi akıl ettin. Al şu 250 bakır sikkeyi, bu sır aramızda kalsın. Artık bizim adamımızsın.")
		return

	# Normal durumda konuşma
	dm.start_dialogue(leader_name, "Buralarda dolaşmak yürek ister yabancı. Kampımıza izinsiz girenlerin sonu iyi bitmez... Ama akıllı biriysen konuşarak anlaşabiliriz.")

func _draw() -> void:
	# Taban gölgesi
	draw_circle(Vector2(0, 6), 9.0, Color(0, 0, 0, 0.4))

	# Reis gövdesi (Koyu siyah/kızıl zırhlı haydut lideri)
	draw_rect(Rect2(-7, -8, 14, 15), Color("1e293b"))
	draw_rect(Rect2(-5, -6, 10, 11), Color("831843")) # Bordo deri yelek

	# Baş ve maske
	draw_circle(Vector2(0, -13), 5.5, Color("d4a373"))
	draw_rect(Rect2(-5, -14, 10, 4), Color("991b1b")) # Kırmızı reis bandanası
	draw_circle(Vector2(-2, -13), 1.0, Color("0f172a")) # Göz
	draw_circle(Vector2(2, -13), 1.0, Color("0f172a"))

	# Çift kama (Sağ ve sol el)
	draw_line(Vector2(-8, -2), Vector2(-13, 3), Color("cbd5e1"), 2.0)
	draw_line(Vector2(8, -2), Vector2(13, 3), Color("cbd5e1"), 2.0)

	# Çizmeler
	draw_rect(Rect2(-6, 7, 4, 5), Color("0f172a"))
	draw_rect(Rect2(2, 7, 4, 5), Color("0f172a"))
