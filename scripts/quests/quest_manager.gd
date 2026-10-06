@tool
extends Node

# Project T - Dinamik Görev ve Olay Yöneticisi (QuestManager)
# Autoload Singleton: QuestManager
# Görevlerin yaşam döngüsü, oyuncu günlüğü, diyalog & dünya tetikleyicileri

signal quest_added(quest_id: String)
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal journal_updated

var quests: Dictionary = {} # quest_id -> QuestData
var general_journal_notes: Array[String] = []

func _ready() -> void:
	_init_default_quests()

func _init_default_quests() -> void:
	# 1. Görev: Çiftçi Kemal'in Kayıp Orağı
	var q_kemal = QuestData.new()
	q_kemal.quest_id = "kemal_lost_sickle"
	q_kemal.title = "Kemal'in Yadigâr Orağı"
	q_kemal.description = "Çiftçi Kemal, dedesinden kalma kıymetli orağını güneybatı çayırlarında veya gölet sazlıklarında çalışırken düşürdüğünü söylüyor."
	q_kemal.rumor_source = "Çiftçi Kemal & Köy Meydanı Sohbetleri"
	q_kemal.objective_text = "Tarlanın güneyindeki sazlık ve çalıları araştırarak orağı bul ve Kemal'e teslim et."
	q_kemal.stage = QuestData.QuestStage.AVAILABLE
	q_kemal.condition_type = QuestData.ConditionType.ITEM_COLLECT
	q_kemal.target_id = "kemal_sickle"
	q_kemal.target_count = 1
	var r1: Array[Dictionary] = [
		{"item_id": "cooper_coins", "amount": 25},
		{"item_id": "inn_bread", "amount": 2}
	]
	q_kemal.reward_items = r1
	q_kemal.completion_dialogue = "Gözlerime inanamıyorum! Dedemin yadigârı! Çok yaşa evlat, al şu taze ekmekleri ve harçlığı hakkettin."
	var l1: Array[String] = [
		"Kemal ile konuştum. Orağını tarlanın güneyinde, uzun otların arasında kaybettiğinden şüpheleniyor."
	]
	q_kemal.log_entries = l1
	register_quest(q_kemal)

	# 2. Görev / Olay: Kervan Savunması (Dinamik Dünya Olayı)
	var q_caravan = QuestData.new()
	q_caravan.quest_id = "caravan_defense"
	q_caravan.title = "Kervan Pusuya Düştü"
	q_caravan.description = "Bozkırın kuzeydoğu dağ patikasında gezgin bir tüccar kervanı haydutlar tarafından kuşatılmış. Yardım edilmezse kervan yağmalanacak."
	q_caravan.rumor_source = "Demirci Boran & Han Dedikoduları"
	q_caravan.objective_text = "Dağ yolundaki kervan noktasına git ve haydutları püskürt."
	q_caravan.stage = QuestData.QuestStage.AVAILABLE
	q_caravan.condition_type = QuestData.ConditionType.EVENT_TRIGGER
	q_caravan.target_id = "caravan_ambush"
	q_caravan.target_count = 1
	var r2: Array[Dictionary] = [
		{"item_id": "cooper_coins", "amount": 50},
		{"item_id": "iron_ore", "amount": 3}
	]
	q_caravan.reward_items = r2
	q_caravan.completion_dialogue = "Tüccarlar sana minnettar! Haydutlar kaçtı ve yol güvende."
	var l2: Array[String] = [
		"Köyde dağ patikasından gelen yardım çığlıkları duyulduğu fısıldanıyor."
	]
	q_caravan.log_entries = l2
	register_quest(q_caravan)

	# 3. Ana Görev Zinciri: Vadinin Sessizliği (Silence of the Valley)
	var q_valley = QuestData.new()
	q_valley.quest_id = "silence_of_the_valley"
	q_valley.title = "Vadinin Sessizliği"
	q_valley.description = "Vadide son günlerde ticaret kervanları tek tek kayboluyor. Köylüler tedirgin, muhafızlar ise dağ yoluna yaklaşmaya çekiniyor."
	q_valley.rumor_source = "Hancı Mira, Çiftçi Kemal veya Kervan Yolu İpuçları"
	q_valley.objective_text = "Eski kervan yolundaki araba enkazını ve haydut kampını araştırarak delil topla."
	q_valley.stage = QuestData.QuestStage.AVAILABLE
	q_valley.condition_type = QuestData.ConditionType.ITEM_COLLECT
	q_valley.target_id = "bandit_ledger"
	q_valley.target_count = 1
	var r3: Array[Dictionary] = [
		{"item_id": "cooper_coins", "amount": 120},
		{"item_id": "ancient_medallion", "amount": 1}
	]
	q_valley.reward_items = r3
	q_valley.completion_dialogue = "Vadinin Sessizliği gizemi çözüldü."
	var l3: Array[String] = [
		"Köyde kervanların sırra kadem bastığı konuşuluyor."
	]
	q_valley.log_entries = l3
	register_quest(q_valley)

# Vadinin Sessizliği Çatallanma Kararı (Choice A: Muhafızlara teslim et, Choice B: Haydutlarla anlaş)
var valley_quest_choice: String = "" # "guards" veya "bandits"

