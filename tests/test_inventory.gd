extends SceneTree

# Envanter Sistemi Birim ve Entegrasyon Testleri
# Kapsam:
# 1. Temel ekleme, çıkarma ve maksimum istifleme (stacking) limitleri
# 2. Slotlar arası taşıma, yer değiştirme (swap) ve birleştirme (merge)
# 3. Dolu envanter senaryosu (eşya kaybı olmaması, can_add_item kontrolü)
# 4. Kayıt / yükleme veri uyumluluğu (get_save_data / load_save_data)
# 5. Hasat edilebilir bitki ve sandık entegrasyonu (dolu envanterde koruma)

func _init() -> void:
	print("--- TEST BAŞLATILDI: Modüler Envanter Sistemi & Fiziksel Eşyalar ---")
	test_inventory_stacking_and_adding()
	test_slot_moving_and_swapping()
	test_inventory_full_handling()
	test_save_load_compatibility()
	test_world_interaction_integration()
	test_world_item_pickup_and_full_inventory()
	test_inventory_drop_item_and_safe_position()
	test_crate_loot_drop_and_bounce()
	print("--- TÜM TESTLER BAŞARIYLA TAMAMLANDI ---")
	quit(0)

func test_inventory_stacking_and_adding() -> void:
	var inv = Inventory.new()
	root.add_child(inv)

	# 1. Boş slota tekil veya istiflenebilir eşya ekleme
	var remaining = inv.add_item("wood", 50)
	assert(remaining == 0, "50 odun başarıyla eklenmeli")
	var slot0 = inv.get_slot(0)
	assert(slot0 != null and slot0["item_id"] == "wood", "Slot 0 odun olmalı")
	assert(slot0["amount"] == 50, "Slot 0 adedi 50 olmalı")

	# 2. Aynı slota istifleme (wood max_stack = 99)
	remaining = inv.add_item("wood", 40)
	assert(remaining == 0, "40 odun daha eklenmeli")
	assert(slot0["amount"] == 90, "Slot 0 adedi 90 olmalı")

	# 3. İstif sınırını aşma (90 + 15 = 105 -> Slot 0: 99, Slot 1: 6)
	remaining = inv.add_item("wood", 15)
	assert(remaining == 0, "Kalan odunlar yeni slota taşmalı")
	assert(slot0["amount"] == 99, "Slot 0 tam 99 olmalı")
	var slot1 = inv.get_slot(1)
	assert(slot1 != null and slot1["item_id"] == "wood", "Slot 1 yeni odun slotu olmalı")
	assert(slot1["amount"] == 6, "Slot 1 adedi 6 olmalı")

	# 4. İstiflenemeyen eşya ekleme (rusted_sword max_stack = 1)
	var sword_rem = inv.add_item("rusted_sword", 1)
	assert(sword_rem == 0, "Kılıç eklenmeli")
	var slot2 = inv.get_slot(2)
	assert(slot2 != null and slot2["item_id"] == "rusted_sword" and slot2["amount"] == 1, "Slot 2 kılıç olmalı")

	var sword_rem2 = inv.add_item("rusted_sword", 1)
	assert(sword_rem2 == 0, "İkinci kılıç yeni slota eklenmeli")
	var slot3 = inv.get_slot(3)
	assert(slot3 != null and slot3["item_id"] == "rusted_sword" and slot3["amount"] == 1, "Slot 3 ikinci kılıç olmalı")

	inv.queue_free()
	print("[PASS] Eşya ekleme ve istifleme mantığı doğrulandı.")

func test_slot_moving_and_swapping() -> void:
	var inv = Inventory.new()
	root.add_child(inv)

	inv.add_item("red_herb", 10) # slot 0
	inv.add_item("iron_ore", 5)  # slot 1

	# Boş slota taşıma: Slot 0 -> Slot 5
	var success = inv.move_or_merge_slot(0, 5)
	assert(success == true, "Boş slota taşıma başarılı olmalı")
	assert(inv.is_slot_empty(0), "Slot 0 boşalmalı")
	assert(inv.get_slot(5)["item_id"] == "red_herb" and inv.get_slot(5)["amount"] == 10, "Slot 5 kırmızı ot olmalı")

	# Dolu slotlar arası takas (swap): Slot 1 (iron_ore) ile Slot 5 (red_herb)
	success = inv.move_or_merge_slot(1, 5)
	assert(success == true, "Takas işlemi başarılı olmalı")
	assert(inv.get_slot(1)["item_id"] == "red_herb" and inv.get_slot(1)["amount"] == 10, "Slot 1 artık kırmızı ot olmalı")
	assert(inv.get_slot(5)["item_id"] == "iron_ore" and inv.get_slot(5)["amount"] == 5, "Slot 5 artık demir olmalı")

	# Aynı eşyaları birleştirme (merge):
	# Slot 1'de 10 red_herb var. Slot 2'ye de 15 red_herb koyalım.
	inv.set_slot(2, "red_herb", 15)
	success = inv.move_or_merge_slot(1, 2)
	assert(success == true, "Birleştirme başarılı olmalı")
	assert(inv.is_slot_empty(1), "Slot 1 tamamen aktarılıp boşalmalı")
	assert(inv.get_slot(2)["amount"] == 25, "Slot 2 toplam 25 red_herb olmalı")

	inv.queue_free()
	print("[PASS] Slotlar arası taşıma, takas ve birleştirme doğrulandı.")

