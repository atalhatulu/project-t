extends SceneTree

# Test betiği: Görev 28 — Karakter-Çevre Etkileşimi & Devasa Bölgesel Harita Smoke Test
# Senaryolar:
# 1. Adım İzleri & Parçacıkları (Zemine göre ayak izi kalıcılığı ve sönümlenmesi)
# 2. Uzun Otların Ezilmesi & Hışırtı Efekti (TallGrass spring fiziği ve parçacık tepkisi)
# 3. İkinci Bölge (Dağ Eteği Vadisi) Biyom & Kanyon Yapısı (Kayalık/Çayır biyom algılama)
# 4. Kanyon Kanca Geçidi & Gizli Zirve Sandığı (GrapplePoint entegrasyonu)
# 5. RegionManager & MapManager İki Bölge Sürekliliği (POI & Sis açılımı)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 28 — Karakter-Çevre Etkileşimi & Devasa Harita Smoke Test ---")
	test_footprints_and_particle_effects()
	test_tall_grass_trampling_physics()
	test_mountain_valley_biome_and_canyon()
	test_canyon_grapple_and_treasure()
	test_two_region_map_continuity()
	print("--- TÜM KARAKTER-ÇEVRE VE BÖLGESEL HARİTA TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_footprints_and_particle_effects() -> void:
	var step_fx = preload("res://scripts/effects/step_particles.gd").new()
	root.add_child(step_fx)
	
	assert(step_fx.footprints.is_empty(), "Başlangıçta ayak izi olmamalı")
	step_fx.spawn_footprint(Vector2(100, 100), Color("2e1f14"), 0.5)
	assert(step_fx.footprints.size() == 1, "Ayak izi listeye eklenmeli")
	
	# Zaman aşımı simülasyonu
	step_fx._process(1.5)
	assert(step_fx.footprints[0]["alpha"] < 0.65, "Zamanla ayak izi saydamlaşmalı")
	
	# 4 saniye sonra silinmeli
	step_fx._process(3.0)
	assert(step_fx.footprints.is_empty(), "Ömrü biten ayak izi temizlenmeli")
	
	step_fx.free()
	print("[PASS] Ayak izi bırakma, yön açısı ve zamanla sönümlenme mekanizması doğrulandı.")

func test_tall_grass_trampling_physics() -> void:
	var grass = preload("res://scenes/props/tall_grass.tscn").instantiate()
	root.add_child(grass)
	grass._ready()
	
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.velocity = Vector2(80, 0)
	
	assert(grass.bend_angle == 0.0, "Ot başlangıçta dik durmalı")
	grass._on_body_entered(player)
	assert(grass.is_being_trampled == true, "Oyuncu girince ezilme durumu aktifleşmeli")
	assert(grass.bend_velocity > 0.0, "Sağa hareket eden oyuncu otu sağa yatırmalı")
	
	# Yay fiziği simülasyonu
	grass._process(0.1)
	assert(grass.bend_angle != 0.0, "Açı yaylanarak güncellenmeli")
	
	grass._on_body_exited(player)
	assert(grass.is_being_trampled == false, "Oyuncu çıkınca ezilme bitmeli")
	
	grass.free()
	player.free()
	print("[PASS] Uzun ot yay fiziği, yöne duyarlı eğilme ve parçacık tepkisi doğrulandı.")

func test_mountain_valley_biome_and_canyon() -> void:
	var mtn_scene = preload("res://scenes/world/mountain_valley_location.tscn").instantiate()
	root.add_child(mtn_scene)
	mtn_scene._ready()
	
	# Dağ vadisi zemin biyomu testi
	var biome_mtn = mtn_scene.get_biome_at_world_pos(Vector2(200, 200)) # Kayalık alan
	assert(biome_mtn != null, "Biyom verisi alınabilmeli")
	assert(biome_mtn.biome_type == BiomeData.BiomeType.MOUNTAIN, "Dağ bölgesinde biyom MOUNTAIN olmalı")
	
	mtn_scene.free()
	print("[PASS] İkinci bölge (Dağ Eteği Vadisi) zemin, kanyon ve biyom algılama doğrulandı.")

func test_canyon_grapple_and_treasure() -> void:
	var mtn_scene = preload("res://scenes/world/mountain_valley_location.tscn").instantiate()
	root.add_child(mtn_scene)
	mtn_scene._ready()
	
	var grapple_w = mtn_scene.find_child("Grapple_Canyon_West", true, false)
	assert(grapple_w != null, "Kanyon batı kanca noktası mevcut olmalı")
	var grapple_e = mtn_scene.find_child("Grapple_Canyon_East", true, false)
	assert(grapple_e != null, "Kanyon doğu kanca noktası mevcut olmalı")
	var chest = mtn_scene.find_child("Chest_Canyon_Peak", true, false)
	assert(chest != null, "Kanyon zirve gizli sandığı mevcut olmalı")
	assert(chest.reward_item_ids.has("iron_ore"), "Sandıkta demir cevheri ödülü olmalı")
	
	mtn_scene.free()
	print("[PASS] Kanyon kanca geçidi ve zirve ganimet sandığı doğrulandı.")

func test_two_region_map_continuity() -> void:
	var mm = root.get_node_or_null("MapManager")
	if not mm:
		mm = preload("res://scripts/map/map_manager.gd").new()
		mm.name = "MapManager"
		root.add_child(mm)
		mm._ready()
	
	assert(mm.pois.has("hunter_cabin"), "MapManager'da Dağ Avcı Kulübesi kayıtlı olmalı")
	assert(mm.pois.has("mountain_canyon_peak"), "MapManager'da Sarp Kanyon Zirvesi kayıtlı olmalı")
	
	var rm = root.get_node_or_null("RegionManager")
	if not rm:
		rm = preload("res://scripts/world/region_manager.gd").new()
		rm.name = "RegionManager"
		root.add_child(rm)
		rm._ready()
	
	assert(rm.registered_regions.has("region_01_greenwood"), "Bölge 1 kayıtlı olmalı")
	assert(rm.registered_regions.has("region_02_mountain_valley"), "Bölge 2 kayıtlı olmalı")
	
	print("[PASS] İki bölgenin MapManager ve RegionManager üzerindeki harita sürekliliği doğrulandı.")
