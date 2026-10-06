@tool
extends StaticBody2D

# Project T - Tepedeki Antik Gözetleme Kulesi (Watchtower)
# 3/4 Perspektif, taş kule gövdesi, ahşap çatı ve gözetleme balkonu

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	var tower_w = 40.0
	var tower_h = 70.0
	var hw = tower_w * 0.5

	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(6, 8), 26.0, 14.0, Color(0, 0, 0, 0.45))

	# 2. Taş Gövde
	draw_rect(Rect2(-hw, -tower_h, tower_w, tower_h), Color("4b5563"))
	# Taş gövde sol gölge / sağ aydınlık
	draw_rect(Rect2(-hw, -tower_h, 8, tower_h), Color("374151"))
	draw_rect(Rect2(hw - 8, -tower_h, 8, tower_h), Color("6b7280"))

	# 3. Kemerli Giriş Kapısı
	draw_rect(Rect2(-7, -18, 14, 18), Color("111827"))
	draw_circle(Vector2(0, -18), 7.0, Color("111827"))

	# 4. Gözetleme Mazgalları (Pencereler)
	draw_rect(Rect2(-3, -42, 6, 10), Color("1f2937"))
	draw_rect(Rect2(-3, -60, 6, 8), Color("1f2937"))

	# 5. Balkon ve Ahşap Siperlik
	draw_rect(Rect2(-hw - 4, -tower_h - 6, tower_w + 8, 8), Color("5c4033"))
	draw_rect(Rect2(-hw - 4, -tower_h - 14, tower_w + 8, 8), Color("3d2817"))

	# 6. Koni Çatı
	var roof_pts = PackedVector2Array([
		Vector2(-hw - 6, -tower_h - 14),
		Vector2(hw + 6, -tower_h - 14),
		Vector2(0, -tower_h - 38)
	])
	draw_colored_polygon(roof_pts, Color("7c2d12"))

	# Çatı saçak çizgisi
	draw_line(Vector2(-hw - 6, -tower_h - 14), Vector2(hw + 6, -tower_h - 14), Color("991b1b"), 2.0)

	# Tepe bayrak direği
	draw_line(Vector2(0, -tower_h - 38), Vector2(0, -tower_h - 48), Color("d1d5db"), 1.5)
	# Yırtık bayrak
	var flag_pts = PackedVector2Array([
		Vector2(0, -tower_h - 48),
		Vector2(10, -tower_h - 44),
		Vector2(0, -tower_h - 40)
	])
	draw_colored_polygon(flag_pts, Color("b91c1c"))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
