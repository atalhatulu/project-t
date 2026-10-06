@tool
extends Node2D

# Project T - Prosedürel 3/4 Perspektif Savaşçı Görseli ve Placeholder Animasyon Sistemi
# Durumlar: IDLE, WALK, ROLL, ATTACK, SWIM, CLIMB, HURT, DEATH
# 4 Yönlü Pozlar: UP, DOWN, LEFT, RIGHT
# Nefes alma (idle breathing), gövde bobbing (walk), kılıç savurma (attack), kulaç (swim),
# duvara tutunma (climb), sarsılma/flicker (hurt), yere çökme/düşme (death)

var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var player = get_parent() as CharacterBody2D
	if not player:
		_draw_default_idle(Vector2.DOWN)
		return

	var facing: Vector2 = Vector2.DOWN
	if "facing_direction" in player and player.facing_direction != Vector2.ZERO:
		facing = player.facing_direction

	var state = player.get("current_state")
	var is_moving = player.velocity.length() > 5.0

	# 1. Ölüm Durumu (DEATH)
	if state == player.State.DEAD:
		_draw_death_pose(facing)
		return

	# 2. Hasar Alma Durumu (HURT)
	if state == player.State.HURT:
		_draw_hurt_pose(facing)
		return

	# 3. Yüzme Durumu (SWIM)
	if state == player.State.SWIM:
		_draw_swim_pose(facing, is_moving)
		return

	# 4. Tırmanma Durumu (CLIMB)
	if state == player.State.CLIMB:
		_draw_climb_pose(is_moving)
		return

	# 5. Yuvarlanma Durumu (ROLL)
	if state == player.State.ROLL:
		_draw_roll_pose(facing)
		return

	# 6. Saldırı Durumu (ATTACK)
	if state == player.State.ATTACK:
		_draw_attack_pose(facing)
		return

	# 7. Yürüme Durumu (WALK)
	if state == player.State.MOVE or (is_moving and state != player.State.INVENTORY and state != player.State.TALKING):
		_draw_walk_pose(facing)
		return

	# 8. Boşta Bekleme (IDLE)
	_draw_idle_pose(facing)

# --- 1. IDLE (Hafif Nefes Hareketi) ---
func _draw_idle_pose(facing: Vector2) -> void:
	var breath_bob = sin(anim_time * 3.5) * 0.75
	_draw_oval_shadow(Vector2(0, 14), 10.0, 4.0, Color(0, 0, 0, 0.35))
	_draw_character_body(facing, 0.0, breath_bob, false, Vector2.ZERO)

# --- 2. WALK (Gövde Bobbing ve Adım Ritmi) ---
func _draw_walk_pose(facing: Vector2) -> void:
	var step_cycle = anim_time * 12.0
	var leg_offset = sin(step_cycle) * 3.0
	var body_bob = abs(sin(step_cycle)) * 1.5
	_draw_oval_shadow(Vector2(0, 14), 10.0, 4.0, Color(0, 0, 0, 0.4))
	_draw_character_body(facing, leg_offset, body_bob, true, Vector2.ZERO)

# --- 3. ROLL (Küreye Yakın Hızlı Dönüş / Squash-Stretch Destekli) ---
func _draw_roll_pose(facing: Vector2) -> void:
	_draw_oval_shadow(Vector2(0, 10), 12.0, 5.0, Color(0, 0, 0, 0.45))
	var spin = sin(anim_time * 24.0) * 3.0
	# Kıvrılmış pelerin ve gövde küresi
	draw_circle(Vector2(0, 4), 8.5, Color("3b1d11"))
	draw_circle(Vector2(spin, 2), 6.5, Color("4a2b13"))
	draw_circle(Vector2(facing.x * 4, 0), 4.0, Color("d4a373"))

# --- 4. ATTACK (Yöne Göre Kılıç Savurma Pozi) ---
func _draw_attack_pose(facing: Vector2) -> void:
	_draw_oval_shadow(Vector2(0, 14), 11.0, 4.5, Color(0, 0, 0, 0.4))
	# Kılıç savurma ofseti
	var slash_offset = facing * 12.0
	_draw_character_body(facing, 0.0, -1.0, false, slash_offset)

	# Savrulan Kılıç Bıçağı
	var blade_start = Vector2(0, 0)
	var blade_end = blade_start + facing * 18.0
	var blade_side = Vector2(-facing.y, facing.x) * 8.0
	draw_line(blade_start + blade_side * 0.5, blade_end, Color("e2e8f0"), 2.5)
	# Işıltı yayı
	draw_arc(blade_start + facing * 8.0, 10.0, facing.angle() - 0.7, facing.angle() + 0.7, 8, Color(1, 1, 1, 0.75), 1.5)

