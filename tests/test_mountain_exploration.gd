extends SceneTree

# Test: Mountain Exploration (Mineable Rock Vein, Ancient Shrine, Mountain Valley Location)

var tests_passed = 0
var tests_failed = 0
var _tested = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true

	print("--- TEST BAŞLANGICI: MOUNTAIN EXPLORATION ---")
	test_mineable_rock()
	test_ancient_shrine()
	test_mountain_valley_location_instances()
	test_save_load_persistence()

	print("\n--- TEST SONUÇLARI ---")
	print("Başarılı: %d, Başarısız: %d" % [tests_passed, tests_failed])
	if tests_failed == 0:
		print("TÜM DAĞ KEŞİF TESTLERİ BAŞARIYLA GEÇTİ!")
		quit(0)
	else:
		printerr("Bazı testler başarısız oldu!")
		quit(1)
	return true

func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		printerr("FAIL: " + message)

func test_mineable_rock() -> void:
	print("\n[Test 1: MineableRock Vuruş ve Parçalanma]")
	var rock = MineableRock.new()
	rock.interactable_id = "test_rock_1"
	rock.loot_count_min = 2
	rock.loot_count_max = 2
	var loot_arr: Array[String] = ["iron_ore"]
	rock.possible_loot_ids = loot_arr
	root.add_child(rock)

	assert_true(not rock.is_broken, "Kaya başlangıçta kırılmamış olmalı")
	assert_true(rock.hits_left == 3, "Başlangıç vuruş canı 3 olmalı")

	# 1. vuruş
	rock.damage_rock(1)
	assert_true(rock.hits_left == 2, "1. vuruştan sonra 2 can kalmalı")
	assert_true(not rock.is_broken, "1. vuruşta kırılmamalı")

	# 2. vuruş
	rock.damage_rock(1)
	assert_true(rock.hits_left == 1, "2. vuruştan sonra 1 can kalmalı")

	# 3. vuruş - kırılma
	rock.damage_rock(1)
	assert_true(rock.is_broken, "3. vuruştan sonra is_broken true olmalı")
	assert_true(rock.current_state == "broken", "Durum 'broken' olmalı")
	assert_true(not rock.is_interactable, "Kırıldıktan sonra etkileşime kapalı olmalı")
	assert_true(rock.has_dropped_loot, "Ganimet düşürmüş olmalı")

	rock.queue_free()

func test_ancient_shrine() -> void:
	print("\n[Test 2: AncientShrine Adak Sunma ve Şifa]")
	var shrine = AncientShrine.new()
	shrine.interactable_id = "test_shrine_1"
	root.add_child(shrine)

	assert_true(not shrine.is_activated, "Sunak başlangıçta inaktif olmalı")

	# Sahte oyuncu ve envanter
	var player = CharacterBody2D.new()
	var inv = Inventory.new()
	inv.name = "Inventory"
	player.add_child(inv)
	player.set("inventory", inv)
	root.add_child(player)

	# Adak olmadan etkileşim
	shrine._on_interacted(player)
	assert_true(not shrine.is_activated, "Adaksız etkileşimde aktifleşmemeli")

	# Dağ çiçeği ekle
	inv.add_item("mountain_flower", 1)
	assert_true(inv.get_item_count("mountain_flower") == 1, "Envantere dağ çiçeği eklendi")

	# Adak ile etkileşim
	shrine._on_interacted(player)
	assert_true(shrine.is_activated, "Çiçek sunulduğunda sunak aktifleşmeli")
	assert_true(inv.get_item_count("mountain_flower") == 0, "Sunulan dağ çiçeği envanterden tüketilmeli")

	player.queue_free()
	shrine.queue_free()

func test_mountain_valley_location_instances() -> void:
	print("\n[Test 3: Mountain Valley Sahnesi Düğüm Kontrolleri]")
	var scene = load("res://scenes/world/mountain_valley_location.tscn")
	var mtn_instance = scene.instantiate()
	root.add_child(mtn_instance)

	var ysort = mtn_instance.get_node_or_null("YSort_Entities")
	assert_true(ysort != null, "YSort_Entities bulunmalı")

	var rock1 = ysort.get_node_or_null("OreVein_1")
	assert_true(rock1 is MineableRock, "OreVein_1 MineableRock türünde olmalı")

	var shrine = ysort.get_node_or_null("AncientShrine_Peak")
	assert_true(shrine is AncientShrine, "AncientShrine_Peak AncientShrine türünde olmalı")

	mtn_instance.queue_free()

func test_save_load_persistence() -> void:
	print("\n[Test 4: Save & Load Kalıcılığı]")
	var rock = MineableRock.new()
	rock.interactable_id = "rock_persist"
	rock.damage_rock(3) # Kır
	var rock_data = rock.get_save_data()
	assert_true(rock_data.get("is_broken", false) == true, "Kaya save verisinde is_broken true olmalı")

	var new_rock = MineableRock.new()
	new_rock.load_save_data(rock_data)
	assert_true(new_rock.is_broken == true, "Yeni kaya save'den yüklenince broken olmalı")

	var shrine = AncientShrine.new()
	shrine.interactable_id = "shrine_persist"
	shrine.current_state = "activated"
	shrine.is_activated = true
	var shrine_data = shrine.get_save_data()
	assert_true(shrine_data.get("is_activated", false) == true, "Sunak save verisinde is_activated true olmalı")

	var new_shrine = AncientShrine.new()
	new_shrine.load_save_data(shrine_data)
	assert_true(new_shrine.is_activated == true, "Yeni sunak save'den yüklenince aktif olmalı")

	rock.queue_free()
	new_rock.queue_free()
	shrine.queue_free()
	new_shrine.queue_free()
