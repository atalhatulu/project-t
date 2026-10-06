extends SceneTree

# Test betiği: Etkileşimli nesneler, öncelik seçimi, diyalog ve kırılma testleri

func _init() -> void:
	print("--- TEST BAŞLATILDI: Çevresel Etkileşim Altyapısı ---")
	test_interactable_types()
	test_interaction_priority()
	test_crate_breaking()
	test_plant_respawn()
	print("--- TÜM ETKİLEŞİM TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)

func test_interactable_types() -> void:
	# 1. Sandık Testi
	var chest = ChestInteractable.new()
	root.add_child(chest)
	assert(chest.is_open == false, "Sandık başlangıçta kapalı olmalı")
	assert(chest.get_action_prompt_text() == "Aç", "Prompt 'Aç' olmalı")
	chest.interact_with(null)
	assert(chest.is_open == true, "Etkileşim sonrası sandık açılmalı")
	assert(chest.get_action_prompt_text() == "Kapat", "Açıkken prompt 'Kapat' olmalı")
	chest.queue_free()

	# 2. Tabela Testi
	var sign = ReadableSign.new()
	sign.sign_message = "Test Tabelası"
	root.add_child(sign)
	assert(sign.prompt_action_text == "Oku", "Tabela promptu 'Oku' olmalı")
	sign.queue_free()

	# 3. Harabe Testi
	var ruin = AncientRuin.new()
	root.add_child(ruin)
	assert(ruin.prompt_action_text == "İncele", "Harabe promptu 'İncele' olmalı")
	ruin.queue_free()

	print("[PASS] Sandık, Tabela ve Harabe temel etkileşimleri doğrulandı.")

func test_interaction_priority() -> void:
	# Oyuncu ve çoklu nesne mesafe önceliği testi
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	var item1 = ChestInteractable.new()
	root.add_child(item1)
	item1.global_position = Vector2(110, 100) # 10 birim uzaklıkta

	var item2 = ReadableSign.new()
	root.add_child(item2)
	item2.global_position = Vector2(130, 100) # 30 birim uzaklıkta

	var arr: Array[Node2D] = [item2, item1]
	player.nearby_interactables = arr
	player._update_active_interaction_target()

	assert(player.active_target == item1, "En yakın nesne (item1) aktif hedef seçilmeli")
	assert(item1.prompt_node.visible == true, "En yakın nesnenin promptu görünür olmalı")
	assert(item2.prompt_node.visible == false, "Uzak nesnenin promptu gizlenmeli")

	# item1'i devre dışı bırakalım
	item1.is_interactable = false
	player._update_active_interaction_target()
	assert(player.active_target == item2, "Devre dışı kalan nesneden sonra sıradaki yakın nesne seçilmeli")
	assert(item2.prompt_node.visible == true, "Sıradaki nesnenin promptu aktif olmalı")

	player.queue_free()
	item1.queue_free()
	item2.queue_free()
	print("[PASS] Çoklu nesnede en yakın hedef seçimi ve prompt aktivasyonu doğrulandı.")

func test_crate_breaking() -> void:
	var crate = BreakableCrate.new()
	root.add_child(crate)
	assert(crate.is_broken == false, "Kasa başlangıçta sağlam olmalı")
	assert(crate.is_interactable == true, "Kasa etkileşime açık olmalı")

	crate.break_crate()
	assert(crate.is_broken == true, "Kasa kırılmış olmalı")
	assert(crate.is_interactable == false, "Kırılan kasa etkileşime kapanmalı")
	assert(crate.collision_layer == 0, "Kırılan kasanın çarpışması devre dışı kalmalı")
	assert(crate.wood_splinters.size() > 0, "Kasa kırılma parçacıkları üretilmeli")

	crate.queue_free()
	print("[PASS] Kasa kırılma, parçacık saçma ve çarpışma iptali doğrulandı.")

func test_plant_respawn() -> void:
	var plant = HarvestablePlant.new()
	plant.respawn_game_hours = 2.0
	root.add_child(plant)

	assert(plant.current_state == "ready", "Bitki hazır olmalı")
	plant.interact_with(null)
	assert(plant.current_state == "harvested", "Toplandıktan sonra 'harvested' olmalı")
	assert(plant.is_interactable == false, "Toplanan bitki etkileşime kapanmalı")

	# 1 saat geçsin
	plant._on_hour_changed(1)
	assert(plant.current_state == "harvested", "1 saat sonra hala hasat edilmiş olmalı")

	# 2. saat geçsin -> yeniden büyümeli
	plant._on_hour_changed(2)
	assert(plant.current_state == "ready", "Yeniden büyüme süresi dolunca 'ready' olmalı")
	assert(plant.is_interactable == true, "Tekrar toplanabilir olmalı")

	plant.queue_free()
	print("[PASS] Bitki toplama ve TimeManager saat döngüsünde yeniden yetişme doğrulandı.")