# --- 5. SWIM (Kulaç ve Su Üstü Hareketi) ---
func _draw_swim_pose(_facing: Vector2, is_moving: bool) -> void:
	var swim_speed_mult = 8.0 if is_moving else 3.0
	var swim_cycle = anim_time * swim_speed_mult
	var ripple_scale = 1.0 + sin(swim_cycle * 0.6) * 0.25

	# Su dalgası ve köpük halkaları
	draw_arc(Vector2(0, 4), 10.0 * ripple_scale, 0, TAU, 16, Color("4ca1a3", 0.75), 1.5)
	draw_arc(Vector2(0, 4), 6.0 * ripple_scale, 0, TAU, 12, Color("ffffff", 0.85), 1.0)

	# Üst Gövde
	draw_rect(Rect2(-6, -4, 12, 8), Color("4a2b13"))
	# Kulaç atan kollar
	var arm_x = sin(swim_cycle) * 5.0
	draw_rect(Rect2(-9 + arm_x, -2, 4, 4), Color("d4a373"))
	draw_rect(Rect2(5 - arm_x, -2, 4, 4), Color("d4a373"))
	# Kafa
	draw_circle(Vector2(0, -8), 4.0, Color("d4a373"))
	draw_rect(Rect2(-4, -12, 8, 4), Color("2b1810"))

# --- 6. CLIMB (Tutunma ve Dikey Çekiş Hissiyatı) ---
func _draw_climb_pose(is_moving: bool) -> void:
	var climb_cycle = anim_time * (10.0 if is_moving else 0.0)
	var climb_hand_offset = sin(climb_cycle) * 4.0

	# Sırttan görünüş (Duvarda tutunma)
	draw_rect(Rect2(-7, -8, 14, 14), Color("4a2b13"))
	draw_line(Vector2(-3, -12), Vector2(3, 4), Color("94a3b8"), 2.0)
	# Kollar
	draw_rect(Rect2(-8, -14 - climb_hand_offset, 4, 6), Color("d4a373"))
	draw_rect(Rect2(4, -14 + climb_hand_offset, 4, 6), Color("d4a373"))
	# Ayaklar
	draw_rect(Rect2(-6, 6 + climb_hand_offset, 4, 5), Color("181412"))
	draw_rect(Rect2(2, 6 - climb_hand_offset, 4, 5), Color("181412"))
	# Baş
	draw_circle(Vector2(0, -11), 4.0, Color("2b1810"))

# --- 7. HURT (Kısa Geri Tepme / Sarsılma) ---
func _draw_hurt_pose(facing: Vector2) -> void:
	var jitter = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	_draw_oval_shadow(Vector2(0, 14), 9.0, 3.5, Color(0, 0, 0, 0.35))
	# Geriye yaslanmış acı pozu
	_draw_character_body(facing, 0.0, -1.5, false, jitter - facing * 4.0)

# --- 8. DEATH (Yere Düşme / Çökme Pozi) ---
func _draw_death_pose(_facing: Vector2) -> void:
	_draw_oval_shadow(Vector2(0, 6), 14.0, 6.0, Color(0, 0, 0, 0.45))
	# Yere yatay devrilmiş karakter pozu
	draw_rect(Rect2(-12, 0, 24, 7), Color("3b1d11")) # Yere serilen pelerin
	draw_rect(Rect2(-8, -3, 16, 8), Color("4a2b13")) # Gövde
	draw_circle(Vector2(-10, 0), 4.0, Color("d4a373")) # Kafa
	draw_rect(Rect2(-13, -3, 5, 4), Color("2b1810")) # Saç
	draw_line(Vector2(0, 2), Vector2(10, 5), Color("94a3b8"), 2.0) # Yerde duran kılıç

