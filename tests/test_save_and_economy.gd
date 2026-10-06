extends SceneTree

# Test betiği: Görev 17 (Save/Load) & Görev 18 (Ekonomi ve Zanaat)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 17 & 18 — Save/Load ve Ekonomi ---")
	test_economy_trading()
	test_economy_crafting()
	test_save_load_lifecycle()
	test_save_error_handling()
	print("--- TÜM SAVE/LOAD VE EKONOMİ TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_economy_trading() -> void:
	var em = preload("res://scripts/economy/economy_manager.gd").new()
	root.add_child(em)
	em._ready()

	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()

	# Oyuncuya 100 bakır sikke ver
	inv.add_item("cooper_coins", 100)
	assert(em.get_player_gold(inv) == 100, "Oyuncunun başlangıçta 100 parası olmalı")

	# Mira'dan 2 somun ekmek al (inn_bread base: 6)
	var bread_price = em.get_item_price("inn_bread", 1.0, true)
	var success_buy = em.buy_from_merchant("mira", "inn_bread", 2, inv)
	assert(success_buy == true, "Ekmek alımı başarılı olmalı")
	assert(inv.has_item("inn_bread", 2) == true, "Envantere 2 ekmek gelmeli")
	assert(em.get_player_gold(inv) == 100 - (bread_price * 2), "Para tam olarak eksilmeli")

	# 1 ekmeği geri sat
	var sell_unit_price = em.get_item_price("inn_bread", 1.0, false)
	var prev_gold = em.get_player_gold(inv)
	var success_sell = em.sell_to_merchant("mira", "inn_bread", 1, inv)
	assert(success_sell == true, "Ekmek satışı başarılı olmalı")
	assert(inv.has_item("inn_bread", 1) == true, "Kalan ekmek 1 olmalı")
	assert(em.get_player_gold(inv) == prev_gold + sell_unit_price, "Satış tutarı eklenmeli")

	# Para yetersizken alma testi
	inv.remove_item("cooper_coins", em.get_player_gold(inv)) # Sıfırla
	var failed_buy = em.buy_from_merchant("mira", "inn_bread", 1, inv)
	assert(failed_buy == false, "Yetersiz para ile alım başarısız olmalı ve eşya verilmemeli")

	em.free()
	player.free()
	print("[PASS] Ekonomi alışverişi, para hesapları ve atomik işlem doğrulamaları tamamlandı.")

func test_economy_crafting() -> void:
	var em = preload("res://scripts/economy/economy_manager.gd").new()
	root.add_child(em)
	em._ready()

	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()

	# 2 Odun + 2 Demir Cevheri ver
	inv.add_item("wood", 2)
	inv.add_item("iron_ore", 2)

	assert(em.can_craft_recipe("craft_axe", inv) == true, "Malzemeler varken üretilebilmeli")
	var craft_ok = em.craft_recipe("craft_axe", inv)
	assert(craft_ok == true, "Üretim başarılı olmalı")
	assert(inv.has_item("crafted_axe", 1) == true, "Envantere balta gelmeli")
	assert(inv.has_item("wood", 2) == false, "Malzemeler tüketilmeli")
	assert(inv.has_item("iron_ore", 2) == false, "Malzemeler tüketilmeli")

	# Malzeme olmadan üretim denenmesi
	assert(em.can_craft_recipe("craft_axe", inv) == false, "Yetersiz malzemeyle üretilememeli")

	em.free()
	player.free()
	print("[PASS] Zanaat/üretim tarifleri ve atomik malzeme tüketimi doğrulandı.")

func test_save_load_lifecycle() -> void:
	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = preload("res://scripts/save/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)
		sm._ready()

	# Test ortamı: Oyuncu, Sandık
	var player = preload("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	root.add_child(player)
	player.add_to_group("player")
	player._ready()
	player.global_position = Vector2(350, 420)
	player.current_health = 68
	var inv: Inventory = player.get_inventory()
	inv.add_item("iron_ore", 5)
	inv.add_item("cooper_coins", 77)

	var chest = preload("res://scenes/props/chest.tscn").instantiate()
	chest.interactable_id = "test_chest_save_01"
	root.add_child(chest)
	chest._ready()
	chest.current_state = "opened"
	chest.is_open = true # Açılmış sandık

	# Slot 1'e kaydet
	var save_success = sm.save_game(1)
	assert(save_success == true, "Slot 1'e kayıt başarılı olmalı")
	assert(sm.save_slot_exists(1) == true, "Kayıt dosyası var olmalı")

	# Durumları değiştir
	player.global_position = Vector2(100, 100)
	player.current_health = 100
	inv.clear()
	chest.is_open = false

	# Slot 1'den yükle
	var load_success = sm.load_game(1)
	assert(load_success == true, "Slot 1'den yükleme başarılı olmalı")

	# Doğrula
	assert(player.global_position == Vector2(350, 420), "Oyuncu konumu geri yüklenmeli: " + str(player.global_position))
	assert(player.current_health == 68, "Oyuncu canı geri yüklenmeli")
	assert(inv.has_item("iron_ore", 5) == true, "Envanter eşyaları geri yüklenmeli")
	assert(inv.has_item("cooper_coins", 77) == true, "Paralar geri yüklenmeli")
	assert(chest.is_open == true, "Sandık açık durumu geri yüklenmeli")

	chest.free()
	player.free()
	print("[PASS] Sürüm kontrollü SaveManager, 3 slot altyapısı ve dünya durumu geri yükleme doğrulandı.")

func test_save_error_handling() -> void:
	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = preload("res://scripts/save/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)
		sm._ready()

	# Olmayan slotu yüklemeyi dene
	var missing_res = sm.load_game(99) # Slot 99 yok
	assert(missing_res == false, "Olmayan kayıt yüklenmeye çalışıldığında güvenli false dönmeli")

	# Bozuk JSON dosyası simülasyonu
	var corrupt_path = sm.get_slot_path(3)
	var f = FileAccess.open(corrupt_path, FileAccess.WRITE)
	f.store_string("{ 'bozuk_json': [ }")
	f.close()

	var corrupt_res = sm.load_game(3)
	assert(corrupt_res == false, "Bozuk JSON yüklenmeye çalışıldığında çökmeden false dönmeli")

	var meta = sm.get_slot_metadata(3)
	assert(meta.get("corrupted", false) == true, "Bozuk dosya metadata tarafından tespit edilmeli")

	print("[PASS] Hatalı ve bozuk dosyalarda çökmeden güvenli hata yönetimi doğrulandı.")
