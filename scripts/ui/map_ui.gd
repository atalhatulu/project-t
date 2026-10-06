@tool
extends Control
class_name MapUI

# Project T - Dünya Haritası ve Hızlı Seyahat Arayüzü (MapUI)
# M tuşuyla açılır ve kapanır.
#
# Görsel ve İşlevsel Özellikler:
# 1. Retro piksel parşömen çerçevesi & mini dünya haritası
# 2. Hücresel Fog-of-War (keşfedilmemiş alanlar siyah/sisli kaplama ile gizli)
# 3. Oyuncu konumu (yanıp sönen mavi/altın üçgen veya nokta)
# 4. Keşfedilmiş Önemli Yerler (POIs) ve hızlı seyahat butonları
# 5. Sağ tık ile haritaya özel işaretçi (marker) ekleme / kaldırma
# 6. Hızlı seyahat ile anında intikal ve geçen seyahat süresi (TimeManager)

signal visibility_toggled(is_open: bool)

var is_open: bool = false
var map_manager: Node = null

# UI Boyutları: Ekran 640x360, Harita Paneli: 440 x 300
var panel_rect: Rect2 = Rect2(0, 0, 440, 300)
var map_area_rect: Rect2 = Rect2(0, 0, 384, 256) # 1920x1280 * 0.20

# Renkler
var col_border: Color = Color("451a03") # Koyu deri kahve
var col_frame: Color = Color("78350f")
var col_parchment: Color = Color("fef3c7") # Parşömen sarısı
var col_water: Color = Color("38bdf8")
var col_grass: Color = Color("84cc16")
var col_mountain: Color = Color("a8a29e")
var col_dirt: Color = Color("d97706")
var col_fog: Color = Color(0.08, 0.08, 0.10, 0.94) # Yoğun sis
var col_player: Color = Color("3b82f6") # Oyuncu mavisi
var col_gold: Color = Color("eab308")
var col_text: Color = Color("1c1917")

# Etkileşim durumu
var selected_poi_id: String = ""
var hover_poi_id: String = ""
var pulse_timer: float = 0.0
var travel_message: String = ""
var message_timer: float = 0.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center_panel()
	_connect_map_manager()

func _center_panel() -> void:
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	panel_rect.position = Vector2(
		(vp_size.x - panel_rect.size.x) * 0.5,
		(vp_size.y - panel_rect.size.y) * 0.5
	)
	# Harita çizim alanı panelin ortasında yer alır
	map_area_rect.position = panel_rect.position + Vector2(28, 24)

func _connect_map_manager() -> void:
	if not is_inside_tree():
		return
	if not map_manager:
		map_manager = get_node_or_null("/root/MapManager")
	if map_manager:
		if not map_manager.map_updated.is_connected(_on_map_updated):
			map_manager.map_updated.connect(_on_map_updated)

func _on_map_updated() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if not is_open:
		return
	pulse_timer += delta * 4.0
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			travel_message = ""
	queue_redraw()

func toggle() -> void:
	set_open(not is_open)

