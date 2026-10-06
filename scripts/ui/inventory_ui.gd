@tool
extends Control
class_name InventoryUI

# Project T - Modüler Pixel Art Envanter Arayüzü
# World of Anterra esintili retro altın/kehribar çerçeveli 24 slot ızgarası
# Slot seçimi, eşya detayları (isim, açıklama, kategori), sürükle/bırak ve slot takası

signal visibility_toggled(is_open: bool)
signal item_drop_requested(slot_index: int, amount: int)

const SLOT_SIZE: float = 28.0
const SLOT_PADDING: float = 4.0
const COLS: int = 6
const ROWS: int = 4

var inventory: Inventory = null
var selected_slot_index: int = -1
var hovered_slot_index: int = -1
var drag_source_slot: int = -1
var drop_button_rect: Rect2 = Rect2()
var is_drop_hovered: bool = false

var is_open: bool = false

# UI Renk Paleti
var col_panel_bg: Color = Color(0.10, 0.12, 0.16, 0.94)
var col_border: Color = Color("e5a93b") # Altın vurgu
var col_border_dark: Color = Color("78561d")
var col_slot_bg: Color = Color(0.06, 0.08, 0.11, 0.95)
var col_slot_hover: Color = Color(0.22, 0.28, 0.38, 0.9)
var col_slot_selected: Color = Color("f1c40f")
var col_text: Color = Color("f3f4f6")
var col_text_dim: Color = Color("9ca3af")

# Panel Koordinatları
var panel_rect: Rect2 = Rect2(0, 0, 360, 210)

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center_panel()

func _center_panel() -> void:
	var vp_size = get_viewport_rect().size
	panel_rect.position = Vector2(
		(vp_size.x - panel_rect.size.x) * 0.5,
		(vp_size.y - panel_rect.size.y) * 0.5
	)

func set_inventory(inv: Inventory) -> void:
	if inventory:
		if inventory.inventory_changed.is_connected(_on_inventory_changed):
			inventory.inventory_changed.disconnect(_on_inventory_changed)
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
	queue_redraw()

func _on_inventory_changed() -> void:
	queue_redraw()

func open() -> void:
	is_open = true
	visible = true
	selected_slot_index = -1
	drag_source_slot = -1
	_center_panel()
	visibility_toggled.emit(true)
	queue_redraw()

func close() -> void:
	is_open = false
	visible = false
	selected_slot_index = -1
	drag_source_slot = -1
	visibility_toggled.emit(false)
	queue_redraw()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func _gui_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event is InputEventMouseMotion:
		var pos = event.position
		is_drop_hovered = drop_button_rect.has_point(pos)
		var slot_idx = _get_slot_at_pos(pos)
		if slot_idx != hovered_slot_index or is_drop_hovered:
			hovered_slot_index = slot_idx
			queue_redraw()

	elif event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# 1. Yere Bırak butonuna tıklandı mı?
			if drop_button_rect.has_point(mb.position):
				if selected_slot_index != -1 and inventory and not inventory.is_slot_empty(selected_slot_index):
					item_drop_requested.emit(selected_slot_index, 1)
					if inventory.is_slot_empty(selected_slot_index):
						selected_slot_index = -1
						drag_source_slot = -1
				queue_redraw()
				accept_event()
				return

			# 2. Slotlara tıklandı mı?
			var slot_idx = _get_slot_at_pos(mb.position)
			# Tıklama: Slot seç veya sürüklemeye başla
			if slot_idx != -1:
				if drag_source_slot == -1:
					if inventory and not inventory.is_slot_empty(slot_idx):
						drag_source_slot = slot_idx
						selected_slot_index = slot_idx
				else:
					# İkinci tık: Taşı veya takas et
					if inventory:
						inventory.move_or_merge_slot(drag_source_slot, slot_idx)
					selected_slot_index = slot_idx
					drag_source_slot = -1
			else:
				# Panel dışına veya boş alana tıklandıysa seçimi sıfırla
				drag_source_slot = -1
			queue_redraw()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# Sağ Tık: Doğrudan 1 adet yere bırak
			var slot_idx = _get_slot_at_pos(mb.position)
			if slot_idx != -1 and inventory and not inventory.is_slot_empty(slot_idx):
				item_drop_requested.emit(slot_idx, 1)
				if inventory.is_slot_empty(slot_idx):
					if selected_slot_index == slot_idx:
						selected_slot_index = -1
					if drag_source_slot == slot_idx:
						drag_source_slot = -1
				queue_redraw()
				accept_event()

