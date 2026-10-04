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
	var has_met = memory.has_met_player() if memory else false
	if memory: memory.on_talked_with_player()

	if current_schedule_entry.has("dialogue_first"):
		return current_schedule_entry["dialogue_repeat"] if has_met else current_schedule_entry["dialogue_first"]

	return "Kolay gelsin yolcu."
