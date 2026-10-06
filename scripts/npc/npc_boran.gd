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
	if memory:
		memory.on_talked_with_player()

	# İtibara göre tepkiler
	if is_inside_tree():
		var fm = get_node_or_null("/root/FactionManager")
		if fm:
			var rel = fm.get_relation_level("villagers")
			if rel == FactionManager.RelationLevel.HOSTILE:
				return "Defol ocağımdan! Köyde yaptıklarını duyduk, sana tek bir çivi dahi satmam!"
			elif rel == FactionManager.RelationLevel.SUSPICIOUS:
				return "Gözüm üzerinde yolcu... Çekiç elimde tetikte bekliyorum, uslu dur."

	# 1. Vadinin Sessizliği Görev Sonucu Tepkisi (En yüksek öncelik)
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		var q_valley = qm.get_quest("silence_of_the_valley")
		if q_valley:
			if q_valley.is_completed():
				if qm.valley_quest_choice == "guards":
					return "Muhafızlar haydutların inini basıp silahlarını müsadere etmiş! Getirdikleri kırık kılıçları ocağımda eritiyorum, köye huzur getirdin."
				elif qm.valley_quest_choice == "bandits":
					return "Demir cevheri sevkiyatı kesildi... Dağ yolundaki haydutlar iyice palazlandı diyorlar. Garip şeyler dönüyor vadide."
			elif q_valley.is_available():
				qm.start_quest("silence_of_the_valley")
				return "Kervan yolu günlerdir sessiz. Ne cevher geliyor ne çelik... Dağ yolunun aşağısında kırık bir araba enkazı görmüş avcılar."

	# Eğer ocaktaysa veya çalışma saatindeyse dükkânı aç
	if current_state == State.WORK:
		var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		if player and player.has_method("open_shop_for"):
			player.open_shop_for("boran")
			return "Ocağın ateşi harlıdır! Kılıç, balta, odun ve işlenmemiş demir cevheri bulunur. Ne lazım?"

		var q_caravan = qm.get_quest("caravan_defense")
		if q_caravan:
			if q_caravan.stage == QuestData.QuestStage.COMPLETED:
				return "Kervanı kurtardığını duydum! Dağ yolu yeniden nefes aldı, bileğine kuvvet yolcu."
			elif q_caravan.stage == QuestData.QuestStage.FAILED:
				return "Yazık oldu kervana... Haydutlar ortalığı darmadağın etmiş, ticaret yolumuz kesildi."
			elif q_caravan.stage == QuestData.QuestStage.ACTIVE:
				return "Kuzeydoğu patikasından feryatlar yükseliyor! Haydutlar kervana pusu kurmuş olmalı, acele etsen iyi olur!"

	if current_schedule_entry.has("dialogue_first"):
		if not has_met:
			return current_schedule_entry["dialogue_first"]
		else:
			return current_schedule_entry["dialogue_repeat"]

	return "Selam sana dostum."
