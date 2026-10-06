extends BaseNPC
class_name FarmerKemal

# Project T - Çiftçi Kemal
#
# Program:
# 05:00 — Köy Evinde uyanır (Köy Evi: 380, 445)
# 07:00 — Güneydoğu tarlasına gider ve ekin biçer (Tarla/Gölet kıyısı: 680, 420)
# 14:00 — Köye gelir, Köy Meydanı'nda dinlenir ve sohbet eder (Meydan: 480, 320)
# 18:00 — Kızıl Han'a gider, akşam yemeği yer (Kızıl Han: 380, 265)
# 21:00 — Köy Evine döner ve uyur (Köy Evi: 380, 445)

const POS_HOUSE = Vector2(380, 445)
const POS_FIELD = Vector2(680, 420)
const POS_SQUARE = Vector2(480, 320)
const POS_INN = Vector2(380, 265)

func _init() -> void:
	npc_id = "kemal"
	npc_name = "Çiftçi Kemal"
	npc_occupation = "Emektar Çiftçi"
	walk_speed = 38.0

	location_eat = POS_INN
	location_rest = POS_HOUSE
	location_social = POS_SQUARE

	schedule = [
		{
			"hour": 5,
			"target_state": State.IDLE,
			"target": POS_HOUSE,
			"dialogue_first": "Güneş doğmadan uyanmak çiftçinin kaderidir. Tarlaya çıkma vakti yaklaşıyor.",
			"dialogue_repeat": "Sabah bereketi başkadır evlat. Horozlar ötmeden ayaktayız."
		},
		{
			"hour": 7,
			"target_state": State.WORK,
			"target": POS_FIELD,
			"dialogue_first": "Ah kafam ah! Dedemden kalma orak aletimi buralarda bir yerde düşürdüm... Bulamıyorum bir türlü!",
			"dialogue_repeat": "Tarlanın taşlarını temizliyorum ama aklım hala o kayıp orakta."
		},
		{
			"hour": 14,
			"target_state": State.SOCIALIZE,
			"target": POS_SQUARE,
			"dialogue_first": "Öğle sıcağında toprak kavruluyor. Meydandaki ağaçların gölgesi ilaç gibi geldi.",
			"dialogue_repeat": "Boran ustaya uğrayıp yeni bir orak sorsam mı acaba? Eskisinin yerini tutmaz ya..."
		},
		{
			"hour": 18,
			"target_state": State.SOCIALIZE,
			"target": POS_INN,
			"dialogue_first": "Toprağın tozu boğazıma yapıştı. Mira'nın sıcacık çorbası içimi ısıtır şimdi.",
			"dialogue_repeat": "Hanın neşesi yerinde bu akşam. Bereketli bir hasat dileyelim."
		},
		{
			"hour": 21,
			"target_state": State.SLEEP,
			"target": POS_HOUSE,
			"dialogue_first": "Gözlerim kapanıyor... Yarın şafakla yine tarladayız...",
			"dialogue_repeat": "Zzz... Toprak kokusu..."
		}
	]

func _ready() -> void:
	super._ready()
	# Görsel renklerini çiftçiye uygun yap (Yeşil/toprak tonları, hasır şapka rengi)
	if visual_node:
		visual_node.shirt_color = Color("2e5a27")
		visual_node.apron_color = Color("5c442c")
		visual_node.hair_color = Color("854d0e")

	# Başlangıçta Mira ve Boran ile iyi ilişki
	if social:
		social.set_relationship("mira", 35.0)
		social.set_relationship("boran", 20.0)

	# Kemal başlangıçta hafızasında kayıp alet olayını bilir (ve diğer NPC'lere yayabilir)
	if memory:
		memory.learn_info("kemal_lost_tool", npc_id, "Kadim orak aletimi tarlanın güneyinde kaybettim.")

func get_current_dialogue() -> String:
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if not qm and get_parent() != null:
		qm = get_parent().get_node_or_null("QuestManager")
	var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	if not player and get_parent() != null:
		player = get_parent().get_node_or_null("Player")
	var inv: Inventory = player.get_inventory() if player and player.has_method("get_inventory") else null

	# 1. Vadinin Sessizliği Görev Tepkisi
	if qm:
		var q_valley = qm.get_quest("silence_of_the_valley")
		if q_valley:
			if q_valley.is_completed():
				if qm.valley_quest_choice == "guards":
					return "Muhafızlar dağdaki haydut inini basmış diyorlar. Artık ekinlerimizi şehre götürürken korkmayacağız, ellerin dert görmesin!"
				elif qm.valley_quest_choice == "bandits":
					return "Tüccarlar artık vadimizden geçmeye korkuyor. Topladığımız buğday depolarda çürüyecek diye ödüm kopuyor..."
			elif q_valley.is_available():
				qm.start_quest("silence_of_the_valley")
				return "Tarlada çalışırken doğu dağlarından tekerlek gıcırtıları ve haykırışlar duydum evlat. Kervanlar birer birer kayboluyor, yolun kenarında araba enkazları kalmış."

	# 2. Kemal'in Orağı Görevi
	if qm:
		var q = qm.get_quest("kemal_lost_sickle")
		if q:
			if q.stage == QuestData.QuestStage.ACTIVE and inv and inv.has_item("kemal_sickle", 1):
				qm.complete_quest("kemal_lost_sickle", inv)
				if memory:
					memory.record_event("player_helped_kemal", {"item": "kemal_sickle"})
				return q.completion_dialogue
			elif q.stage == QuestData.QuestStage.COMPLETED:
				return "Yadigâr orağım elimde ya, ekinler artık boynumu bükemez! Sağ olasın yiğit yolcu."
			elif q.stage == QuestData.QuestStage.AVAILABLE:
				# İlk kez konuşulduğunda görevi aktif yap
				qm.start_quest("kemal_lost_sickle")
				if memory:
					memory.record_event("asked_for_sickle", {})
				return "Ah evlat, sorma başıma geleni! Dedemden kalma kadim çelik orağı tarlanın güneyinde, gölet yakınındaki çalılarda düşürdüm. Gözlerim pek seçmiyor, bulup getirirsen duacın olurum!"

	var has_met = memory.has_met_player() if memory else false
	if memory: memory.on_talked_with_player()

	if current_schedule_entry.has("dialogue_first"):
		return current_schedule_entry["dialogue_repeat"] if has_met else current_schedule_entry["dialogue_first"]

	return "Kolay gelsin yolcu."
