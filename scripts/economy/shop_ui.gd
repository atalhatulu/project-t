@tool
extends Control
class_name ShopUI

# Project T - Alışveriş ve Ticaret Arayüzü (ShopUI)
# Tüccar stokları, fiyatlar, satın alma, satış ve oyuncu bakır sikkeleri

signal shop_closed

var is_open: bool = false
var merchant_id: String = ""
var economy_manager: Node = null
var player_inventory: Inventory = null

# Sekmeler: 0 = Satın Al (Buy), 1 = Sat (Sell)
var active_tab: int = 0

# UI Boyutları ve Renkleri
var panel_rect: Rect2 = Rect2(0, 0, 400, 240)
var col_bg: Color = Color(0.10, 0.12, 0.16, 0.96)
var col_panel: Color = Color(0.06, 0.08, 0.11, 0.95)
var col_gold: Color = Color("e5a93b")
var col_gold_bright: Color = Color("f1c40f")
var col_text: Color = Color("f3f4f6")
var col_text_dim: Color = Color("9ca3af")
var col_danger: Color = Color("ef4444")
var col_success: Color = Color("22c55e")

var buy_item_rects: Array[Dictionary] = []
var sell_item_rects: Array[Dictionary] = []
var tab_rect_buy: Rect2 = Rect2()
var tab_rect_sell: Rect2 = Rect2()
var btn_close_rect: Rect2 = Rect2()

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center_panel()

func _center_panel() -> void:
	if not is_inside_tree(): return
	var vp_size = get_viewport_rect().size
	panel_rect.position = Vector2(
		(vp_size.x - panel_rect.size.x) * 0.5,
		(vp_size.y - panel_rect.size.y) * 0.5
	)

func open_shop(p_merchant_id: String, p_inv: Inventory) -> void:
	merchant_id = p_merchant_id
	player_inventory = p_inv
	economy_manager = get_node_or_null("/root/EconomyManager") if is_inside_tree() else null
	is_open = true
	visible = true
	_center_panel()
	queue_redraw()

func close_shop() -> void:
	is_open = false
	visible = false
	shop_closed.emit()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_open: return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos = event.position
		
		# Kapat Butonu
		if btn_close_rect.has_point(mpos):
			close_shop()
			accept_event()
			return

		# Sekmeler
		if tab_rect_buy.has_point(mpos):
			active_tab = 0
			queue_redraw()
			accept_event()
			return
		elif tab_rect_sell.has_point(mpos):
			active_tab = 1
			queue_redraw()
			accept_event()
			return

		# Satın Alma Tıklamaları
		if active_tab == 0:
			for b in buy_item_rects:
				if b["rect"].has_point(mpos) and economy_manager and player_inventory:
					economy_manager.buy_from_merchant(merchant_id, b["item_id"], 1, player_inventory)
					queue_redraw()
					accept_event()
					return
		# Satış Tıklamaları
		elif active_tab == 1:
			for s in sell_item_rects:
				if s["rect"].has_point(mpos) and economy_manager and player_inventory:
					economy_manager.sell_to_merchant(merchant_id, s["item_id"], 1, player_inventory)
					queue_redraw()
					accept_event()
					return