func resolve_valley_quest(choice: String, player_inventory: Inventory = null) -> bool:
	if not quests.has("silence_of_the_valley"):
		return false
	var q: QuestData = quests["silence_of_the_valley"]
	if q.stage != QuestData.QuestStage.ACTIVE:
		return false

	valley_quest_choice = choice
	var fm = get_node_or_null("/root/FactionManager") if is_inside_tree() else null

	if choice == "guards":
		# A) Kanıtı Muhafızlara teslim et
		if player_inventory:
			player_inventory.remove_item("bandit_ledger", 1)
			player_inventory.add_item("cooper_coins", 150)
		if fm:
			fm.modify_reputation("guards", 35)
			fm.modify_reputation("villagers", 25)
			fm.modify_reputation("bandits", -30)
		q.log_entries.append("Kanıtları Muhafız Selim'e teslim ettin. Köy muhafızları haydut kampını dağıttı ve kervan yolu emniyete alındı.")
	elif choice == "bandits":
		# B) Haydutlarla anlaşarak olayı gizle
		if player_inventory:
			player_inventory.remove_item("bandit_ledger", 1)
			player_inventory.add_item("cooper_coins", 250)
		if fm:
			fm.modify_reputation("bandits", 40)
			fm.modify_reputation("guards", -20)
			fm.modify_reputation("villagers", -15)
		q.log_entries.append("Haydutlarla gizli bir anlaşma yaptın. Defteri onlara bırakıp sessiz kaldın; haydutlar seni müttefik saydı.")
	else:
		return false

	q.stage = QuestData.QuestStage.COMPLETED
	quest_completed.emit("silence_of_the_valley")
	quest_updated.emit("silence_of_the_valley")
	journal_updated.emit()
	return true

func register_quest(q: QuestData) -> void:
	quests[q.quest_id] = q
	quest_added.emit(q.quest_id)

func start_quest(quest_id: String) -> bool:
	if not quests.has(quest_id): return false
	var q: QuestData = quests[quest_id]
	if q.stage == QuestData.QuestStage.AVAILABLE:
		q.stage = QuestData.QuestStage.ACTIVE
		quest_started.emit(quest_id)
		quest_updated.emit(quest_id)
		journal_updated.emit()
		return true
	return false

func complete_quest(quest_id: String, player_inventory: Inventory = null) -> bool:
	if not quests.has(quest_id): return false
	var q: QuestData = quests[quest_id]
	if q.stage != QuestData.QuestStage.ACTIVE: return false

	# Görev eşyasını envanterden al (varsa)
	if player_inventory and q.condition_type == QuestData.ConditionType.ITEM_COLLECT:
		player_inventory.remove_item(q.target_id, q.target_count)

	# Ödülleri ver
	if player_inventory and not q.reward_items.is_empty():
		for rew in q.reward_items:
			player_inventory.add_item(rew.get("item_id", ""), rew.get("amount", 1))

	q.stage = QuestData.QuestStage.COMPLETED
	q.log_entries.append("Görev başarıyla tamamlandı.")
	quest_completed.emit(quest_id)
	quest_updated.emit(quest_id)
	journal_updated.emit()

	if is_inside_tree():
		var fm = get_node_or_null("/root/FactionManager")
		if fm:
			fm.on_quest_completed(quest_id)

	return true

func fail_quest(quest_id: String) -> bool:
	if not quests.has(quest_id): return false
	var q: QuestData = quests[quest_id]
	if q.stage == QuestData.QuestStage.COMPLETED: return false

	q.stage = QuestData.QuestStage.FAILED
	q.log_entries.append("Bu fırsat kaçırıldı veya görev başarısız oldu.")
	quest_failed.emit(quest_id)
	quest_updated.emit(quest_id)
	journal_updated.emit()
	return true

func advance_quest_condition(cond_type: QuestData.ConditionType, target_id: String, amount: int = 1) -> void:
	for q_id in quests:
		var q: QuestData = quests[q_id]
		# Eğer AVAILABLE ise ve oyuncu hedefi doğrudan bulduysa görevi ACTIVE yapıp ilerlet
		if q.stage == QuestData.QuestStage.AVAILABLE and q.condition_type == cond_type and q.target_id == target_id:
			start_quest(q_id)

		if q.stage == QuestData.QuestStage.ACTIVE and q.condition_type == cond_type and q.target_id == target_id:
			var done = q.update_progress(amount)
			quest_updated.emit(q_id)
			journal_updated.emit()
			if done and cond_type == QuestData.ConditionType.EVENT_TRIGGER:
				complete_quest(q_id, null)

func add_journal_note(note: String) -> void:
	general_journal_notes.append(note)
	journal_updated.emit()

func get_active_quests() -> Array[QuestData]:
	var list: Array[QuestData] = []
	for q in quests.values():
		if q.is_active():
			list.append(q)
	return list

func get_all_quests() -> Array[QuestData]:
	var list: Array[QuestData] = []
	for q in quests.values():
		list.append(q)
	return list

func get_quest(quest_id: String) -> QuestData:
	return quests.get(quest_id, null)
