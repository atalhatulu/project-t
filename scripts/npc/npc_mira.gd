extends BaseNPC
class_name InnkeeperMira

# Project T - Hancı Mira
#
# Program:
# 06:00 — Kızıl Han'da uyanır ve temizlik yapar (Kızıl Han: 380, 265)
# 09:00 — Handa tezgaha geçer, yemek ve içecek sunar (Kızıl Han: 380, 265)
# 17:00 — Köy meydanına çıkar, köylülerle sosyalleşir ve dedikoduları dinler (Meydan: 480, 320)
# 20:00 — Akşam yoğunluğu için Hana döner (Kızıl Han: 380, 265)
# 23:00 — Kızıl Han'ın arka odasında uyur (Kızıl Han: 380, 265)

const POS_INN = Vector2(380, 265)
const POS_SQUARE = Vector2(480, 320)

func _init() -> void:
	npc_id = "mira"
	npc_name = "Hancı Mira"
	npc_occupation = "Kızıl Han İşletmecisi"
	walk_speed = 42.0

	location_eat = POS_INN
	location_rest = POS_INN
	location_social = POS_SQUARE

	schedule = [
		{
			"hour": 6,
			"target_state": State.WORK,
			"target": POS_INN,
			"dialogue_first": "Günaydın! Masaları siliyorum, dün geceden kalan kargaşayı temizlemek zor iş.",
			"dialogue_repeat": "Erken kalkmışsın yolcu. Çorba kaynıyor, birazdan hazır olur."
		},
		{
			"hour": 9,
			"target_state": State.WORK,
			"target": POS_INN,
			"dialogue_first": "Hoş geldin! Ben Mira, Kızıl Han'ın sahibiyim. Bozkırın en iyi yahnisini burada bulursun.",
			"dialogue_repeat": "Boş bir masaya geçebilirsin dostum. Yol yorgunluğunu atmak için doğru yerdesin."
		},
		{
			"hour": 17,
			"target_state": State.SOCIALIZE,
			"target": POS_SQUARE,
			"dialogue_first": "Akşam serinliğinde meydana çıkıp havadisleri toplamak gibisi yok.",
			"dialogue_repeat": "Meydan pek hareketli bugün. Herkes bir şeyler fısıldaşıyor."
		},
		{
			"hour": 20,
			"target_state": State.WORK,
			"target": POS_INN,
			"dialogue_first": "Akşam kalabalığı başladı bile! Kadehler dolup taşıyor.",
			"dialogue_repeat": "Kusura bakma kalabalık çok, bir şey lazımsa tezgaha seslen!"
		},
		{
			"hour": 23,
			"target_state": State.SLEEP,
			"target": POS_INN,
			"dialogue_first": "Esneme... Han kapandı artık yolcu. Yarın görüşürüz...",
			"dialogue_repeat": "Zzz... Lambaları söndürdüm..."
		}
	]

func _ready() -> void:
	super._ready()
	# Görsel renklerini hancıya uygun yap (Bordo yelek, koyu saç)
	if visual_node:
		visual_node.shirt_color = Color("831843")
		visual_node.apron_color = Color("500724")
		visual_node.hair_color = Color("1e1b4b")

	# Başlangıçta Boran ve Kemal ile iyi ilişki
	if social:
		social.set_relationship("boran", 25.0)
		social.set_relationship("kemal", 30.0)

func get_current_dialogue() -> String:
	var has_met = memory.has_met_player() if memory else false
	if memory: memory.on_talked_with_player()

	# Eğer tezgâhtaysa veya çalışma saatindeyse dükkânı aç
	if current_state == State.WORK:
		var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		if player and player.has_method("open_shop_for"):
			player.open_shop_for("mira")
			return "Hoş geldin! Taze pişmiş han ekmeği, nefis yahni ve elmalarımız var. Ne arzu ederdin?"

	# 1. Vadinin Sessizliği Görev Sonucu Tepkisi
	var qm = get_node_or_null("/root/QuestManager") if is_inside_tree() else null
	if qm:
		var q_valley = qm.get_quest("silence_of_the_valley")
		if q_valley and q_valley.is_completed():
			if qm.valley_quest_choice == "guards":
				return "Duyduğuma göre kervanları vuran haydut çetesini açığa çıkarmışsın! Hanımıza tüccarlar yeniden uğramaya başladı, vadi sana minnettar."
			elif qm.valley_quest_choice == "bandits":
				return "Kervan yolu hala tekinsiz... Haydutların kimseyle göz göze gelmeden vadide at koşturduğu söyleniyor. Garip bir sessizlik var."

		# Söylenti evresi
		if q_valley and q_valley.is_available():
			qm.start_quest("silence_of_the_valley")
			return "Son günlerde hana gelen kervanlar kesildi yolcu. Doğu dağ yolundaki eski ticaret güzergahında kırılmış arabalar görülmüş. Bir şeyler dönüyor orada."

	# Eğer Kemal'in kayıp alet bilgisini öğrenmişse oyuncuya anlatsın!
	if memory and memory.has_info("kemal_lost_tool"):
		var info = memory.get_info("kemal_lost_tool")
		return "Biliyor musun? Çiftçi Kemal ile konuştum az önce. 'Kadim orak aletimi tarlanın güneyinde kaybettim' diye dert yanıyordu. Yazık adama, ekinler ortada kalacak."

	if current_schedule_entry.has("dialogue_first"):
		return current_schedule_entry["dialogue_repeat"] if has_met else current_schedule_entry["dialogue_first"]

	return "Selam sana yolcu."