func _get_slot_at_pos(pos: Vector2) -> int:
	var start_x = panel_rect.position.x + 14.0
	var start_y = panel_rect.position.y + 36.0

	for r in range(ROWS):
		for c in range(COLS):
			var idx = r * COLS + c
			var sx = start_x + c * (SLOT_SIZE + SLOT_PADDING)
			var sy = start_y + r * (SLOT_SIZE + SLOT_PADDING)
			var slot_rect = Rect2(sx, sy, SLOT_SIZE, SLOT_SIZE)
			if slot_rect.has_point(pos):
				return idx
	return -1

func _draw() -> void:
	if not is_open:
		return

	# 1. Ana Panel Arka Planı ve Çerçevesi
	draw_rect(Rect2(panel_rect.position + Vector2(2, 2), panel_rect.size), Color(0, 0, 0, 0.45))
	draw_rect(panel_rect, col_panel_bg)
	draw_rect(panel_rect, col_border, false, 1.5)
	draw_rect(Rect2(panel_rect.position + Vector2(2, 2), panel_rect.size - Vector2(4, 4)), col_border_dark, false, 1.0)

	# 2. Başlık Çubuğu
	var font = ThemeDB.fallback_font
	var title_pos = panel_rect.position + Vector2(14, 20)
	draw_string(font, title_pos, "ENVANTER (24 Slot)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_border)
	draw_string(font, panel_rect.position + Vector2(panel_rect.size.x - 65, 20), "[I] Kapat", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_dim)

	# 3. 24 Slot Izgarası (6 x 4)
	var start_x = panel_rect.position.x + 14.0
	var start_y = panel_rect.position.y + 34.0

	for r in range(ROWS):
		for c in range(COLS):
			var idx = r * COLS + c
			var sx = start_x + c * (SLOT_SIZE + SLOT_PADDING)
			var sy = start_y + r * (SLOT_SIZE + SLOT_PADDING)
			var slot_rect = Rect2(sx, sy, SLOT_SIZE, SLOT_SIZE)

			# Slot Arka Planı
			var bg_color = col_slot_bg
			if idx == drag_source_slot:
				bg_color = Color(0.35, 0.25, 0.1, 0.95)
			elif idx == hovered_slot_index:
				bg_color = col_slot_hover
			draw_rect(slot_rect, bg_color)

			# Slot Çerçevesi
			var border_color = col_border_dark
			if idx == selected_slot_index:
				border_color = col_slot_selected
			elif idx == hovered_slot_index:
				border_color = Color("9ca3af")
			draw_rect(slot_rect, border_color, false, 1.0)

			# Eşya İkonu ve Miktar
			if inventory and not inventory.is_slot_empty(idx):
				var slot_data = inventory.get_slot(idx)
				var item = ItemDatabase.get_item(slot_data["item_id"])
				if item:
					_draw_item_icon(slot_rect, item)
					if slot_data["amount"] > 1:
						var amt_str = str(slot_data["amount"])
						var amt_pos = Vector2(slot_rect.end.x - 14, slot_rect.end.y - 3)
						draw_string(font, amt_pos, amt_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 7, col_text)

	# 4. Sağ Taraf: Eşya Detay Paneli
	var info_x = start_x + COLS * (SLOT_SIZE + SLOT_PADDING) + 12.0
	var info_y = start_y
	var info_w = panel_rect.end.x - info_x - 14.0
	var info_h = ROWS * (SLOT_SIZE + SLOT_PADDING) - SLOT_PADDING

	var info_rect = Rect2(info_x, info_y, info_w, info_h)
	draw_rect(info_rect, Color(0.06, 0.08, 0.11, 0.7))
	draw_rect(info_rect, col_border_dark, false, 1.0)

	var active_slot = selected_slot_index if selected_slot_index != -1 else hovered_slot_index
	if inventory and active_slot != -1 and not inventory.is_slot_empty(active_slot):
		var slot_data = inventory.get_slot(active_slot)
		var item = ItemDatabase.get_item(slot_data["item_id"])
		if item:
			# Başlık ve Kategori
			draw_string(font, Vector2(info_x + 6, info_y + 14), item.name, HORIZONTAL_ALIGNMENT_LEFT, int(info_w - 12), 9, col_border)
			draw_string(font, Vector2(info_x + 6, info_y + 26), "[" + item.get_category_name() + "]  x" + str(slot_data["amount"]), HORIZONTAL_ALIGNMENT_LEFT, int(info_w - 12), 7, col_text_dim)

			# Ayraç Çizgisi
			draw_line(Vector2(info_x + 6, info_y + 32), Vector2(info_x + info_w - 6, info_y + 32), col_border_dark, 1.0)

			# Açıklama (Çok satırlı)
			var lines = item.description.split("\n")
			var text_cursor_y = info_y + 44
			for line in lines:
				draw_string(font, Vector2(info_x + 6, text_cursor_y), line, HORIZONTAL_ALIGNMENT_LEFT, int(info_w - 12), 7, col_text)
				text_cursor_y += 12

			# Yere Bırak Butonu (Sağ altta)
			var btn_w = info_w - 12.0
			var btn_h = 16.0
			var btn_x = info_x + 6.0
			var btn_y = info_y + info_h - btn_h - 6.0
			drop_button_rect = Rect2(btn_x, btn_y, btn_w, btn_h)

			var btn_bg = Color(0.35, 0.15, 0.15, 0.9) if is_drop_hovered else Color(0.2, 0.1, 0.1, 0.8)
			var btn_border = Color("e74c3c") if is_drop_hovered else Color("c0392b")
			draw_rect(drop_button_rect, btn_bg)
			draw_rect(drop_button_rect, btn_border, false, 1.0)
			draw_string(font, Vector2(btn_x + btn_w * 0.5 - 28, btn_y + 11), "[Yere Bırak]", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, col_text)
	else:
		drop_button_rect = Rect2()
		draw_string(font, Vector2(info_x + 10, info_y + 24), "Bir eşya seçin...", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_dim)

# Pixel Art Şematik Eşya İkonu Çizici
func _draw_item_icon(slot_rect: Rect2, item: ItemData) -> void:
	var center = slot_rect.position + slot_rect.size * 0.5
	match item.icon_shape:
		"circle":
			draw_circle(center, 7.0, item.icon_color)
			draw_circle(center, 3.5, item.secondary_color)
		"rect":
			draw_rect(Rect2(center.x - 7, center.y - 5, 14, 10), item.icon_color)
			draw_rect(Rect2(center.x - 5, center.y - 3, 10, 6), item.secondary_color)
		"gem":
			var pts = PackedVector2Array([
				Vector2(center.x, center.y - 8),
				Vector2(center.x + 7, center.y),
				Vector2(center.x, center.y + 8),
				Vector2(center.x - 7, center.y)
			])
			draw_colored_polygon(pts, item.icon_color)
			draw_circle(center, 2.5, item.secondary_color)
		"cross":
			draw_rect(Rect2(center.x - 2, center.y - 8, 4, 16), item.icon_color)
			draw_rect(Rect2(center.x - 7, center.y - 3, 14, 4), item.secondary_color)
		"potion":
			# Şişe boynu ve gövdesi
			draw_rect(Rect2(center.x - 2, center.y - 8, 4, 4), item.secondary_color)
			draw_circle(Vector2(center.x, center.y + 1), 6.5, item.icon_color)
		_:
			draw_circle(center, 6.0, item.icon_color)
