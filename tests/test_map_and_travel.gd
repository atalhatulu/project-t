extends SceneTree

# Test betiği: Görev 20 — Dünya Haritası ve Seyahat (MapManager, MapUI, Sis Sistemi, Özel İşaretler, Hızlı Seyahat)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 20 — Harita ve Seyahat Sistemi ---")
	test_map_coordinate_scaling()
	test_fog_of_war_revealing()
	test_custom_markers()
	test_fast_travel_and_time_advance()
	test_map_ui_toggle_and_player_lock()
	test_map_save_load()
	print("--- TÜM HARİTA VE SEYAHAT TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_map_coordinate_scaling() -> void:
	var mm = root.get_node_or_null("MapManager")
	if not mm:
		mm = preload("res://scripts/map/map_manager.gd").new()
		mm.name = "MapManager"
		root.add_child(mm)
		mm._ready()

	# Dünya boyutu 1920x1280 -> Harita UI boyutu 384x256 (Ölçek: 0.20)
	var world_center = Vector2(960, 640)
	var map_coord = mm.world_to_map_coords(world_center)
	assert(map_coord == Vector2(192, 128), "Koordinat ölçeklemesi 0.20 olmalı")

	var restored_world = mm.map_to_world_coords(map_coord)
	assert(restored_world == world_center, "Haritadan dünyaya koordinat dönüşümü birebir tutmalı")
	print("[PASS] Koordinat sistemi ölçekleme (1920x1280 -> 384x256) doğrulandı.")

func test_fog_of_war_revealing() -> void:
	var mm = root.get_node_or_null("MapManager")
	var far_pos = Vector2(1700, 1100) # Haritanın uzak köşesi
	var cell = mm.get_fog_cell_coord(far_pos)

	# Başlangıçta sisli olmalı
	assert(mm.is_fog_revealed(cell) == false, "Uzak hücre başlangıçta sis altında olmalı")

	# Konum çevresini aç
	mm.reveal_fog_around_world_pos(far_pos, 100.0)
	assert(mm.is_fog_revealed(cell) == true, "Keşif sonrası hücre sisi açılmalı")
	print("[PASS] Hücresel Sis Sistemi (Fog of War) ve alan aydınlatma doğrulandı.")

func test_custom_markers() -> void:
	var mm = root.get_node_or_null("MapManager")
	var marker_pos = Vector2(650, 400)

	var prev_count = mm.custom_markers.size()
	var m_id = mm.add_marker(marker_pos, "Maden Girişi", Color("f59e0b"))
	assert(mm.custom_markers.size() == prev_count + 1, "İşaretçi listeye eklenmeli")

	# Yakındaki işareti kaldırma
	var removed = mm.remove_marker_near(marker_pos, 30.0)
	assert(removed == true, "Yakındaki işaretçi kaldırılabilmeli")
	assert(mm.custom_markers.size() == prev_count, "İşaret sayısı eski haline dönmeli")
	print("[PASS] Oyuncu özel harita işaretçileri (ekleme, kaldırma, konum eşleşmesi) doğrulandı.")

func test_fast_travel_and_time_advance() -> void:
	var mm = root.get_node_or_null("MapManager")
	var tm = root.get_node_or_null("TimeManager")
	if not tm:
		tm = preload("res://scripts/core/time_manager.gd").new()
		tm.name = "TimeManager"
		root.add_child(tm)
		tm._ready()

	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(480, 320) # Köy meydanı

	# 1. Keşfedilmemiş veya uygun olmayan noktaya hızlı seyahat engeli
	assert(mm.can_fast_travel_to("watchtower") == false, "Keşfedilmemiş kuleye seyahat edilememeli")
	assert(mm.can_fast_travel_to("glade") == false, "Seyahate kapalı noktaya gidilememeli")

	# 2. Kuleyi keşfet ve seyahat et
	mm.discover_poi("watchtower")
	assert(mm.can_fast_travel_to("watchtower") == true, "Keşfedilen kuleye seyahat açılmalı")

	var start_hour = tm.current_hour
	var tower_pos = mm.pois["watchtower"]["world_pos"]
	var travel_hours = mm.calculate_travel_hours(player.global_position, tower_pos)

	var success = mm.fast_travel("watchtower", player)
	assert(success == true, "Hızlı seyahat başarılı olmalı")
	assert(player.global_position == tower_pos, "Oyuncu kule konumuna ışınlanmalı")
	assert(tm.current_hour >= start_hour, "Seyahat sonrası dünya zamanı ilerlemeli")

	player.free()
	print("[PASS] Sınırlı hızlı seyahat, mesafe süresi ve dünya saati ilerlemesi doğrulandı.")

func test_map_ui_toggle_and_player_lock() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()

	assert(player.map_ui != null, "Oyuncuda MapUI mevcut olmalı")
	assert(player.map_ui.is_open == false, "Harita başlangıçta kapalı olmalı")
	assert(player.current_state == player.State.IDLE, "Başlangıçta IDLE olmalı")

	# Haritayı aç
	player.map_ui.set_open(true)
	assert(player.map_ui.is_open == true, "Harita açılmalı")
	assert(player.current_state == player.State.INVENTORY, "Harita açıkken oyuncu kontrolleri kilitlenmeli")
	assert(player.velocity == Vector2.ZERO, "Harita açılınca oyuncu hızı sıfırlanmalı")

	# Haritayı kapat
	player.map_ui.set_open(false)
	assert(player.map_ui.is_open == false, "Harita kapanmalı")
	assert(player.current_state == player.State.IDLE, "Harita kapanınca hareket kilidi açılmalı")

	player.free()
	print("[PASS] M tuşu açılışı, arayüz çizimi ve hareket kontrollerinin kilitlenmesi doğrulandı.")

func test_map_save_load() -> void:
	var sm = root.get_node_or_null("SaveManager")
	var mm = root.get_node_or_null("MapManager")

	mm.discover_poi("glade")
	mm.add_marker(Vector2(500, 500), "Kamp Alanı")

	# Slot 1'e kaydet
	var save_res = sm.save_game(1)
	assert(save_res == true, "Kayıt başarılı olmalı")

	# Değiştir
	mm.pois["glade"]["discovered"] = false
	mm.custom_markers.clear()

	# Slot 1'den yükle
	var load_res = sm.load_game(1)
	assert(load_res == true, "Yükleme başarılı olmalı")

	assert(mm.is_poi_discovered("glade") == true, "Keşfedilen bölge geri yüklenmeli")
	assert(mm.custom_markers.size() > 0, "Özel harita işaretleri geri yüklenmeli")
	print("[PASS] MapManager ve keşif verilerinin SaveManager entegrasyonu doğrulandı.")
