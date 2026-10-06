extends SceneTree

# Test betiği: Görev 21 — Bölgesel Yükleme ve Akış Sistemi (RegionManager, Streaming, Uzak NPC Simülasyonu, SaveManager)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 21 — Bölgesel Yükleme ve Akış Sistemi ---")
	test_region_manager_registration()
	test_dynamic_region_load_and_unload()
	test_camera_and_player_continuity()
	test_unloaded_npc_lightweight_simulation()
	test_interactable_persistence_across_unloads()
	test_save_manager_regional_integration()
	print("--- TÜM BÖLGESEL YÜKLEME TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_region_manager_registration() -> void:
	var rm = root.get_node_or_null("RegionManager")
	assert(rm != null, "RegionManager singleton yüklü olmalı")
	assert(rm.registered_regions.has("region_01_greenwood"), "Kızıl Vadi kayıtlı olmalı")
	assert(rm.registered_regions.has("region_02_mountain_valley"), "Dağ Eteği Vadisi kayıtlı olmalı")
	
	# Konum üzerinden bölge kimliği tespiti
	var pos_village = Vector2(500, 300)
	assert(rm.get_region_id_at_position(pos_village) == "region_01_greenwood", "Köy konumu bölge 1 olmalı")
	
	var pos_mountain = Vector2(2400, 600)
	assert(rm.get_region_id_at_position(pos_mountain) == "region_02_mountain_valley", "Dağ konumu bölge 2 olmalı")
	print("[PASS] Bölge kayıtları ve koordinat sınır tespiti doğrulandı.")

func test_dynamic_region_load_and_unload() -> void:
	var rm = root.get_node_or_null("RegionManager")
	
	# Dağ vadisi bölgesini dinamik olarak yükle
	var mountain_node = rm.load_region("region_02_mountain_valley")
	assert(mountain_node != null, "Dağ vadisi bölgesi başarıyla örneklenmeli")
	assert(rm.loaded_regions.has("region_02_mountain_valley"), "loaded_regions içinde yer almalı")
	assert(mountain_node.position == Vector2(1920, 0), "Bölge konumu ofsetli yerleşmeli")
	
	# Bölgeyi boşalt (unload)
	rm.unload_region("region_02_mountain_valley")
	assert(not rm.loaded_regions.has("region_02_mountain_valley"), "Boşaltılan bölge listeden çıkmalı")
	print("[PASS] Dinamik bölge yükleme ve sahneden boşaltma (load/unload) doğrulandı.")

func test_camera_and_player_continuity() -> void:
	# Oyuncu ve kamera sürekliliği: Oyuncunun pozisyonu bölge geçişlerinde korunmalı
	var rm = root.get_node_or_null("RegionManager")
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(400, 300)
	
	assert(player.get_node_or_null("Camera2D") != null, "Oyuncuda Camera2D olmalı")
	
	# Oyuncuyu sınır çizgisine ve ikinci bölgeye taşı
	player.global_position = Vector2(2100, 500)
	rm.update_regional_streaming()
	
	assert(rm.active_region_id == "region_02_mountain_valley", "Aktif bölge oyuncunun konumuna göre güncellenmeli")
	assert(player.global_position == Vector2(2100, 500), "Kamera ve oyuncu konumu sıçramadan korunmalı")
	
	player.free()
	print("[PASS] Bölge geçişlerinde kamera ve oyuncu hareket sürekliliği doğrulandı.")

func test_unloaded_npc_lightweight_simulation() -> void:
	var rm = root.get_node_or_null("RegionManager")
	var tm = root.get_node_or_null("TimeManager")
	
	# Simülasyon için boşaltılmış NPC ekle
	rm.unloaded_npcs_cache["hunter_tark"] = {
		"region_id": "region_02_mountain_valley",
		"position": Vector2(2300, 700),
		"state": 2, # WORK
		"hunger": 20.0,
		"energy": 80.0
	}
	
	# Gece saatine geçiş simülasyonu (saat 23:00)
	rm._on_time_hour_changed(23)
	
	var sim_npc = rm.unloaded_npcs_cache["hunter_tark"]
	assert(sim_npc["state"] == 4, "Gece saatinde uzak NPC durumu SLEEP olmalı")
	assert(sim_npc["energy"] > 80.0, "Uykuda enerjisi yenilenmeli")
	
	# Gündüz saatine geçiş simülasyonu (saat 10:00)
	rm._on_time_hour_changed(10)
	assert(sim_npc["state"] == 2, "Gündüz saatinde uzak NPC durumu WORK olmalı")
	
	rm.unloaded_npcs_cache.erase("hunter_tark")
	print("[PASS] Uzak NPC'lerin fizik yerine hafif zaman ve ihtiyaç simülasyonuyla güncellenmesi doğrulandı.")

func test_interactable_persistence_across_unloads() -> void:
	var rm = root.get_node_or_null("RegionManager")
	
	# Dağ bölgesini yükle
	var mtn_region = rm.load_region("region_02_mountain_valley")
	assert(mtn_region != null)
	
	# Bölgedeki bir sandığı aç
	var chest = mtn_region.find_child("Chest_Hunter", true, false)
	assert(chest != null, "Avcı sandığı sahnede bulunmalı")
	assert(chest.is_open == false, "Başlangıçta kapalı olmalı")
	chest.is_open = true
	chest.current_state = "opened"
	
	# Bölgeyi boşalt (unload)
	rm.unload_region("region_02_mountain_valley")
	
	# Önbellekte durum saklanmış olmalı
	assert(rm.unloaded_interactables_cache.has("region_02_mountain_valley"), "Bölge önbelleği açılmalı")
	var c_cache = rm.unloaded_interactables_cache["region_02_mountain_valley"]
	assert(c_cache.has("chest_hunter_supplies"), "Sandık durumu önbelleğe alınmalı")
	assert(c_cache["chest_hunter_supplies"]["state"] == "opened", "Sandık açık olarak saklanmalı")
	
	# Bölgeyi yeniden yükle (reload)
	var reloaded_region = rm.load_region("region_02_mountain_valley")
	var reloaded_chest = reloaded_region.find_child("Chest_Hunter", true, false)
	assert(reloaded_chest.is_open == true, "Yeniden yüklenen sandık açık durumu korumalı")
	
	rm.unload_region("region_02_mountain_valley")
	print("[PASS] Bölge boşaltılıp geri yüklendiğinde çevresel nesnelerin durum tutarlılığı doğrulandı.")

func test_save_manager_regional_integration() -> void:
	var sm = root.get_node_or_null("SaveManager")
	var rm = root.get_node_or_null("RegionManager")
	
	# Önbelleğe özel durum ekle
	rm.unloaded_interactables_cache["region_02_mountain_valley"] = {
		"test_sign": { "is_inspected": true }
	}
	rm.active_region_id = "region_02_mountain_valley"
	
	# Kaydet
	var save_res = sm.save_game(1)
	assert(save_res == true, "Kayıt başarılı olmalı")
	
	# Temizle
	rm.unloaded_interactables_cache.clear()
	rm.active_region_id = "region_01_greenwood"
	
	# Yükle
	var load_res = sm.load_game(1)
	assert(load_res == true, "Yükleme başarılı olmalı")
	assert(rm.active_region_id == "region_02_mountain_valley", "Aktif bölge geri yüklenmeli")
	assert(rm.unloaded_interactables_cache.has("region_02_mountain_valley"), "Bölgesel nesne önbelleği geri yüklenmeli")
	print("[PASS] RegionManager verilerinin SaveManager ile entegre kayıt/yükleme döngüsü doğrulandı.")
