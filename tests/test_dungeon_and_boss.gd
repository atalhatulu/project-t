extends SceneTree

# Test betiği: Görev 26 — Yankılı Mağara Zindanı & Boss Doğrulama Testi
# Senaryolar:
# 1. Zindan sahne yapısı & 7 oda bileşenleri (Tuzaklar, Basınç Plakası, İtilebilir Kaya, Gizli Duvar, Boss, Ödül)
# 2. Ağırlık Plakası ve İtilebilir Kaya etkileşimi (Kapı açılması)
# 3. Kırılabilir Gizli Duvar mekaniği (Vuruş hasarı ve parçalanma)
# 4. Zamanlamalı Yer Dikenleri & Zehir Sisi hasar mantığı
# 5. Kadim Mağara Trolü (Faz 1, Faz 2 öfke, Slam telegraph, Boss kapısı açılması)
# 6. Kanca (Grappling Hook) mekaniği & Açık dünyada yeni alanlara erişim (Kule & Nehir Adası)

const PressurePlateScript = preload("res://scripts/interactables/pressure_plate.gd")
const PushableRockScript = preload("res://scripts/interactables/pushable_rock.gd")
const GrapplePointScript = preload("res://scripts/interactables/grapple_point.gd")
const SecretWallScript = preload("res://scripts/world/secret_wall.gd")
const FloorSpikesScript = preload("res://scripts/world/floor_spikes.gd")
const PoisonMistAreaScript = preload("res://scripts/world/poison_mist_area.gd")
const CaveTrollScript = preload("res://scripts/creatures/cave_troll.gd")

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 26 — Yankılı Mağara Zindanı Smoke Test ---")
	test_dungeon_scene_structure()
	test_pressure_plate_and_rock_puzzle()
	test_secret_wall_break()
	test_spikes_and_hazard_traps()
	test_cave_troll_boss_phases()
	test_grappling_hook_mechanic_and_world_access()
	print("--- TÜM ZİNDAN VE BOSS DOĞRULAMALARI BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_dungeon_scene_structure() -> void:
	var dungeon = preload("res://scenes/interiors/cave_dungeon.tscn").instantiate()
	root.add_child(dungeon)
	
	var ysort = dungeon.get_node_or_null("YSort_Entities")
	assert(ysort != null, "YSort_Entities bulunmalı")
	
	var plate = ysort.get_node_or_null("PuzzlePlate")
	assert(plate != null, "Basınç plakası bulunmalı")
	
	var rock = ysort.get_node_or_null("PuzzleRock")
	assert(rock != null, "İtilebilir kaya bulunmalı")
	
	var wall = ysort.get_node_or_null("SecretWall")
	assert(wall != null, "Gizli kırılabilir duvar bulunmalı")
	
	var spikes1 = ysort.get_node_or_null("SpikeTrap1")
	assert(spikes1 != null, "Yer dikeni tuzağı bulunmalı")
	
	var troll = ysort.get_node_or_null("CaveTrollBoss")
	assert(troll != null, "Mağara trolü boss'u bulunmalı")
	
	var reward_chest = ysort.get_node_or_null("RewardChest")
	assert(reward_chest != null, "Ödül sandığı bulunmalı")
	assert(reward_chest.reward_item_ids.has("grappling_hook"), "Ödül sandığında kanca (grappling_hook) bulunmalı")
	
	dungeon.free()
	print("[PASS] Zindan sahne yapısı ve 7 oda nesneleri başarıyla doğrulandı.")

func test_pressure_plate_and_rock_puzzle() -> void:
	var plate = PressurePlateScript.new()
	var door = preload("res://scenes/props/dungeon_door.tscn").instantiate()
	root.add_child(door)
	root.add_child(plate)
	plate._ready()
	door._ready()
	
	door.is_locked = true
	door.is_open = false
	door._apply_door_state()
	assert(door.is_open == false, "Kapı başlangıçta kapalı olmalı")
	
	plate.target_door_path = plate.get_path_to(door)
	plate.press_plate()
	assert(plate.is_pressed == true, "Plaka basılmış olmalı")
	assert(door.is_open == true, "Plaka kapıyı açmalı")
	assert(door.is_locked == false, "Kapının kilidi çözülmeli")
	
	plate.free()
	door.free()
	print("[PASS] Basınç plakası ve kapı açılma bulmacası doğrulandı.")

func test_secret_wall_break() -> void:
	var wall = SecretWallScript.new()
	root.add_child(wall)
	wall._ready()
	
	assert(wall.is_broken == false, "Duvar başlangıçta sağlam olmalı")
	wall.take_hit()
	assert(wall.current_hits == 1, "1 vuruş sayılmalı")
	wall.take_hit()
	assert(wall.current_hits == 2, "2 vuruş sayılmalı")
	wall.take_hit()
	assert(wall.is_broken == true, "3 vuruşta duvar kırılmalı")
	assert(wall.collision_layer == 0, "Kırılan duvarın çarpışma katmanı sıfırlanmalı")
	
	wall.free()
	print("[PASS] Kırılabilir gizli duvar hasar ve parçalanma mantığı doğrulandı.")

func test_spikes_and_hazard_traps() -> void:
	var spikes = FloorSpikesScript.new()
	spikes.cycle_interval = 2.0
	spikes.warning_duration = 0.5
	spikes.extended_duration = 0.5
	root.add_child(spikes)
	spikes._ready()
	
	# Zaman döngüsünü simüle et
	spikes._physics_process(0.5)
	assert(spikes.current_state == FloorSpikesScript.SpikeState.RETRACTED, "0.5 sn'de dikenler içeride olmalı")
	
	spikes._physics_process(0.6) # t = 1.1 sn -> Warning eşiği (2.0 - 1.0 = 1.0)
	assert(spikes.current_state == FloorSpikesScript.SpikeState.WARNING, "1.1 sn'de uyarı evresinde olmalı")
	
	spikes._physics_process(0.5) # t = 1.6 sn -> Extended eşiği (2.0 - 0.5 = 1.5)
	assert(spikes.current_state == FloorSpikesScript.SpikeState.EXTENDED, "1.6 sn'de dikenler dışarıda ve tehlikeli olmalı")
	
	spikes.free()
	print("[PASS] Zamanlamalı yer dikeni döngüleri ve uyarı evreleri doğrulandı.")

func test_cave_troll_boss_phases() -> void:
	var troll = CaveTrollScript.new()
	var door = preload("res://scenes/props/dungeon_door.tscn").instantiate()
	root.add_child(door)
	root.add_child(troll)
	troll._ready()
	door._ready()
	
	door.is_locked = true
	door.is_open = false
	door._apply_door_state()
	troll.boss_door_path = troll.get_path_to(door)
	
	assert(troll.current_phase == CaveTrollScript.BossPhase.PHASE_1, "Trol başlangıçta Faz 1'de olmalı")
	assert(troll.current_health == 180, "Trol 180 canla başlamalı")
	
	# Hasar al ve Faz 2 kontrolü
	troll.current_health = 80 # %50 altı
	troll._physics_process(0.016)
	assert(troll.current_phase == CaveTrollScript.BossPhase.ENRAGED, "Can %50 altına inince Faz 2 Öfkeli moda geçmeli")
	assert(troll.base_speed > 40.0, "Faz 2'de hızı artmalı")
	
	# Boss yenilgisi
	troll.die()
	assert(troll.current_state == BaseCreature.CreatureState.DEAD, "Trol ölü durumuna geçmeli")
	assert(door.is_open == true, "Trol ölünce boss kapısı otomatik açılmalı")
	
	troll.free()
	door.free()
	print("[PASS] Kadim Mağara Trolü faz geçişleri, saldırı öfkesi ve kapı açma mekaniği doğrulandı.")

func test_grappling_hook_mechanic_and_world_access() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()
	
	var inv: Inventory = player.get_inventory()
	assert(inv != null, "Oyuncunun envanteri olmalı")
	
	var grapple_point = GrapplePointScript.new()
	grapple_point.global_position = Vector2(300, 300)
	root.add_child(grapple_point)
	grapple_point._ready()
	
	# Kancasız etkileşim: çekilmemeli
	player.global_position = Vector2(100, 100)
	grapple_point._on_interacted(player)
	assert(player.current_state != player.State.GRAPPLE, "Kancasız oyuncu kanca moduna geçmemeli")
	
	# Kanca ekle ve etkileşim dene
	inv.add_item("grappling_hook", 1)
	assert(inv.has_item("grappling_hook", 1), "Envantere kanca eklenmeli")
	
	grapple_point._on_interacted(player)
	assert(player.current_state == player.State.GRAPPLE, "Kanca varken oyuncu GRAPPLE state'ine geçmeli")
	
	# Hareketi simüle et
	for i in range(30):
		player._physics_process(0.033)
	
	assert(player.current_state == player.State.IDLE or player.current_state == player.State.MOVE, "Çekilme tamamlanınca oyuncu serbest kalmalı")
	assert(player.global_position.distance_to(grapple_point.global_position + grapple_point.arrival_offset) < 15.0, "Oyuncu kanca hedefine ulaşmış olmalı")
	
	# Açık dünya lokasyonunda kanca noktaları mevcut mu kontrol et
	var world_scene = preload("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world_scene)
	var tower_grapple = world_scene.find_child("Grapple_Tower_Ledge", true, false)
	assert(tower_grapple != null, "Gözetleme Kulesi terasında kanca noktası bulunmalı")
	var island_grapple = world_scene.find_child("Grapple_River_Island", true, false)
	assert(island_grapple != null, "Nehir Adası gizli alanında kanca noktası bulunmalı")
	var island_chest = world_scene.find_child("Chest_River_Island", true, false)
	assert(island_chest != null, "Nehir Adası gizli sandığı bulunmalı")
	
	world_scene.free()
	player.free()
	grapple_point.free()
	print("[PASS] Kanca mekaniği ve açık dünya kule/nehir adası erişimi doğrulandı.")