# --- ORTAK GÖVDE ÇİZİMİ (Yön & Katmanlar) ---
func _draw_character_body(facing: Vector2, leg_offset: float, body_bob: float, is_walking: bool, extra_offset: Vector2) -> void:
	var is_facing_up = facing.y < -0.4
	var is_facing_horizontal = abs(facing.x) > 0.4
	var flip = -1.0 if facing.x < -0.2 else 1.0

	var root_pos = extra_offset

	# Pelerin
	var cape_wag = sin(anim_time * 8.0) * 2.0 if is_walking else 0.0
	var cape_pts = PackedVector2Array([
		root_pos + Vector2(-7 * flip, -4 - body_bob),
		root_pos + Vector2(7 * flip, -4 - body_bob),
		root_pos + Vector2((9 + cape_wag) * flip, 10),
		root_pos + Vector2((-9 + cape_wag) * flip, 10)
	])
	draw_colored_polygon(cape_pts, Color("2d140b"))
	draw_polyline(cape_pts, Color("1a0a05"), 1.0) # Koyu pelerin piksel konturu

	# Bacaklar ve Deri Çizmeler
	draw_rect(Rect2(root_pos.x - 5, root_pos.y + 3 - leg_offset, 4, 10), Color("181412"))
	draw_rect(Rect2(root_pos.x + 1, root_pos.y + 3 + leg_offset, 4, 10), Color("181412"))
	# Çizme ucu ve tokası
	draw_rect(Rect2(root_pos.x - 6, root_pos.y + 10 - leg_offset, 5, 3), Color("2f1f17"))
	draw_rect(Rect2(root_pos.x + 1, root_pos.y + 10 + leg_offset, 5, 3), Color("2f1f17"))
	draw_rect(Rect2(root_pos.x - 4, root_pos.y + 10 - leg_offset, 2, 1), Color("b45309")) # Altın toka

	# Gövde (Deri Zırh / Tunik)
	draw_rect(Rect2(root_pos.x - 7, root_pos.y - 8 - body_bob, 14, 12), Color("4a2b13"))
	draw_rect(Rect2(root_pos.x - 7, root_pos.y - 8 - body_bob, 14, 12), Color("261408"), false, 1.0) # Kontur

	# Kemer ve Demir Toka
	draw_rect(Rect2(root_pos.x - 7, root_pos.y + 1 - body_bob, 14, 3), Color("1c130d"))
	draw_rect(Rect2(root_pos.x - 2, root_pos.y + 1 - body_bob, 4, 3), Color("eab308")) # Altın kemer tokası
	draw_rect(Rect2(root_pos.x - 1, root_pos.y + 2 - body_bob, 2, 1), Color("713f12"))

	# Omuz Kürkleri
	draw_circle(root_pos + Vector2(-7, -8 - body_bob), 3.2, Color("573314"))
	draw_circle(root_pos + Vector2(7, -8 - body_bob), 3.2, Color("573314"))
	draw_circle(root_pos + Vector2(-7, -8 - body_bob), 2.0, Color("78481c"))
	draw_circle(root_pos + Vector2(7, -8 - body_bob), 2.0, Color("78481c"))

	# Sırt Kılıcı & Kın
	draw_line(root_pos + Vector2(5 * flip, -14 - body_bob), root_pos + Vector2(7 * flip, -3 - body_bob), Color("cbd5e1"), 2.0)
	draw_circle(root_pos + Vector2(4.5 * flip, -14.5 - body_bob), 1.5, Color("eab308")) # Kılıç kabzası

	# Kafa & Yüz Detayı (Yöne göre)
	var head_center = root_pos + Vector2(0, -12 - body_bob)
	# Ten
	draw_circle(head_center, 4.2, Color("d4a373"))

	if is_facing_up:
		# Arkadan görünüş: Saç tamamen kaplar
		draw_circle(head_center, 4.5, Color("2b1810"))
		draw_circle(head_center + Vector2(0, 1), 3.5, Color("1e100a"))
	else:
		# Önden veya yandan görünüş
		draw_rect(Rect2(head_center.x - 4, head_center.y - 5, 8, 4), Color("2b1810")) # Üst saç
		draw_line(head_center + Vector2(-4, -4), head_center + Vector2(-3, -1), Color("2b1810"), 1.5)
		draw_line(head_center + Vector2(4, -4), head_center + Vector2(3, -1), Color("2b1810"), 1.5)

		if not is_facing_horizontal:
			# Düz öne bakış: Gözler, kaşlar ve sakal
			draw_circle(head_center + Vector2(-1.5, 0), 0.9, Color("0f172a")) # Gözbebeği
			draw_circle(head_center + Vector2(1.5, 0), 0.9, Color("0f172a"))
			draw_rect(Rect2(head_center.x - 2, head_center.y + 2, 4, 2), Color("2b1810")) # Sakal
		else:
			# Yana bakış: Tek göz ve favori
			draw_circle(head_center + Vector2(2.0 * flip, 0), 0.9, Color("0f172a"))
			draw_rect(Rect2(head_center.x + (1.0 * flip), head_center.y + 2, 3, 2), Color("2b1810"))

func _draw_default_idle(facing: Vector2) -> void:
	_draw_idle_pose(facing)

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(12):
		var rad = (float(i) / 12.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
