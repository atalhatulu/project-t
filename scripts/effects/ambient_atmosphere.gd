@tool
extends Node2D
class_name AmbientAtmosphere

# Project T - Atmosferik Çevre Parçacıkları & Işık Hüzmeleri (World of Anterra / Eastward Stili)
# Havada süzülen altın ışık zerrecikleri (dust motes / pollen),
# rüzgarla salınan orman polenleri ve hafif organik çevre derinliği.

@export var mote_count: int = 35
@export var area_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1920, 1280))
@export var base_color: Color = Color("fef08a") # Altın sarısı/amber polen ışıltısı
@export var wind_velocity: Vector2 = Vector2(18.0, 6.0)

var motes: Array[Dictionary] = []
var time_accum: float = 0.0

func _ready() -> void:
	z_index = 10 # Karakter ve yer seviyesinin hemen üstünde hafif süzülür
	_init_motes()
	queue_redraw()

func _init_motes() -> void:
	motes.clear()
	for i in range(mote_count):
		motes.append({
			"pos": Vector2(
				randf_range(area_rect.position.x, area_rect.end.x),
				randf_range(area_rect.position.y, area_rect.end.y)
			),
			"size": randf_range(1.0, 2.5),
			"alpha": randf_range(0.2, 0.7),
			"sway_offset": randf() * TAU,
			"sway_speed": randf_range(1.5, 3.2),
			"speed_mult": randf_range(0.6, 1.4)
		})

func _process(delta: float) -> void:
	time_accum += delta
	var follow_player = get_tree().get_first_node_in_group("player")
	var center = follow_player.global_position if follow_player else area_rect.get_center()

	for m in motes:
		var sway_x = sin(time_accum * m["sway_speed"] + m["sway_offset"]) * 8.0
		var sway_y = cos(time_accum * m["sway_speed"] * 0.7 + m["sway_offset"]) * 4.0

		m["pos"].x += (wind_velocity.x * m["speed_mult"] + sway_x) * delta
		m["pos"].y += (wind_velocity.y * m["speed_mult"] + sway_y) * delta

		# Ekran / merkez etrafında sarma (Wrap around)
		if m["pos"].x > center.x + 480.0:
			m["pos"].x = center.x - 480.0
			m["pos"].y = randf_range(center.y - 320.0, center.y + 320.0)
		elif m["pos"].x < center.x - 480.0:
			m["pos"].x = center.x + 480.0
			m["pos"].y = randf_range(center.y - 320.0, center.y + 320.0)

		if m["pos"].y > center.y + 320.0:
			m["pos"].y = center.y - 320.0
		elif m["pos"].y < center.y - 320.0:
			m["pos"].y = center.y + 320.0

	queue_redraw()

func _draw() -> void:
	for m in motes:
		var p = m["pos"] as Vector2
		var s = m["size"] as float
		var a = m["alpha"] * (0.6 + 0.4 * sin(time_accum * 2.0 + m["sway_offset"]))
		var c = Color(base_color.r, base_color.g, base_color.b, a)

		# Piksel parçacığı (1-2px)
		draw_rect(Rect2(p, Vector2(s, s)), c)
		# Küçük yumuşak hale
		if s > 1.8:
			var halo_c = Color(base_color.r, base_color.g, base_color.b, a * 0.3)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(s + 2, s + 2)), halo_c)
