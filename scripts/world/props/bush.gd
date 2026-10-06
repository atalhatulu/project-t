@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Organik Pixel Art Çalı Nesnesi
# Kümeleme (leaf clusters), yaprak gölgeleri, rüzgar dalgalanması ve kır çiçekleri

@export var bush_color: Color = Color("2e5a27")
@export var flower_color: Color = Color("f1c40f")
@export var has_flowers: bool = true

var wind_time: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	wind_time = randf() * 50.0
	queue_redraw()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		wind_time += delta * 2.8
		queue_redraw()

func _draw() -> void:
	var wind_sway = sin(wind_time) * 1.2 if not Engine.is_editor_hint() else 0.0

	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(0, 4), 11.0, 5.0, Color(0, 0, 0, 0.35))

	var col_deep = bush_color.darkened(0.4)
	var col_dark = bush_color.darkened(0.18)
	var col_mid = bush_color
	var col_light = bush_color.lightened(0.22)
	var col_high = bush_color.lightened(0.4)

	# 2. Alt Koyu Yaprak Kümeleri
	draw_circle(Vector2(-6 + wind_sway * 0.3, -2), 6.5, col_deep)
	draw_circle(Vector2(6 + wind_sway * 0.5, -2), 7.0, col_dark)

	# 3. Ana Gövde Kümeleri
	draw_circle(Vector2(-4 + wind_sway * 0.6, -5), 7.5, col_mid)
	draw_circle(Vector2(4 + wind_sway * 0.8, -6), 8.0, col_mid)
	draw_circle(Vector2(wind_sway * 0.7, -8), 8.5, col_light)

	# 4. Sol-Üst Güneş Alan Piksel Vurguları (Işık sol-üstten vurur)
	draw_circle(Vector2(-3 + wind_sway * 0.9, -10), 4.5, col_high)
	draw_circle(Vector2(3 + wind_sway * 1.0, -11), 3.5, col_high)

	# 5. Kır Çiçekleri (Belirgin piksel taçyaprakları)
	if has_flowers:
		_draw_flower_dot(Vector2(-4 + wind_sway * 0.8, -7), flower_color)
		_draw_flower_dot(Vector2(5 + wind_sway * 0.9, -8), flower_color)
		_draw_flower_dot(Vector2(0 + wind_sway * 0.6, -4), Color("ffffff"))

func _draw_flower_dot(pos: Vector2, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(2, 2)), col)
	draw_rect(Rect2(pos + Vector2(1, 0), Vector2(1, 1)), col.lightened(0.4))

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(12):
		var rad = (float(i) / 12.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
