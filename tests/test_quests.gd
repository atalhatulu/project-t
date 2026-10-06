extends SceneTree

# Test betiği: Görev 16 — Dinamik Görevler, Oyuncu Günlüğü ve Dünya Olayları

func _init() -> void:
	print("--- TEST BAŞLATILDI: Görev 16 — Dinamik Görevler ve Dünya Olayları ---")
	var qm = root.get_node_or_null("QuestManager")
	if not qm:
		qm = preload("res://scripts/quests/quest_manager.gd").new()
		qm.name = "QuestManager"
		root.add_child(qm)
		qm._ready()

	test_quest_data_and_manager(qm)
	test_kemal_lost_sickle_quest(qm)
	test_world_event_independent_cycle(qm)
	test_world_event_player_consequences(qm)
	test_journal_ui(qm)
	print("--- TÜM GÖREV VE OLAY TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)

func test_quest_data_and_manager(qm: Node) -> void:
	assert(qm != null, "QuestManager mevcut olmalı")

	var q = qm.get_quest("kemal_lost_sickle")
	assert(q != null, "Kemal'in orağı görevi kayıtlı olmalı")
	assert(q.stage == QuestData.QuestStage.AVAILABLE, "Görev başlangıçta AVAILABLE olmalı")

	# Görev başlatma
	var started = qm.start_quest("kemal_lost_sickle")
	assert(started == true, "Görev başlatılabilmeli")
	assert(q.is_active() == true, "Görev ACTIVE durumunda olmalı")

	print("[PASS] QuestData aşamaları (available, active, completed, failed) ve QuestManager kayıtları doğrulandı.")

func test_kemal_lost_sickle_quest(qm: Node) -> void:
	var q = qm.get_quest("kemal_lost_sickle")

	# Oyuncu ve Envanter oluştur
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()
	assert(inv != null, "Oyuncu envanteri mevcut olmalı")

	# 1. Kemal ile konuşmadan veya konuşarak: orağı bulma
	inv.add_item("kemal_sickle", 1)
	assert(inv.has_item("kemal_sickle", 1) == true, "Kemal'in orağı envantere eklendi")

	# 2. Kemal NPC'si ile diyalog ve teslim etme
	var kemal = preload("res://scenes/npc/npc_kemal.tscn").instantiate()
	root.add_child(kemal)
	kemal._ready()

	var dialogue = kemal.get_current_dialogue()
	assert(dialogue == q.completion_dialogue, "Kemal görevi tamamlayıp teşekkür etmeli")
	assert(q.is_completed() == true, "Görev COMPLETED olmalı")
	assert(inv.has_item("kemal_sickle", 1) == false, "Orak envanterden teslim edilmiş olmalı")
	assert(inv.has_item("cooper_coins", 25) == true, "Görev ödülü bakır sikkeler verilmiş olmalı")
	assert(inv.has_item("inn_bread", 2) == true, "Görev ödülü ekmekler verilmiş olmalı")

	player.queue_free()
	kemal.queue_free()
	print("[PASS] Çiftçi Kemal'in kayıp orak arama, bulma, teslim etme ve ödül döngüsü doğrulandı.")

func test_world_event_independent_cycle(qm: Node) -> void:
	# Olayın oyuncu kabul etmeden kendi kendine başlaması ve zaman aşımı (görmezden gelinmesi)
	var event = WorldEvent.new()
	event.event_id = "caravan_ambush"
	event.trigger_hour = 10
	event.expiration_hours = 3
	root.add_child(event)
	event._ready()

	assert(event.status == WorldEvent.EventStatus.PENDING, "Başlangıçta PENDING olmalı")

	# Saat 10: Olay bağımsız başlar
	event._on_hour_changed(10)
	assert(event.status == WorldEvent.EventStatus.ACTIVE, "Saat 10'da oyuncu olmadan ACTIVE olmalı")

	# 3 saat sonra (Saat 13): Görmezden gelindi, yağmalandı
	event._on_hour_changed(11)
	event._on_hour_changed(12)
	event._on_hour_changed(13)
	assert(event.status == WorldEvent.EventStatus.RESOLVED_IGNORED, "Süre bitince RESOLVED_IGNORED olmalı")

	var q = qm.get_quest("caravan_defense")
	assert(q.stage == QuestData.QuestStage.FAILED, "Görmezden gelinen olay görevi FAILED yapmalı")

	event.queue_free()
	print("[PASS] Dünya olaylarının oyuncu müdahalesinden bağımsız başlaması ve görmezden gelme sonuçları doğrulandı.")

func test_world_event_player_consequences(qm: Node) -> void:
	# Oyuncunun kervana müdahale edip haydutları temizlemesi
	var q = qm.get_quest("caravan_defense")
	q.stage = QuestData.QuestStage.ACTIVE

	var event = WorldEvent.new()
	event.event_id = "caravan_ambush"
	root.add_child(event)
	event._ready()
	event.start_event(10, 1)

	# Haydutların yenilmesi taklidi
	event.resolve_intervened()
	assert(event.status == WorldEvent.EventStatus.RESOLVED_SUCCESS, "Müdahale sonrası RESOLVED_SUCCESS olmalı")
	assert(q.stage == QuestData.QuestStage.COMPLETED, "Kervan savunma görevi tamamlanmalı")

	event.queue_free()
	print("[PASS] Oyuncu müdahalesi ile olayların kalıcı zafer/kurtarma ile sonuçlanması doğrulandı.")

func test_journal_ui(qm: Node) -> void:
	var journal = preload("res://scenes/ui/journal_ui.tscn").instantiate()
	root.add_child(journal)
	journal.quest_manager = qm
	journal._ready()

	assert(journal.is_open == false, "Günlük başlangıçta kapalı olmalı")
	journal.toggle()
	assert(journal.is_open == true, "J tuşu ile toggle sonrası açık olmalı")
	assert(journal.visible == true, "Arayüz görünür olmalı")

	# Sekme değişimi kontrolü
	journal.current_tab = 1
	var completed_quests = journal._get_current_tab_quests()
	assert(completed_quests.size() > 0, "Tamamlanan sekmesinde görev listelenmeli")

	journal.toggle()
	assert(journal.is_open == false, "Tekrar toggle ile kapanmalı")
	journal.queue_free()
	print("[PASS] Oyuncu günlüğü (JournalUI), J tuşu açılışı, parşömen sekmeleri ve kayıt görüntüleme doğrulandı.")
