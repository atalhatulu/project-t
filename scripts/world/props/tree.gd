@tool
extends StaticBody2D

# Project T - 3/4 Perspektif Pixel Art Ağaç Nesnesi
# Belirgin kökler, dallı gövde kabuğu ve katmanlı yaprak kümeleri (foliage clusters).

@export_enum("small", "medium", "large") var tree_size: String = "medium"
@export var wind_strength: float = 1.0

var tree_radius: float = 24.0
var wind_time: float = 0.0

# Düşen yapraklar
var falling_leaves: Array[Dictionary] = []
var leaf_spawn_timer: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_apply_size()
	wind_time = randf() * 100.0
	leaf_spawn_timer = randf_range(2.0, 7.0)
	queue_redraw()

func _apply_size() -> void:
	match tree_size:
		"small":
			tree_radius = 16.0
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CircleShape2D:
				(col.shape as CircleShape2D).radius = 4.5
		"medium":
			tree_radius = 24.0
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CircleShape2D:
				(col.shape as CircleShape2D).radius = 6.0
		"large":
			tree_radius = 32.0
			var col = get_node_or_null("CollisionShape2D")
			if col and col.shape is CircleShape2D:
				(col.shape as CircleShape2D).radius = 8.0

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		wind_time += delta * 2.2
		if _is_near_camera():
			leaf_spawn_timer -= delta
			if leaf_spawn_timer <= 0.0:
				leaf_spawn_timer = randf_range(3.0, 8.0)
				_spawn_falling_leaf()
			_update_falling_leaves(delta)
		queue_redraw()

func _is_near_camera() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return global_position.distance_to(player.global_position) < 450.0
	return true

func _spawn_falling_leaf() -> void:
	var trunk_h = tree_radius * 0.75
	var start_y = -trunk_h - randf_range(6, tree_radius)
	var start_x = randf_range(-tree_radius * 0.7, tree_radius * 0.7)
	falling_leaves.append({
		"pos": Vector2(start_x, start_y),
		"vel": Vector2(randf_range(-6, 6), randf_range(12, 22)),
		"sway_offset": randf() * 10.0,
		"life": 3.0,
		"color": Color("529e46") if randf() > 0.3 else Color("f1c40f")
	})

func _update_falling_leaves(delta: float) -> void:
	var i = falling_leaves.size() - 1
	while i >= 0:
		var leaf = falling_leaves[i]
		leaf["life"] -= delta
		var sway = sin(wind_time * 3.0 + leaf["sway_offset"]) * 14.0
		leaf["pos"].x += sway * delta
		leaf["pos"].y += leaf["vel"].y * delta
		if leaf["life"] <= 0.0 or leaf["pos"].y >= 10.0:
			falling_leaves.remove_at(i)
		i -= 1

func _draw() -> void:
	var wind_sway = sin(wind_time) * (1.6 * wind_strength) if not Engine.is_editor_hint() else 0.0

	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(2, 8), tree_radius * 0.7, tree_radius * 0.35, Color(0, 0, 0, 0.42))

	var trunk_w = tree_radius * 0.38
	var trunk_h = tree_radius * 0.85

	# 2. Gövde ve Kökler (Katmanlı meşe ağacı kabuğu)
	var col_bark_dark = Color("382312")
	var col_bark_mid = Color("4d331c")
	var col_bark_light = Color("664528")

	# Kök yayılımları
	draw_line(Vector2(-trunk_w * 0.5, 4), Vector2(-trunk_w * 0.8, 9), col_bark_dark, 3.0)
	draw_line(Vector2(trunk_w * 0.5, 4), Vector2(trunk_w * 0.9, 9), col_bark_mid, 3.0)

	# Ana gövde
	draw_rect(Rect2(-trunk_w * 0.5, -trunk_h * 0.5, trunk_w, trunk_h * 0.7), col_bark_mid)
	# Gövde sol gölge ve sağ ışık şeritleri
	draw_rect(Rect2(-trunk_w * 0.5, -trunk_h * 0.5, 3, trunk_h * 0.7), col_bark_dark)
	draw_rect(Rect2(trunk_w * 0.5 - 3, -trunk_h * 0.5, 3, trunk_h * 0.7), col_bark_light)

	# Dallanma çizgileri
	var branch_y = -trunk_h * 0.3
	draw_line(Vector2(-trunk_w * 0.2, branch_y), Vector2(-tree_radius * 0.5, branch_y - 8), col_bark_dark, 2.5)
	draw_line(Vector2(trunk_w * 0.2, branch_y), Vector2(tree_radius * 0.5, branch_y - 10), col_bark_mid, 2.5)

	# 3. Katmanlı Yaprak Kümeleri (Foliage Clusters - World of Anterra Stili)
	var col_leaf_deep = Color("173413")
	var col_leaf_dark = Color("234b1d")
	var col_leaf_mid = Color("35692d")
	var col_leaf_light = Color("4b8c3f")
	var col_leaf_high = Color("64b354")

	var crown_y = -trunk_h - 4

	# Alt katman derin gölgeler
	draw_circle(Vector2(-tree_radius * 0.35 + wind_sway * 0.3, crown_y + 4), tree_radius * 0.65, col_leaf_deep)
	draw_circle(Vector2(tree_radius * 0.35 + wind_sway * 0.4, crown_y + 4), tree_radius * 0.65, col_leaf_dark)

	# Orta katman ana hacim
	draw_circle(Vector2(-tree_radius * 0.2 + wind_sway * 0.6, crown_y - 4), tree_radius * 0.75, col_leaf_mid)
	draw_circle(Vector2(tree_radius * 0.2 + wind_sway * 0.7, crown_y - 2), tree_radius * 0.75, col_leaf_mid)
	draw_circle(Vector2(wind_sway * 0.8, crown_y - 8), tree_radius * 0.8, col_leaf_light)

	# Üst ve sağ güneş alan aydınlık yaprak tepecikleri (Işık sol-üstten vurur)
	draw_circle(Vector2(-tree_radius * 0.25 + wind_sway * 0.9, crown_y - 12), tree_radius * 0.45, col_leaf_high)
	draw_circle(Vector2(tree_radius * 0.15 + wind_sway * 1.0, crown_y - 14), tree_radius * 0.4, col_leaf_high)
	draw_circle(Vector2(wind_sway * 1.1, crown_y - 18), tree_radius * 0.3, col_leaf_high)

	# 4. Süzülen yapraklar
	for leaf in falling_leaves:
		var p = leaf["pos"] as Vector2
		var col = leaf["color"] as Color
		draw_rect(Rect2(p, Vector2(2, 2)), col)

func _draw_oval_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var rad = (float(i) / 16.0) * TAU
		pts.append(pos + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(pts, col)