func set_open(open: bool) -> void:
	is_open = open
	visible = is_open
	visibility_toggled.emit(is_open)
	if is_open:
		_center_panel()
		_connect_map_manager()
		# Açılışta oyuncunun bulunduğu yeri otomatik aydınlat
		var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
		if player and map_manager:
			map_manager.reveal_fog_around_world_pos(player.global_position, 160.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		# Harita alanı içinde mi tıklandı?
		if map_area_rect.has_point(mouse_pos):
			var local_map_pos = mouse_pos - map_area_rect.position
			var world_click_pos = map_manager.map_to_world_coords(local_map_pos) if map_manager else local_map_pos * 5.0

			if event.button_index == MOUSE_BUTTON_LEFT:
				# Sol tık: POI seçimi ve hızlı seyahat kontrolü
				_handle_left_click(world_click_pos, local_map_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Sağ tık: Özel işaretçi koy veya kaldır
				_handle_right_click(world_click_pos)

	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event.position)

func _handle_left_click(_world_pos: Vector2, local_map_pos: Vector2) -> void:
	if not map_manager:
		return

	var clicked_poi = _find_poi_near_map_pos(local_map_pos, 14.0)
	if clicked_poi != "":
		selected_poi_id = clicked_poi
		var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if map_manager.can_fast_travel_to(clicked_poi):
			if player:
				var hours = map_manager.calculate_travel_hours(player.global_position, map_manager.pois[clicked_poi]["world_pos"])
				var success = map_manager.fast_travel(clicked_poi, player)
				if success:
					travel_message = "%s noktasına seyahat edildi! (%s saat geçti)" % [map_manager.pois[clicked_poi]["name"], str(hours)]
					message_timer = 3.5
		else:
			travel_message = "%s hızlı seyahate uygun değil." % [map_manager.pois[clicked_poi]["name"]]
			message_timer = 2.5
	queue_redraw()

func _handle_right_click(world_pos: Vector2) -> void:
	if not map_manager:
		return
	# Eğer zaten yakınında işaret varsa kaldır, yoksa ekle
	var removed = map_manager.remove_marker_near(world_pos, 80.0)
	if not removed:
		map_manager.add_marker(world_pos, "Özel İşaret", Color("f59e0b"))
		travel_message = "Haritaya yeni işaret eklendi."
		message_timer = 2.0
	else:
		travel_message = "İşaret kaldırıldı."
		message_timer = 1.5
	queue_redraw()

func _handle_mouse_motion(screen_pos: Vector2) -> void:
	if not map_area_rect.has_point(screen_pos) or not map_manager:
		hover_poi_id = ""
		return
	var local_map_pos = screen_pos - map_area_rect.position
	hover_poi_id = _find_poi_near_map_pos(local_map_pos, 12.0)

func _find_poi_near_map_pos(local_map_pos: Vector2, radius: float) -> String:
	if not map_manager:
		return ""
	for p_id in map_manager.pois:
		var poi = map_manager.pois[p_id]
		if not poi["discovered"]:
			continue
		var poi_map_pos = map_manager.world_to_map_coords(poi["world_pos"])
		if poi_map_pos.distance_to(local_map_pos) <= radius:
			return p_id
	return ""

# ----------------- ÇİZİM FONKSİYONLARI (Pixel Art UI) -----------------
func _draw() -> void:
	if not is_open:
		return

	# 1. Ekran arkası karartma
	var vp_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0, 0, 0, 0.6))

	# 2. Dış Çerçeve (Ahşap & Deri bordür)
	draw_rect(panel_rect, col_border)
	draw_rect(panel_rect.grow(-3), col_frame)
	draw_rect(panel_rect.grow(-5), Color("292524"))

	# 3. Başlık Çubuğu
	draw_string(ThemeDB.fallback_font, panel_rect.position + Vector2(28, 18), "DÜNYA HARİTASI & SEYAHAT (M)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fef08a"))
	draw_string(ThemeDB.fallback_font, panel_rect.position + Vector2(260, 18), "[Sağ Tık]: İşaret Ekle/Kaldır", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("cbd5e1"))

	# 4. Harita Tabanı (Parşömen ve Coğrafi Bölgeler)
	_draw_base_world_map()

	# 5. Sis Katmanı (Fog of War)
	_draw_fog_of_war()

	# 6. Keşfedilmiş Önemli Yerler (POIs) & Görev İşaretleri
	_draw_pois_and_markers()

	# 7. Oyuncu Konum İbresi
	_draw_player_indicator()

	# 8. Alt Bilgi Çubuğu ve Bildirimler
	_draw_status_bar()

func _draw_base_world_map() -> void:
	draw_rect(map_area_rect, col_parchment)

	# Temsili coğrafi bölgeler (Basit retro harita blokları)
	var ox = map_area_rect.position.x
	var oy = map_area_rect.position.y

	# Nehir / Su (Merkezden güneye kıvrılan su yolu)
	var water_poly = PackedVector2Array([
		Vector2(ox + 160, oy + 40),
		Vector2(ox + 175, oy + 120),
		Vector2(ox + 190, oy + 180),
		Vector2(ox + 240, oy + 240),
		Vector2(ox + 215, oy + 240),
		Vector2(ox + 170, oy + 175),
		Vector2(ox + 155, oy + 115),
		Vector2(ox + 140, oy + 40)
	])
	draw_colored_polygon(water_poly, col_water)

	# Batı Ormanı (Yeşil alan)
	draw_rect(Rect2(ox + 20, oy + 30, 80, 120), Color(0.4, 0.65, 0.2, 0.45))
	# Kuzeydoğu Kayalıkları (Gri tepe)
	draw_rect(Rect2(ox + 260, oy + 20, 110, 80), Color(0.6, 0.58, 0.55, 0.5))
	# Doğu Çoraklığı / Haydut Bozkırı (Toprak rengi)
	draw_rect(Rect2(ox + 270, oy + 140, 100, 100), Color(0.75, 0.55, 0.35, 0.4))
	# Kızıl Köy Alanı (Açık sarı/yeşil çayır)
	draw_circle(Vector2(ox + 96, oy + 64), 32.0, Color(0.85, 0.75, 0.4, 0.5))

