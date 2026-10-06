@tool
extends Node2D
class_name DungeonCaveRoom

# Project T - Birbirine Bağlı Mağara / Zindan Odası ve Koridor Çizimi
# 3/4 Perspektif karanlık mağara duvarları, sarkıtlar, geçitler ve zemin dokusu

@export var room_shape: String = "seven_chambers"

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# 1. Zifiri Karanlık Mağara Boşluğu
	draw_rect(Rect2(-800, -700, 1600, 1300), Color("06080b"))

	# 2. Mağara Odaları Zeminleri (Taş/Kaya Zemin)
	var col_floor = Color("1e232a")
	var col_corridor = Color("171b21")
	var col_chasm = Color("0a0d12")
	var col_wall = Color("2d343f")
	var col_wall_top = Color("3f4857")
	var col_boss_floor = Color("231c28")

	# Oda 1: Giriş Salonu (0, 150)
	draw_circle(Vector2(0, 150), 75.0, col_floor)

	# Koridor 1 -> 2: Tuzak Koridoru (0, 70 -> 0, -20)
	draw_rect(Rect2(-24, -30, 48, 120), col_corridor)

	# Oda 2: Tuzak ve Diken Geçidi (0, -60)
	draw_circle(Vector2(0, -60), 70.0, col_floor)

	# Koridor 2 -> 3: Batı Bulmaca Geçidi (-40, -60 -> -160, -60)
	draw_rect(Rect2(-170, -75, 140, 32), col_corridor)

	# Oda 3: Ağırlık Plakası & Kaya Bulmaca Odası (-230, -60)
	draw_circle(Vector2(-230, -60), 80.0, col_floor)

	# Koridor 2 -> 4: Doğu Zehirli Uçurum Geçidi (40, -60 -> 160, -60)
	draw_rect(Rect2(40, -75, 140, 32), col_corridor)

	# Oda 4: Zehirli Sis & Kanca Uçurumu Odası (230, -60)
	draw_circle(Vector2(230, -60), 85.0, col_floor)
	# Ortadaki dipsiz uçurum/zehir çukuru
	draw_circle(Vector2(230, -60), 38.0, col_chasm)

	# Koridor 4 -> 5: Gizli Doğu Geçidi (Kırılabilir Duvar Arkası) (290, -60 -> 390, -60)
	draw_rect(Rect2(290, -75, 100, 30), col_corridor)

	# Oda 5: Gizli Hazine Odası (440, -60)
	draw_circle(Vector2(440, -60), 65.0, col_floor)

	# Koridor 2 -> 6: Kuzey Boss Önü Kapı Koridoru (-25, -170 -> 25, -120)
	draw_rect(Rect2(-25, -200, 50, 90), col_corridor)

	# Oda 6: Kadim Trol Boss Arenası (0, -320)
	draw_circle(Vector2(0, -320), 125.0, col_boss_floor)

	# Koridor 6 -> 7: Kadim Mabet / Ödül Odası Geçidi (-22, -490 -> 22, -430)
	draw_rect(Rect2(-22, -480, 44, 60), col_corridor)

	# Oda 7: İç Mabet & Kanca Ödül Odası (0, -540)
	draw_circle(Vector2(0, -540), 75.0, col_floor)

	# 3. Mağara Duvar Çerçeveleri
	draw_arc(Vector2(0, 150), 76.0, PI * 0.4, PI * 1.6, 24, col_wall, 6.0)
	draw_arc(Vector2(-230, -60), 81.0, -PI * 0.7, PI * 0.7, 26, col_wall, 7.0)
	draw_arc(Vector2(230, -60), 86.0, PI * 0.2, PI * 0.8, 20, col_wall, 6.0)
	draw_arc(Vector2(440, -60), 66.0, -PI * 0.4, PI * 0.8, 20, col_wall, 7.0)
	draw_arc(Vector2(0, -320), 126.0, 0, TAU, 36, col_wall, 8.0)
	draw_arc(Vector2(0, -540), 76.0, -PI * 0.8, PI * 0.8, 24, col_wall, 7.0)

	# Zemin Çakılları ve Mağara Detayları
	for i in range(24):
		var p1 = Vector2(sin(i * 1.7) * 50.0, cos(i * 2.3) * 40.0)
		draw_circle(Vector2(0, 150) + p1, 2.0, Color("111418"))
		draw_circle(Vector2(0, -320) + p1 * 1.8, 2.5, Color("1a1420"))
		draw_circle(Vector2(-230, -60) + p1 * 0.9, 1.8, Color("111418"))
		draw_circle(Vector2(230, -60) + p1 * 0.9, 2.0, Color("111418"))