func test_inventory_full_handling() -> void:
	var inv = Inventory.new()
	root.add_child(inv)

	# 24 slotun hepsini kılıçlarla doldur
	for i in range(Inventory.SLOT_COUNT):
		inv.set_slot(i, "rusted_sword", 1)

	assert(inv.is_full() == true, "Envanter dolu olarak raporlanmalı")
	assert(inv.can_add_item("rusted_sword", 1) == false, "Yeni kılıç eklenemez olmalı")
	assert(inv.can_add_item("wood", 1) == false, "Yeni tür eşya eklenemez olmalı")

	# Dolu envantere ekleme denenirse eşya kaybolmamalı, tamamı iade dönmeli
	var excess = inv.add_item("wood", 10)
	assert(excess == 10, "Eklenemeyen eşya eksiksiz iade dönmeli")

	inv.queue_free()
	print("[PASS] Dolu envanter kontrolü ve eşya kaybı olmaması doğrulandı.")

func test_save_load_compatibility() -> void:
	var inv = Inventory.new()
	root.add_child(inv)

	inv.set_slot(0, "wild_apple", 5)
	inv.set_slot(7, "ancient_medallion", 1)

	var save_data = inv.get_save_data()
	assert(save_data.size() == 24, "Kayıt verisi 24 slot içermeli")
	assert(save_data[0]["item_id"] == "wild_apple", "Kayıtta slot 0 doğru olmalı")
	assert(save_data[7]["item_id"] == "ancient_medallion", "Kayıtta slot 7 doğru olmalı")

	# Yeni envantere yükle
	var new_inv = Inventory.new()
	root.add_child(new_inv)
	new_inv.load_save_data(save_data)

	assert(new_inv.get_slot(0)["item_id"] == "wild_apple" and new_inv.get_slot(0)["amount"] == 5, "Slot 0 doğru yüklendi")
	assert(new_inv.get_slot(7)["item_id"] == "ancient_medallion" and new_inv.get_slot(7)["amount"] == 1, "Slot 7 doğru yüklendi")
	assert(new_inv.is_slot_empty(1), "Boş slotlar boş kalmalı")

	inv.queue_free()
	new_inv.queue_free()
	print("[PASS] Envanter kayıt ve yükleme uyumluluğu doğrulandı.")

func test_world_interaction_integration() -> void:
	# Oyuncu ve bitki hasadı testi
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()
	assert(inv != null, "Oyuncu envanteri geçerli olmalı")

	# 1. Oyuncu boş envanterle bitki toplar
	var plant = HarvestablePlant.new()
	plant.item_id = "red_herb"
	plant.harvest_amount = 3
	root.add_child(plant)

	plant.interact_with(player)
	assert(plant.current_state == "harvested", "Bitki toplanmış olmalı")
	assert(inv.has_item("red_herb", 3) == true, "Oyuncu envanterinde 3 adet red_herb olmalı")

	# 2. Envanteri tamamen doldurup sandık açmayı deneyelim
	# Envanterin kalan 23 slotunu dolduralım
	for i in range(1, 24):
		inv.set_slot(i, "rusted_sword", 1)
	assert(inv.is_full() == true, "Envanter doldu")

	# Sandık testi
	var chest = ChestInteractable.new()
	var ids: Array[String] = ["wood", "iron_ore"]
	var amts: Array[int] = [10, 5]
	chest.reward_item_ids = ids
	chest.reward_item_amounts = amts
	root.add_child(chest)

	chest.interact_with(player)
	assert(chest.is_looted == false, "Envanter dolu olduğu için sandık yağmalanamamalı")
	assert(inv.has_item("wood", 10) == false, "Odun eklenememiş olmalı")

	# Bir slotu boşaltıp tekrar deneyelim
	inv.remove_from_slot(23, 1) # Slot 23 boşaldı ama 2 farklı eşya var, wood sığar iron_ore sığmaz
	chest.interact_with(player)
	assert(chest.is_looted == false, "Tüm ödüller sığmadığı sürece sandık yağmalanmamalı")

	# İki slot boşaltalım
	inv.remove_from_slot(22, 1)
	chest.interact_with(player)
	assert(chest.is_looted == true, "Tüm ödüller sığdığında sandık yağmalanmalı")
	assert(inv.has_item("wood", 10) == true, "Odun eklenmiş olmalı")
	assert(inv.has_item("iron_ore", 5) == true, "Demir eklenmiş olmalı")

	player.queue_free()
	plant.queue_free()
	chest.queue_free()
	print("[PASS] Dünya nesneleri (bitki ve sandık) ile envanter entegrasyonu doğrulandı.")

