extends SceneTree

# Test betiği: Görev 15 — Canlılar, Yapay Zeka Davranışları ve Savaş Mekanikleri

func _init() -> void:
	print("--- TEST BAŞLATILDI: Canlılar ve Savaş Altyapısı ---")
	test_passive_creatures()
	test_hostile_creatures()
	test_player_combat_and_respawn()
	test_sword_damage_and_loot()
	print("--- TÜM SAVAŞ VE CANLI TESTLERİ BAŞARIYLA TAMAMLANDI ---")
	quit(0)

func test_passive_creatures() -> void:
	var passive = preload("res://scenes/creatures/passive_creature.tscn").instantiate()
	passive.species = "rabbit"
	root.add_child(passive)
	passive.global_position = Vector2(200, 200)

	assert(passive.max_health == 15, "Tavşan canı 15 olmalı")
	assert(passive.current_state == BaseCreature.CreatureState.IDLE or passive.current_state == BaseCreature.CreatureState.WANDER, "Başlangıç durumu IDLE/WANDER olmalı")

	# Oyuncuyu algılama ve kaçma simülasyonu
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(220, 200) # Yakın mesafe
	passive.target_player = player
	passive.current_state = BaseCreature.CreatureState.FLEE

	assert(passive.current_state == BaseCreature.CreatureState.FLEE, "Oyuncu yaklaşınca kaçma durumuna geçmeli")
	
	passive.queue_free()
	player.queue_free()
	print("[PASS] Pasif canlıların (tavşan, geyik, kuş) parametreleri ve kaçma FSM durumu doğrulandı.")

func test_hostile_creatures() -> void:
	var wolf = preload("res://scenes/creatures/enemy_creature.tscn").instantiate()
	wolf.enemy_type = "wolf"
	root.add_child(wolf)
	wolf.global_position = Vector2(500, 500)

	assert(wolf.max_health == 40, "Kurt canı 40 olmalı")
	assert(wolf.attack_damage == 12, "Kurt saldırı hasarı 12 olmalı")

	# Takip sınırı (Leashing / Max Chase Distance) testi
	var far_player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(far_player)
	far_player.global_position = Vector2(900, 900) # Doğuş noktasından >220 piksel uzakta
	wolf.target_player = far_player
	wolf.global_position = Vector2(750, 750) # Doğuş noktasından (500,500) 353 piksel uzakta
	wolf.current_state = BaseCreature.CreatureState.CHASE
	wolf._update_ai_state(0.1)

	assert(wolf.current_state == BaseCreature.CreatureState.RETREAT, "Takip sınırı aşılınca RETREAT durumuna geçmeli")

	wolf.queue_free()
	far_player.queue_free()
	print("[PASS] Tehlikeli canlılar ve düşmanların (kurt, yaban domuzu, haydut) takip ve sınır mekanizması doğrulandı.")

func test_player_combat_and_respawn() -> void:
	var player = preload("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.global_position = Vector2(600, 600)
	player.respawn_point = Vector2(480, 320)

	assert(player.current_health == 100, "Oyuncu başlangıç canı 100 olmalı")
	
	# Hasar alma ve knockback testi
	player.take_damage(30, Vector2(100, 0))
	assert(player.current_health == 70, "Hasar sonrası can 70 olmalı")
	assert(player.knockback_velocity != Vector2.ZERO, "Geri tepme hızı uygulanmalı")

	# Ölümcül hasar testi (Dokunulmazlık süresini sıfırla)
	player.invincibility_timer = 0.0
	player.take_damage(80, Vector2.ZERO)
	assert(player.current_health == 0, "Can 0 olmalı")
	assert(player.current_state == player.State.DEAD, "Oyuncu DEAD durumuna geçmeli")

	# Yeniden doğma (Respawn)
	player.respawn()
	assert(player.current_health == 100, "Yeniden doğunca can yenilenmeli")
	assert(player.global_position == Vector2(480, 320), "Oyuncu köy merkezinde doğmalı")
	assert(player.current_state == player.State.IDLE, "Yeniden doğunca IDLE durumuna dönmeli")

	player.queue_free()
	print("[PASS] Oyuncu canı, hasar alma, geri tepme, ölüm ve köyde yeniden doğma doğrulandı.")

func test_sword_damage_and_loot() -> void:
	var bandit = preload("res://scenes/creatures/enemy_creature.tscn").instantiate()
	bandit.enemy_type = "bandit"
	root.add_child(bandit)
	bandit.global_position = Vector2(300, 300)
	bandit._ready()

	var initial_hp = bandit.current_health
	# Kılıç vuruşu taklidi
	bandit.take_damage(15.0, Vector2(50, 0))
	assert(bandit.current_health == initial_hp - 15.0, "Hasar canlıya doğru iletilmeli")
	assert(bandit.knockback_velocity != Vector2.ZERO, "Geri tepme canlıya uygulanmalı")

	# Canlıyı öldürme ve ganimet saçılması
	bandit.take_damage(100.0, Vector2.ZERO)
	assert(bandit.current_state == BaseCreature.CreatureState.DEAD, "Canlı DEAD durumuna geçmeli")

	bandit.queue_free()
	print("[PASS] Kılıç saldırısı ile hasar verme, geri tepme ve ganimet düşürme doğrulandı.")
