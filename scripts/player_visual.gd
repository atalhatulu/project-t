@tool
extends Node2D

# Project T - 3/4 Perspektif Anatomik Savaşçı Görseli (Placeholder Sprite)
# Kliff / Arthur Morgan oranlarında: 1:6 kafa-vücut oranı, kürk yelek, pelerin ve kılıç kını

var walk_cycle: float = 0.0

func _process(delta: float) -> void:
	var parent_body = get_parent() as CharacterBody2D
	if parent_body and parent_body.velocity.length() > 5.0:
		walk_cycle += delta * 12.0
		queue_redraw()
	elif walk_cycle != 0.0:
		walk_cycle = 0.0
		queue_redraw()

func _draw() -> void:
	var leg_offset = sin(walk_cycle) * 2.5
	var body_bob = abs(sin(walk_cycle)) * 1.0

	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(0, 14), 10.0, 4.0, Color(0, 0, 0, 0.4))

	# 2. Pelerin (Arkada dalgalanan kumaş)
	var cape_pts = PackedVector2Array([
		Vector2(-7, -4 - body_bob),
		Vector2(7, -4 - body_bob),
		Vector2(9 + sin(walk_cycle * 0.8) * 2.0, 10),
		Vector2(-9 + sin(walk_cycle * 0.8) * 2.0, 10)
	])
	draw_colored_polygon(cape_pts, Color("3b1d11"))

	# 3. Bacaklar ve Deri Çizmeler (Orantılı uzunluk)
	draw_rect(Rect2(-5, 4 - leg_offset, 4, 10), Color("181412"))
	draw_rect(Rect2(1, 4 + leg_offset, 4, 10), Color("181412"))

	# 4. Gövde (Deri Zırh / Yelek - Geniş omuzlar)
	draw_rect(Rect2(-7, -8 - body_bob, 14, 12), Color("4a2b13"))

	# 5. Omuz Kürkleri
	draw_circle(Vector2(-7, -8 - body_bob), 3.0, Color("6b3f19"))
	draw_circle(Vector2(7, -8 - body_bob), 3.0, Color("6b3f19"))

	# 6. Sırttaki Kılıç Kabzası
	draw_line(Vector2(5, -14 - body_bob), Vector2(7, -4 - body_bob), Color("94a3b8"), 2.0)

	# 7. Kafa (Orantılı 1:6 oranında)
	draw_circle(Vector2(0, -12 - body_bob), 4.0, Color("d4a373"))
	# Saç / Sakal
	draw_rect(Rect2(-4, -16 - body_bob, 8, 4), Color("2b1810"))
	draw_rect(Rect2(-3, -11 - body_bob, 6, 2), Color("2b1810"))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(12):
		var rad = (float(i) / 12.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