func test_world_item_pickup_and_full_inventory() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()

	# 1. Yerde duran eşya oluştur (Gölge Yosunu x2)
	var world_item = preload("res://scenes/props/world_item.tscn").instantiate() as WorldItem
	world_item.setup_item("shadow_moss", 2)
	root.add_child(world_item)

	assert(world_item.is_interactable == true, "Yerdeki eşya toplanabilir olmalı")
	assert(world_item.get_action_prompt_text().contains("Gölge Yosunu"), "Eşya adı promptta geçmeli")

	# 2. Boş envanterle topla
	world_item.interact_with(player)
	assert(inv.has_item("shadow_moss", 2) == true, "Toplanan eşya envantere girmeli")

	# 3. Dolu envanter senaryosu: Envanteri dolduralım
	for i in range(Inventory.SLOT_COUNT):
		inv.set_slot(i, "rusted_sword", 1)
	assert(inv.is_full() == true, "Envanter doldu")

	# Yeni bir yerdeki eşya (Demir Cevheri x5)
	var world_item2 = preload("res://scenes/props/world_item.tscn").instantiate() as WorldItem
	world_item2.setup_item("iron_ore", 5)
	root.add_child(world_item2)

	world_item2.interact_with(player)
	# Envanter dolu olduğu için eşya silinmemeli, yerde kalmalı ve miktarı azalmamalıdır
	assert(is_instance_valid(world_item2) == true, "Dolu envanterde yerdeki eşya kaybolmamalı")
	assert(world_item2.amount == 5, "Eşya adedi eksilmemeli")
	assert(inv.has_item("iron_ore", 5) == false, "Dolu envantere demir eklenememiş olmalı")

	# Bir slot boşaltınca toplanabilmeli
	inv.remove_from_slot(0, 1)
	world_item2.interact_with(player)
	assert(inv.has_item("iron_ore", 5) == true, "Boş slot açılınca demir envantere eklenmeli")

	player.queue_free()
	print("[PASS] Yerdeki eşyaları toplama ve dolu envanterde yerde kalma davranışı doğrulandı.")

func test_inventory_drop_item_and_safe_position() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var inv: Inventory = player.get_inventory()

	# Oyuncunun slotuna 5 adet elma koyalım
	inv.set_slot(0, "wild_apple", 5)
	assert(inv.has_item("wild_apple", 5) == true, "5 elma envanterde")

	# 1 elma yere bırakılsın
	player._on_item_drop_requested(0, 1)
	assert(inv.get_slot(0)["amount"] == 4, "Envanterde 4 elma kalmalı")

	# Dünyaya eklenen WorldItem'ı bul
	var dropped_item: WorldItem = null
	for child in root.get_children():
		if child is WorldItem and child.item_id == "wild_apple":
			dropped_item = child
			break

	assert(dropped_item != null, "Yere WorldItem örneği bırakılmış olmalı")
	assert(dropped_item.amount == 1, "Bırakılan miktar 1 olmalı")

	# Kalan 4 elmayı da bırakalım
	player._on_item_drop_requested(0, 4)
	assert(inv.is_slot_empty(0) == true, "Slot tamamen boşalmalı")

	# Güvenli pozisyon kontrolü (oyuncudan en fazla 30 birim uzakta olmalı)
	var safe_pos = player._find_safe_drop_position()
	assert(player.global_position.distance_to(safe_pos) <= 30.0, "Bırakma noktası oyuncunun yakınında olmalı")

	if dropped_item:
		dropped_item.queue_free()
	player.queue_free()
	print("[PASS] Envanterden eşya bırakma ve güvenli koordinat belirleme doğrulandı.")

func test_crate_loot_drop_and_bounce() -> void:
	var crate = preload("res://scenes/props/breakable_crate.tscn").instantiate() as BreakableCrate
	crate.loot_chance = 1.0 # Test için kesin ganimet düşsün
	var loots: Array[String] = ["wood"]
	crate.possible_loot_ids = loots
	root.add_child(crate)

	crate.break_crate()
	assert(crate.is_broken == true, "Kasa kırılmalı")
	assert(crate.has_dropped_loot == true, "Kasa ganimet düşürmüş olmalı")

	# Düşen WorldItem'ı tespit et
	var dropped_wood: WorldItem = null
	for child in root.get_children():
		if child is WorldItem and child.item_id == "wood":
			dropped_wood = child
			break

	assert(dropped_wood != null, "Kırılan kasadan odun WorldItem'ı düşmüş olmalı")
	assert(dropped_wood.is_bouncing == true, "Eşya düşme/sıçrama animasyonuyla başlamalı")

	# Animasyon sürecini simüle et
	dropped_wood._process(0.5)
	assert(dropped_wood.is_bouncing == false, "Animasyon süresi bitince sıçrama tamamlanmalı")
	assert(dropped_wood.is_interactable == true, "Yere inen eşya toplanabilir olmalı")

	crate.queue_free()
	if dropped_wood:
		dropped_wood.queue_free()
	print("[PASS] Kasa kırıldığında ganimet düşmesi ve sıçrama animasyonu doğrulandı.")
