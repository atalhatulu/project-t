@tool
extends StaticBody2D

# Project T - Gizli Mağara Girişi (Cave Entrance)
# E tuşu ile oyuncunun inceleyebileceği etkileşim alanı ve meşale askısı

@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	queue_redraw()

func _draw() -> void:
	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(0, 10), 38.0, 14.0, Color(0, 0, 0, 0.45))

	# 2. Kaya Duvarı (Mağara çerçevesi)
	var rock_frame = PackedVector2Array([
		Vector2(-42, 6), Vector2(-36, -26), Vector2(-18, -42),
		Vector2(18, -42), Vector2(36, -26), Vector2(42, 6),
		Vector2(32, 8), Vector2(16, -26), Vector2(-16, -26), Vector2(-32, 8)
	])
	draw_colored_polygon(rock_frame, Color("374151"))

	# Kaya aydınlık üst yüzeyi
	var raw_points = PackedVector2Array([
		Vector2(-36, -26), Vector2(-18, -42), Vector2(18, -42),
		Vector2(36, -26), Vector2(0, -46)
	])
	var rock_top = Geometry2D.convex_hull(raw_points)
	draw_colored_polygon(rock_top, Color("57606f"))

	# 3. Zifiri Karanlık Mağara Ağzı
	var cave_mouth = PackedVector2Array([
		Vector2(-24, 6), Vector2(-20, -18), Vector2(0, -28),
		Vector2(20, -18), Vector2(24, 6)
	])
	draw_colored_polygon(cave_mouth, Color("0b0f14"))

	# 4. Ahşap Destek Kirişleri
	draw_rect(Rect2(-24, -22, 6, 28), Color("4a3319"))
	draw_rect(Rect2(18, -22, 6, 28), Color("4a3319"))
	draw_rect(Rect2(-26, -26, 52, 6), Color("5c4028"))

	# 5. Yosun Detayları
	draw_circle(Vector2(-28, -8), 4.0, Color("2d5a27"))
	draw_circle(Vector2(30, -12), 5.0, Color("2d5a27"))
	draw_circle(Vector2(4, -36), 3.5, Color("3e7b35"))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)

# Mağara kapısı etkileşim diyalog metni
func get_interaction_text() -> String:
	return "Mağaranın derinliklerinden gelen soğuk ve kadim bir esinti yüzüne çarpıyor. İçerisi zifiri karanlık; meşalesiz ve hazırlıksız girmek intihar olur."