func _draw() -> void:
	if not is_open: return

	var font = ThemeDB.fallback_font
	draw_rect(panel_rect, col_bg, true)
	draw_rect(panel_rect, col_gold, false, 2.0)

	# Başlık ve Kapat Butonu
	var m_title = "Dükkân"
	if economy_manager and economy_manager.merchants.has(merchant_id):
		m_title = economy_manager.merchants[merchant_id].get("title", "Dükkân")
	
	draw_string(font, Vector2(panel_rect.position.x + 14, panel_rect.position.y + 24), m_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col_gold_bright)
	
	btn_close_rect = Rect2(panel_rect.end.x - 26, panel_rect.position.y + 10, 18, 18)
	draw_rect(btn_close_rect, Color(0.3, 0.1, 0.1), true)
	draw_string(font, Vector2(btn_close_rect.position.x + 5, btn_close_rect.position.y + 13), "X", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

	# Oyuncunun Parası
	var gold = economy_manager.get_player_gold(player_inventory) if economy_manager and player_inventory else 0
	draw_string(font, Vector2(panel_rect.end.x - 140, panel_rect.position.y + 24), "Kese: " + str(gold) + " Sikke", HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, col_gold_bright)

	# Sekmeler
	tab_rect_buy = Rect2(panel_rect.position.x + 14, panel_rect.position.y + 36, 70, 20)
	tab_rect_sell = Rect2(panel_rect.position.x + 90, panel_rect.position.y + 36, 70, 20)
	
	draw_rect(tab_rect_buy, col_gold if active_tab == 0 else Color(0.18, 0.22, 0.28), true)
	draw_string(font, Vector2(tab_rect_buy.position.x + 14, tab_rect_buy.position.y + 14), "Satın Al", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.BLACK if active_tab == 0 else col_text_dim)

	draw_rect(tab_rect_sell, col_gold if active_tab == 1 else Color(0.18, 0.22, 0.28), true)
	draw_string(font, Vector2(tab_rect_sell.position.x + 22, tab_rect_sell.position.y + 14), "Sat", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.BLACK if active_tab == 1 else col_text_dim)

	# Liste Alanı
	var content_rect = Rect2(panel_rect.position.x + 14, panel_rect.position.y + 62, panel_rect.size.x - 28, 164)
	draw_rect(content_rect, col_panel, true)
	draw_rect(content_rect, Color(0.2, 0.25, 0.32), false, 1.0)

	buy_item_rects.clear()
	sell_item_rects.clear()

	var iy = content_rect.position.y + 8

	# 1. SATIN ALMA LİSTESİ
	if active_tab == 0:
		if economy_manager and economy_manager.merchants.has(merchant_id):
			var stock = economy_manager.merchants[merchant_id]["stock"]
			for s in stock:
				var item = ItemDatabase.get_item(s["item_id"])
				if not item: continue
				
				var item_r = Rect2(content_rect.position.x + 6, iy, content_rect.size.x - 12, 28)
				draw_rect(item_r, Color(0.14, 0.18, 0.24, 0.7), true)
				
				# İsim ve Stok
				draw_string(font, Vector2(item_r.position.x + 8, item_r.position.y + 18), item.name, HORIZONTAL_ALIGNMENT_LEFT, 150, 10, col_text)
				draw_string(font, Vector2(item_r.position.x + 160, item_r.position.y + 18), "Stok: " + str(s["current_stock"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_text_dim)
				
				# Fiyat
				var unit_price = economy_manager.get_item_price(item.id, s.get("price_mult", 1.0), true)
				var can_afford = (gold >= unit_price) and (s["current_stock"] > 0)
				draw_string(font, Vector2(item_r.end.x - 90, item_r.position.y + 18), str(unit_price) + " Sikke", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, col_gold_bright if can_afford else col_danger)
				
				# Al butonu
				var btn_r = Rect2(item_r.end.x - 42, item_r.position.y + 4, 38, 20)
				draw_rect(btn_r, col_gold if can_afford else Color(0.3, 0.3, 0.3), true)
				draw_string(font, Vector2(btn_r.position.x + 12, btn_r.position.y + 14), "Al", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.BLACK if can_afford else col_text_dim)
				
				buy_item_rects.append({"rect": btn_r, "item_id": item.id})
				iy += 32

	# 2. SATIŞ LİSTESİ (Oyuncunun Envanterindeki satılabilir eşyalar)
	else:
		if player_inventory:
			var seen_items = {}
			for slot in player_inventory.slots:
				var i_id = slot["item_id"]
				if i_id == "" or i_id == "cooper_coins" or seen_items.has(i_id):
					continue
				seen_items[i_id] = true
				var item = ItemDatabase.get_item(i_id)
				if not item or item.category == ItemData.ItemCategory.QUEST:
					continue # Görev eşyaları satılamaz!
				
				var item_r = Rect2(content_rect.position.x + 6, iy, content_rect.size.x - 12, 28)
				draw_rect(item_r, Color(0.14, 0.18, 0.24, 0.7), true)
				
				draw_string(font, Vector2(item_r.position.x + 8, item_r.position.y + 18), item.name, HORIZONTAL_ALIGNMENT_LEFT, 150, 10, col_text)
				
				var sell_price = economy_manager.get_item_price(i_id, 1.0, false)
				draw_string(font, Vector2(item_r.end.x - 90, item_r.position.y + 18), str(sell_price) + " Sikke", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, col_success)
				
				var btn_r = Rect2(item_r.end.x - 42, item_r.position.y + 4, 38, 20)
				draw_rect(btn_r, Color("16a34a"), true)
				draw_string(font, Vector2(btn_r.position.x + 10, btn_r.position.y + 14), "Sat", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
				
				sell_item_rects.append({"rect": btn_r, "item_id": i_id})
				iy += 32
