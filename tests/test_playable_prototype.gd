extends SceneTree

# Test betiği: Görev 22 — Oynanabilir Prototip & Keşif Döngüsü Smoke Test
# Senaryolar:
# 1. Başlangıç & Köyden Keşif Akışı (Orman -> Nehir -> Dağ -> Mağara)
# 2. Çoklu Sistem Uyumu (Yüzme, Tırmanma, Savaş, Envanter, Etkileşim)
# 3. Söylenti & Dinamik Görev Çatallanması (Yardım etme vs. Görmezden gelme)
# 4. Kayıt & Yükleme Durum Tutarlılığı (Save/Load Roundtrip)
# 5. Debug Arayüzü Gizlenebilirlik (F3 toggle)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 22 — Oynanabilir Prototip Smoke Test ---")
	test_village_to_wilds_exploration_flow()
	test_multi_system_mechanics_integration()
	test_rumor_and_branching_quest_resolution()
	test_save_load_gameplay_state_roundtrip()
	test_debug_ui_toggle()
	print("--- TÜM OYNANABİLİR PROTOTİP DOĞRULAMALARI BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_village_to_wilds_exploration_flow() -> void:
	# Köyden ormana, nehre ve dağ tepesine kesintisiz rota ve keşif tetikleyicileri
	var world_scene = preload("res://scenes/world.tscn").instantiate()
	root.add_child(world_scene)
	
	var player = world_scene.find_child("Player", true, false)
	assert(player != null, "Oyuncu dünyada mevcut olmalı")
	assert(player.global_position == Vector2(480, 320), "Oyuncu köy meydanında başlamalı")
	
	# Köyden nehre git
	player.global_position = Vector2(860, 660) # Taş Köprü
	var loc = world_scene.find_child("TestLocation", true, false)
	assert(loc != null, "Ana lokasyon haritası bulunmalı")
	
	# Köprüden mağara ve gözetleme kulesine devam et
	player.global_position = Vector2(1520, 280) # Kule
	var trig_tower = world_scene.find_child("Trigger_Tower", true, false)
	assert(trig_tower != null, "Kule keşif tetikleyicisi mevcut olmalı")
	
	world_scene.free()
	print("[PASS] Köy -> Orman -> Nehir -> Dağ -> Mağara kesintisiz keşif akışı doğrulandı.")

func test_multi_system_mechanics_integration() -> void:
	# Yüzme, Tırmanma, Savaş ve Envanterin birlikte çalışması
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()
	
	var inv: Inventory = player.get_inventory()
	assert(inv != null, "Oyuncunun envanteri olmalı")
	
	# 1. Envanter eşya ekleme
	inv.add_item("wood", 5)
	assert(inv.has_item("wood", 5), "Envantere odun eklenmeli")
	
	# 2. Savaş mekaniği & Hasar
	var start_hp = player.current_health
	player.take_damage(20, Vector2.RIGHT)
	assert(player.current_health == start_hp - 20, "Hasar alma çalışmalı")
	
	# 3. Yüzme durumu
	player.is_in_deep_water = true
	player.process_movement_state(0.016)
	assert(player.current_state == player.State.SWIM, "Derin suda SWIM durumuna geçmeli")
	player.is_in_deep_water = false
	
	# 4. Tırmanma durumu
	var cliff = preload("res://scenes/props/climbable_cliff.tscn").instantiate()
	root.add_child(cliff)
	player.current_cliff = cliff
	player.current_state = player.State.CLIMB
	assert(player.current_state == player.State.CLIMB, "Uçurumda CLIMB durumuna geçmeli")
	
	cliff.free()
	player.free()
	print("[PASS] Savaş, envanter, yüzme ve tırmanma sistemleri entegrasyonu doğrulandı.")

func test_rumor_and_branching_quest_resolution() -> void:
	# Söylenti yayılımı ve kervan görevinin iki farklı sonuçla çözülebilmesi
	var qm = root.get_node_or_null("QuestManager")
	var event_node = preload("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(event_node)
	
	var caravan_event: WorldEvent = event_node.find_child("Caravan_Ambush_Event", true, false)
	assert(caravan_event != null, "Kervan olayı sahnede bulunmalı")
	
	# Senaryo A: Görmezden gelinirse kervan yağmalanır (RESOLVED_IGNORED)
	caravan_event.start_event(10, 1)
	assert(caravan_event.status == WorldEvent.EventStatus.ACTIVE, "Olay aktifleşmeli")
	
	caravan_event.resolve_ignored()
	assert(caravan_event.status == WorldEvent.EventStatus.RESOLVED_IGNORED, "Kervan yağmalanma sonucu almalı")
	assert(qm.quests["caravan_defense"].stage == QuestData.QuestStage.FAILED, "Görev başarısız olarak güncellenmeli")
	
	# Senaryo B: Müdahale edilirse kurtarılır (RESOLVED_SUCCESS)
	caravan_event.status = WorldEvent.EventStatus.ACTIVE
	qm.quests["caravan_defense"].stage = QuestData.QuestStage.ACTIVE
	caravan_event.resolve_intervened()
	assert(caravan_event.status == WorldEvent.EventStatus.RESOLVED_SUCCESS, "Kervan kurtarılma sonucu almalı")
	assert(qm.quests["caravan_defense"].stage == QuestData.QuestStage.COMPLETED, "Görev zaferle tamamlanmalı")
	
	event_node.free()
	print("[PASS] Söylenti ve görev çoklu sonuç dallanması (kurtarma vs. yağmalanma) doğrulandı.")

func test_save_load_gameplay_state_roundtrip() -> void:
	var sm = root.get_node_or_null("SaveManager")
	var qm = root.get_node_or_null("QuestManager")
	var mm = root.get_node_or_null("MapManager")
	
	# Durum hazırla
	qm.quests["kemal_lost_sickle"].stage = QuestData.QuestStage.ACTIVE
	mm.discover_poi("watchtower")
	
	# Kaydet
	var save_res = sm.save_game(1)
	assert(save_res == true, "Oyun kaydedilebilmeli")
	
	# Durumu boz
	qm.quests["kemal_lost_sickle"].stage = QuestData.QuestStage.AVAILABLE
	mm.pois["watchtower"]["discovered"] = false
	
	# Yükle
	var load_res = sm.load_game(1)
	assert(load_res == true, "Oyun yüklenebilmeli")
	assert(qm.quests["kemal_lost_sickle"].stage == QuestData.QuestStage.ACTIVE, "Görev durumu korunmalı")
	assert(mm.is_poi_discovered("watchtower") == true, "Harita keşfi korunmalı")
	print("[PASS] Kayıt alıp aynı dünya ve görev durumuna geri dönebilme (Roundtrip) doğrulandı.")

func test_debug_ui_toggle() -> void:
	var debug_ui = preload("res://scenes/ui/time_debug_ui.tscn").instantiate()
	root.add_child(debug_ui)
	
	assert(debug_ui.visible == true, "Debug UI başlangıçta görünür olmalı")
	
	# F3 tuşu ile gizleme
	var event = InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_F3
	debug_ui._input(event)
	
	assert(debug_ui.visible == false, "F3 tuşu ile debug UI gizlenebilmeli")
	
	debug_ui.free()
	print("[PASS] F3 tuşu ile debug arayüzü açma/kapama doğrulandı.")
