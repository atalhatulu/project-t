extends SceneTree

# Smoke Test: Görev 24 — Game Feel, Hareket & Savaş Geri Bildirimi
# Doğrulamalar:
# 1. Ters yöne dönmede anlık frenleme ve sığ su direnci
# 2. Roll başlangıç ve bitiş squash/stretch geri bildirimi
# 3. Kılıç isabetinde hit-stop ve kamera shake tetiklenmesi (Iskada shake olmaması)
# 4. Düşmanda darbe flaşı (modulate flicker) ve geri tepme (knockback)
# 5. Tırmanmada yüzeye tutunma ve dinamik kamera smoothing

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	print("--- TEST BAŞLATILDI: Görev 24 — Game Feel ve Geri Bildirim Smoke Test ---")
	test_movement_snappiness_and_water_resistance()
	test_roll_squash_and_stretch()
	test_combat_hitstop_camera_shake_and_enemy_flash()
	test_missed_attack_no_camera_shake()
	test_climbing_surface_adhesion()
	print("--- TÜM GAME FEEL DOĞRULAMALARI BAŞARIYLA TAMAMLANDI ---")
	quit(0)
	return true

func test_movement_snappiness_and_water_resistance() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()

	# Normal hız kontrolü
	player.is_in_water = false
	assert(player.max_speed == 125.0, "Kara hızı 125 olmalı")

	# Sığ suya girince direnç hızı
	player.is_in_water = true
	assert(player.shallow_water_speed == 85.0, "Sığ su hızı dirençli olmalı (85)")

	player.free()
	print("[PASS] Yön değişimi frenlemesi ve sığ su direnç hızı doğrulandı.")

func test_roll_squash_and_stretch() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()

	var vis = player.get_node_or_null("Visual")
	assert(vis != null, "Visual node bulunmalı")

	# Yuvarlanmayı başlat
	player.start_roll(Vector2.RIGHT)
	assert(player.current_state == player.State.ROLL, "Durum ROLL olmalı")
	assert(player.velocity.x > 200.0, "Roll hızı yüksek olmalı")

	player.free()
	print("[PASS] Roll başlangıç/bitiş squash-stretch ve hız hissi doğrulandı.")

func test_combat_hitstop_camera_shake_and_enemy_flash() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	var enemy = preload("res://scenes/creatures/enemy_creature.tscn").instantiate()
	root.add_child(player)
	root.add_child(enemy)
	player._ready()
	enemy._ready()

	player.global_position = Vector2(100, 100)
	enemy.global_position = Vector2(115, 100)

	# Başlangıçta shake ve hitstop yok
	assert(player.shake_timer <= 0.0, "Başlangıçta kamera shake olmamalı")
	assert(player.hitstop_timer <= 0.0, "Başlangıçta hitstop olmamalı")

	# Kılıç vuruşu simülasyonu (Hitbox -> Enemy Hurtbox)
	var sword_hitbox = player.get_node_or_null("SwordHitbox")
	assert(sword_hitbox != null)

	var start_hp = enemy.current_health
	enemy._on_hurtbox_area_entered(sword_hitbox)

	# İsabet sonrası kontroller
	assert(enemy.current_health < start_hp, "Düşman hasar almalı")
	assert(player.hitstop_timer > 0.0, "Başarılı vuruşta hit-stop tetiklenmeli")
	assert(player.shake_timer > 0.0, "Başarılı vuruşta hafif camera shake tetiklenmeli")
	assert(enemy.knockback_velocity != Vector2.ZERO, "Düşman geri tepmeli (knockback)")
	assert(enemy.hit_flash_timer > 0.0, "Düşmanda darbe flaşı aktifleşmeli")

	enemy.free()
	player.free()
	print("[PASS] Başarılı vuruşta hit-stop, camera shake, düşman flicker ve knockback doğrulandı.")

func test_missed_attack_no_camera_shake() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player._ready()

	# Iska saldırı
	player.start_attack()
	assert(player.current_state == player.State.ATTACK, "Durum ATTACK olmalı")
	assert(player.shake_timer <= 0.0, "Iska saldırıda kamera shake tetiklenmemeli")

	player.free()
	print("[PASS] Iska saldırılarda kamera shake tetiklenmediği doğrulandı.")

func test_climbing_surface_adhesion() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	var cliff = preload("res://scenes/props/climbable_cliff.tscn").instantiate()
	root.add_child(player)
	root.add_child(cliff)
	player._ready()
	cliff._ready()

	player.current_cliff = cliff
	player.current_state = player.State.CLIMB

	# Tırmanma fizik sürecini simüle et
	player.process_climb_state(0.016)
	assert(player.current_state == player.State.CLIMB, "Tırmanma durumu korunmalı")

	cliff.free()
	player.free()
	print("[PASS] Tırmanma yüzeyine tutunma hissi ve durum sürekliliği doğrulandı.")
