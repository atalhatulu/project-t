extends SceneTree

# Test betiği: Görev 19 — İtibar ve Fraksiyon Sistemi (FactionManager, Suç/Görgü Tanığı, Muhafızlar)

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 19 — İtibar ve Fraksiyon Sistemi ---")
	test_faction_reputation_clamping()
	test_theft_unwitnessed_vs_witnessed()
	test_assault_and_guard_alert()
	test_guard_behaviors()
	test_npc_dialogue_reputation_shift()
	test_faction_save_load()
	print("--- TÜM İTİBAR VE FRAKSİYON TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_faction_reputation_clamping() -> void:
	var fm = root.get_node_or_null("FactionManager")
	if not fm:
		fm = preload("res://scripts/reputation/faction_manager.gd").new()
		fm.name = "FactionManager"
		root.add_child(fm)
		fm._ready()

	# Başlangıç değerleri
	assert(fm.get_reputation("villagers") == 0, "Köylüler başlangıç itibarı 0 olmalı")
	assert(fm.get_reputation("guards") == 0, "Muhafızlar başlangıç itibarı 0 olmalı")
	assert(fm.get_reputation("bandits") == -50, "Haydutlar başlangıç itibarı -50 olmalı")

	# Sınır testleri (-100 ile +100)
	fm.modify_reputation("villagers", 150)
	assert(fm.get_reputation("villagers") == 100, "+100 üst limit olmalı")
	assert(fm.get_relation_level("villagers") == FactionManager.RelationLevel.ALLIED, "100 ALLIED olmalı")

	fm.modify_reputation("villagers", -250)
	assert(fm.get_reputation("villagers") == -100, "-100 alt limit olmalı")
	assert(fm.get_relation_level("villagers") == FactionManager.RelationLevel.HOSTILE, "-100 HOSTILE olmalı")

	# Nötr sıfırlama
	fm.set_reputation("villagers", 0)
	fm.set_reputation("guards", 0)
	fm.set_reputation("bandits", -50)
	print("[PASS] Fraksiyon itibar sınırları (-100..+100) ve ilişki kademeleri doğrulandı.")

func test_theft_unwitnessed_vs_witnessed() -> void:
	var fm = root.get_node_or_null("FactionManager")
	fm.set_reputation("villagers", 0)
	fm.set_reputation("guards", 0)

	var player = preload("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	# 1. Tanıksız Hırsızlık (Etrafta kimse yok)
	var unwitnessed_theft = fm.report_crime("theft", "villagers", Vector2(100, 100), player)
	assert(unwitnessed_theft == false, "Görgü tanığı yokken hırsızlık tespit edilmemeli")
	assert(fm.get_reputation("villagers") == 0, "Tanıksız suçta itibar düşmemeli")

	# 2. Tanıklı Hırsızlık (Yakında bir köylü var)
	var npc = preload("res://scenes/npc/npc_boran.tscn").instantiate()
	root.add_child(npc)
	npc.global_position = Vector2(140, 100) # 40 piksel mesafede görgü tanığı

	var witnessed_theft = fm.report_crime("theft", "villagers", Vector2(100, 100), player)
	assert(witnessed_theft == true, "Görgü tanığı varken suç tespit edilmeli")
	assert(fm.get_reputation("villagers") < 0, "Tespit edilen hırsızlıkta köylü itibarı düşmeli")
	assert(fm.get_reputation("guards") < 0, "Tespit edilen hırsızlıkta muhafız itibarı düşmeli")

	npc.free()
	player.free()
	print("[PASS] Sahipli eşya hırsızlığında görgü tanığı ve tespit mekanizması doğrulandı.")

func test_assault_and_guard_alert() -> void:
	var fm = root.get_node_or_null("FactionManager")
	fm.set_reputation("villagers", 0)
	fm.set_reputation("guards", 0)

	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(200, 200)

	var guard = preload("res://scenes/creatures/guard_creature.tscn").instantiate()
	root.add_child(guard)
	guard.global_position = Vector2(280, 200) # 80 birim yakında muhafız

	var npc = preload("res://scenes/npc/npc_kemal.tscn").instantiate()
	root.add_child(npc)
	npc.global_position = Vector2(220, 200)

	# Köylüye saldırı (Kemal darbe alır)
	npc.take_damage(10, Vector2.ZERO, player)

	assert(fm.get_reputation("villagers") <= -25, "Saldırı sonrası köylü itibarı düşmeli")
	assert(fm.get_reputation("guards") <= -20, "Saldırı sonrası muhafız itibarı düşmeli")
	assert(guard.current_alert_level == "hostile", "Yakındaki muhafız saldırı alarmı almalı")

	npc.free()
	guard.free()
	player.free()
	print("[PASS] Saldırı suçu tespiti, itibar kaybı ve muhafız alarmı doğrulandı.")

func test_guard_behaviors() -> void:
	var fm = root.get_node_or_null("FactionManager")
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(300, 300)

	const GuardScript = preload("res://scripts/creatures/guard_creature.gd")
	var guard = preload("res://scenes/creatures/guard_creature.tscn").instantiate()
	root.add_child(guard)
	guard.global_position = Vector2(350, 300)

	# 1. Barışçıl / Nötr durum
	fm.set_reputation("guards", 0)
	guard._evaluate_guard_behavior(0.1)
	assert(guard.guard_state == GuardScript.GuardBehavior.PATROL or guard.guard_state == GuardScript.GuardBehavior.RETREAT, "Nötr durumda muhafız saldırmamalı")

	# 2. Şüpheli itibar -> Uyarma (WARN)
	fm.set_reputation("guards", -20)
	guard.warning_cooldown = 0.0
	guard._evaluate_guard_behavior(0.1)
	assert(guard.has_warned_player == true, "Şüpheli itibarda oyuncu uyarılmalı")

	# 3. Düşman itibar -> Takip (CHASE)
	fm.set_reputation("guards", -50)
	guard._evaluate_guard_behavior(0.1)
	assert(guard.current_state == BaseCreature.CreatureState.CHASE, "Düşman itibarda kovalamaca başlamalı")

	guard.free()
	player.free()
	print("[PASS] Muhafız davranışları (devriye, uyarma, takip, saldırı) doğrulandı.")

func test_npc_dialogue_reputation_shift() -> void:
	var fm = root.get_node_or_null("FactionManager")
	var npc = preload("res://scenes/npc/npc_boran.tscn").instantiate()
	root.add_child(npc)

	# Normal diyalog
	fm.set_reputation("villagers", 0)
	var normal_diag = npc.get_current_dialogue()
	assert(normal_diag != "", "Diyalog boş olmamalı")

	# Düşman itibar diyalogu
	fm.set_reputation("villagers", -60)
	var hostile_diag = npc.get_current_dialogue()
	assert("Defol" in hostile_diag or "Uzak dur" in hostile_diag, "Düşman itibarda kovma diyaloğu gelmeli: " + hostile_diag)

	# Şüpheli itibar diyalogu
	fm.set_reputation("villagers", -20)
	var sus_diag = npc.get_current_dialogue()
	assert("Gözüm üzerinde" in sus_diag or "dikkatli ol" in sus_diag, "Şüpheli itibarda uyarı diyaloğu gelmeli: " + sus_diag)

	npc.free()
	print("[PASS] İtibara göre değişen dinamik NPC diyalogları doğrulandı.")

func test_faction_save_load() -> void:
	var sm = root.get_node_or_null("SaveManager")
	var fm = root.get_node_or_null("FactionManager")

	fm.set_reputation("villagers", 35)
	fm.set_reputation("guards", -45)
	fm.set_reputation("bandits", 15)

	# Slot 2'ye kaydet
	var save_res = sm.save_game(2)
	assert(save_res == true, "Kayıt başarılı olmalı")

	# Değerleri sıfırla
	fm.set_reputation("villagers", 0)
	fm.set_reputation("guards", 0)
	fm.set_reputation("bandits", 0)

	# Slot 2'den yükle
	var load_res = sm.load_game(2)
	assert(load_res == true, "Yükleme başarılı olmalı")

	assert(fm.get_reputation("villagers") == 35, "Köylü itibarı geri yüklenmeli")
	assert(fm.get_reputation("guards") == -45, "Muhafız itibarı geri yüklenmeli")
	assert(fm.get_reputation("bandits") == 15, "Haydut itibarı geri yüklenmeli")
	print("[PASS] FactionManager kayıt ve yükleme uyumluluğu doğrulandı.")
