extends BaseNPC
class_name BlacksmithBoran

# Project T - Demirci Boran (Gelişmiş İhtiyaç, Hafıza ve Karar Yetenekleriyle)

const POS_HOUSE = Vector2(380, 445)
const POS_FORGE = Vector2(580, 275)
const POS_SQUARE = Vector2(480, 320)
const POS_INN = Vector2(380, 265)

func _init() -> void:
	npc_id = "boran"
	npc_name = "Demirci Boran"
	npc_occupation = "Demirci Ustası"
	walk_speed = 40.0

	# İhtiyaç noktaları
	location_eat = POS_INN      # Acıkınca Kızıl Han'a yemek yemeye gider
	location_rest = POS_HOUSE   # Yorulunca evine dinlenmeye gider
	location_social = POS_SQUARE

	schedule = [
		{
			"hour": 6,
			"target_state": State.IDLE,
			"target": POS_HOUSE,
			"dialogue_first": "Esneme... Gün yeni ağarıyor yolcu. Ocağı yakmadan önce biraz çay içiyorum.",
			"dialogue_repeat": "Yine mi sen dostum? Sabah serinliğinde buralar ne hoştur, değil mi?"
		},
		{
			"hour": 8,
			"target_state": State.WORK,
			"target": POS_FORGE,
			"dialogue_first": "Güm! Güm! Çelik tavında dövülür! Ben Boran, köyün demircisiyim. Kılıcını bileyeceksen biraz bekle.",
			"dialogue_repeat": "Örsün sesi kulaklarını sağır etmesin ha! Çiftlik tırpanlarını yetiştirmeye çalışıyorum."
		},
		{
			"hour": 12,
			"target_state": State.SOCIALIZE,
			"target": POS_SQUARE,
			"dialogue_first": "Öğle vakti köy meydanında temiz hava almak iyi geliyor. Dağ yolunda haydutlar görülmüş derler.",
			"dialogue_repeat": "Meydandaki kuyunun suyu pek serindir, bir yudum al istersen yolcu."
		},
		{
			"hour": 14,
			"target_state": State.WORK,
			"target": POS_FORGE,
			"dialogue_first": "Öğleden sonra zırh plakalarını perçinliyorum. Bozkırın çetelerine karşı sağlam kalkan şart.",
			"dialogue_repeat": "Hala çalışıyorum evlat! Sıcak kül sıçramasın, dikkat et."
		},
		{
			"hour": 19,
			"target_state": State.SOCIALIZE,
			"target": POS_INN,
			"dialogue_first": "Bütün günün yorgunluğu Kızıl Han'ın arpa suyuyla atılır! Otur da ozanın türküsünü dinle.",
			"dialogue_repeat": "Hancıya selam söyledin mi? Bu akşam güveç fena kokmuyor!"
		},
		{
			"hour": 22,
			"target_state": State.SLEEP,
			"target": POS_HOUSE,
			"dialogue_first": "Zzz... Ocak söndü, gözlerim kapanıyor... Yarın sabah gel...",
			"dialogue_repeat": "Zzz... Uyku vakti geldi dostum... Kapıyı kapatıver..."
		}
	]

func get_current_dialogue() -> String:
	# Açlık veya yorgunluk durumuna göre özel diyalog
	if current_state == State.EAT:
		if memory: memory.on_talked_with_player()
		return "Karnım zil çalıyordu! Hanın sıcacık çorbasını kaşıklıyorum, sonra konuşalım."
	elif current_state == State.REST:
		if memory: memory.on_talked_with_player()
		return "Bacaklarım tutmuyor, azıcık soluklanayım da ocağa öyle döneyim."

	var has_met = memory.has_met_player() if memory else false

	# Hafızayı güncelle
	if memory:
		memory.on_talked_with_player()

	if current_schedule_entry.has("dialogue_first"):
		if not has_met:
			return current_schedule_entry["dialogue_first"]
		else:
			return current_schedule_entry["dialogue_repeat"]

	return "Selam sana dostum."