func _draw_fog_of_war() -> void:
	if not map_manager:
		return

	var cell_w = map_area_rect.size.x / float(map_manager.FOG_COLS)
	var cell_h = map_area_rect.size.y / float(map_manager.FOG_ROWS)

	for cx in range(map_manager.FOG_COLS):
		for cy in range(map_manager.FOG_ROWS):
			if not map_manager.is_fog_revealed(Vector2i(cx, cy)):
				var r = Rect2(
					map_area_rect.position.x + (cx * cell_w),
					map_area_rect.position.y + (cy * cell_h),
					cell_w,
					cell_h
				)
				draw_rect(r, col_fog)

func _draw_pois_and_markers() -> void:
	if not map_manager:
		return

	# POI'ler
	for p_id in map_manager.pois:
		var poi = map_manager.pois[p_id]
		if not poi["discovered"]:
			continue

		var map_pos = map_area_rect.position + map_manager.world_to_map_coords(poi["world_pos"])
		var is_hover = (hover_poi_id == p_id)
		var is_fast = poi.get("can_fast_travel", false)

		var icon_col = Color("22c55e") if is_fast else Color("0ea5e9")
		if is_hover:
			icon_col = Color("facc15")

		# Simge (Hızlı seyahat noktaları kare elmas, diğerleri daire)
		if is_fast:
			var pts = PackedVector2Array([
				map_pos + Vector2(0, -6),
				map_pos + Vector2(5, 0),
				map_pos + Vector2(0, 6),
				map_pos + Vector2(-5, 0)
			])
			draw_colored_polygon(pts, icon_col)
			draw_polyline(pts, Color.BLACK, 1.0)
		else:
			draw_circle(map_pos, 4.5, icon_col)
			draw_arc(map_pos, 4.5, 0, TAU, 12, Color.BLACK, 1.0)

		# İsim Etiketi
		draw_string(ThemeDB.fallback_font, map_pos + Vector2(8, 4), poi["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("0f172a") if not is_hover else Color("991b1b"))

	# Özel İşaretçiler (Custom Markers)
	for marker in map_manager.custom_markers:
		var m_pos = map_area_rect.position + map_manager.world_to_map_coords(marker["world_pos"])
		var m_col: Color = marker.get("color", Color("eab308"))
		# Küçük flama / bayrak çizimi
		draw_line(m_pos, m_pos + Vector2(0, -10), Color.BLACK, 1.5)
		var flag_pts = PackedVector2Array([
			m_pos + Vector2(0, -10),
			m_pos + Vector2(7, -7),
			m_pos + Vector2(0, -4)
		])
		draw_colored_polygon(flag_pts, m_col)

func _draw_player_indicator() -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player or not map_manager:
		return

	var p_map_pos = map_area_rect.position + map_manager.world_to_map_coords(player.global_position)
	var pulse = 0.5 + 0.5 * sin(pulse_timer)
	var radius = 5.0 + (pulse * 2.5)

	# Nabız halkası
	draw_arc(p_map_pos, radius, 0, TAU, 16, Color(0.2, 0.6, 1.0, 0.7), 1.5)
	# Merkez nokta
	draw_circle(p_map_pos, 3.5, col_player)
	draw_circle(p_map_pos, 1.5, Color.WHITE)

func _draw_status_bar() -> void:
	var bottom_y = panel_rect.position.y + panel_rect.size.y - 10
	if travel_message != "":
		draw_string(ThemeDB.fallback_font, Vector2(panel_rect.position.x + 28, bottom_y), travel_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("bbf7d0"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(panel_rect.position.x + 28, bottom_y), "Elmas simgeler hızlı seyahat yerleşimidir. Gitmek için sol tıkla.", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("94a3b8"))
