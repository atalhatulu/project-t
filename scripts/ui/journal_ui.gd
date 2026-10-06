@tool
extends Control
class_name JournalUI

# Project T - Oyuncu Günlüğü Arayüzü (JournalUI)
# J tuşuyla açılır ve kapanır.
# Zelda & World of Anterra tarzında deri kapaklı retro parşömen/günlük görünümü.
# Harita işaretçisi yerine söylenti kaynakları, hedefler, aşama durumları ve keşif notları listelenir.

signal visibility_toggled(is_open: bool)

var is_open: bool = false
var selected_quest_id: String = ""
var quest_manager: Node = null

# UI Boyutları ve Konumu
var panel_rect: Rect2 = Rect2(0, 0, 420, 260)
var col_bg: Color = Color(0.12, 0.10, 0.08, 0.95) # Deri kahverengi
var col_parchment: Color = Color(0.18, 0.15, 0.12, 0.96) # Parşömen paneli
var col_gold: Color = Color("d97706")
var col_gold_bright: Color = Color("f59e0b")
var col_text: Color = Color("f3f4f6")
var col_text_dim: Color = Color("9ca3af")
var col_text_muted: Color = Color("6b7280")

# Sekmeler: 0 = Aktif Görevler, 1 = Tamamlananlar/Başarısız, 2 = Dedikodu & Keşif Günlüğü
var current_tab: int = 0
var tab_rects: Array[Rect2] = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center_panel()
	_connect_quest_manager()

func _center_panel() -> void:
	if not is_inside_tree():
		return
	var vp_size = get_viewport_rect().size
	panel_rect.position = Vector2(
		(vp_size.x - panel_rect.size.x) * 0.5,
		(vp_size.y - panel_rect.size.y) * 0.5
	)

func _connect_quest_manager() -> void:
	if not is_inside_tree():
		return
	if not quest_manager:
		quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		if not quest_manager.journal_updated.is_connected(_on_journal_updated):
			quest_manager.journal_updated.connect(_on_journal_updated)

func _on_journal_updated() -> void:
	queue_redraw()

func toggle() -> void:
	set_open(not is_open)

func set_open(open: bool) -> void:
	is_open = open
	visible = is_open
	visibility_toggled.emit(is_open)
	if is_open:
		_connect_quest_manager()
		_center_panel()
		# İlk görevi seç
		if quest_manager:
			var act = quest_manager.get_active_quests()
			if not act.is_empty():
				selected_quest_id = act[0].quest_id
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_open: return

	if event is InputEventMouseButton and event.pressed:
		var mpos = event.position
		# Sekme tıklamaları
		for i in range(tab_rects.size()):
			if tab_rects[i].has_point(mpos):
				current_tab = i
				queue_redraw()
				accept_event()
				return

		# Görev listesi tıklamaları
		var list_rect = Rect2(panel_rect.position.x + 14, panel_rect.position.y + 44, 150, 200)
		if list_rect.has_point(mpos):
			var quests_to_show = _get_current_tab_quests()
			var y_offset = list_rect.position.y + 4
			for q in quests_to_show:
				var item_rect = Rect2(list_rect.position.x, y_offset, 142, 28)
				if item_rect.has_point(mpos):
					selected_quest_id = q.quest_id
					queue_redraw()
					accept_event()
					return
				y_offset += 32

func _get_current_tab_quests() -> Array[QuestData]:
	if not quest_manager: return []
	var res: Array[QuestData] = []
	for q in quest_manager.get_all_quests():
		if current_tab == 0 and (q.stage == QuestData.QuestStage.ACTIVE or q.stage == QuestData.QuestStage.AVAILABLE):
			res.append(q)
		elif current_tab == 1 and (q.stage == QuestData.QuestStage.COMPLETED or q.stage == QuestData.QuestStage.FAILED):
			res.append(q)
	return res

func _draw() -> void:
	if not is_open: return

	# Dış Çerçeve ve Deri Arka Plan
	draw_rect(panel_rect, col_bg, true)
	draw_rect(panel_rect, col_gold, false, 2.0)
	draw_rect(panel_rect.grow(-3), col_parchment, true)

	# Başlık
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(panel_rect.position.x + 16, panel_rect.position.y + 24), "MACERA GÜNLÜĞÜ & SÖYLENTİLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col_gold_bright)
	draw_string(font, Vector2(panel_rect.end.x - 70, panel_rect.position.y + 24), "[J] Kapat", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_text_dim)

	# Sekmeler
	tab_rects.clear()
	var tab_names = ["Aktif & Keşif", "Tamamlananlar", "Notlar"]
	var tab_x = panel_rect.position.x + 14
	var tab_y = panel_rect.position.y + 32
	for i in range(tab_names.size()):
		var t_rect = Rect2(tab_x, tab_y, 76, 18)
		tab_rects.append(t_rect)
		var is_sel = (current_tab == i)
		draw_rect(t_rect, col_gold if is_sel else Color(0.2, 0.17, 0.14), true)
		draw_rect(t_rect, col_gold_bright if is_sel else Color(0.3, 0.25, 0.2), false, 1.0)
		draw_string(font, Vector2(t_rect.position.x + 4, t_rect.position.y + 13), tab_names[i], HORIZONTAL_ALIGNMENT_CENTER, t_rect.size.x, 9, Color.BLACK if is_sel else col_text_dim)
		tab_x += 80

	# Sol Bölme: Görev Listesi
	var list_rect = Rect2(panel_rect.position.x + 14, panel_rect.position.y + 54, 150, 192)
	draw_rect(list_rect, Color(0.10, 0.08, 0.06, 0.7), true)
	draw_rect(list_rect, Color(0.3, 0.25, 0.2), false, 1.0)

	# Sağ Bölme: Görev Detayları / Notlar
	var detail_rect = Rect2(panel_rect.position.x + 170, panel_rect.position.y + 54, 236, 192)
	draw_rect(detail_rect, Color(0.10, 0.08, 0.06, 0.7), true)
	draw_rect(detail_rect, Color(0.3, 0.25, 0.2), false, 1.0)

	if current_tab == 2:
		_draw_general_notes(font, detail_rect, list_rect)
		return

	# Görevleri listele
	var quests_list = _get_current_tab_quests()
	var item_y = list_rect.position.y + 6
	for q in quests_list:
		var is_selected = (q.quest_id == selected_quest_id)
		var item_r = Rect2(list_rect.position.x + 2, item_y, 146, 26)
		if is_selected:
			draw_rect(item_r, Color(0.35, 0.25, 0.12, 0.8), true)
			draw_rect(item_r, col_gold_bright, false, 1.0)

		# Durum göstergesi küçük nokta
		var dot_col = col_gold_bright if q.stage == QuestData.QuestStage.ACTIVE else (Color("4ade80") if q.stage == QuestData.QuestStage.COMPLETED else Color("ef4444"))
		if q.stage == QuestData.QuestStage.AVAILABLE: dot_col = Color("9ca3af")
		draw_circle(Vector2(item_r.position.x + 8, item_r.position.y + 13), 3.0, dot_col)

		draw_string(font, Vector2(item_r.position.x + 16, item_r.position.y + 17), q.title, HORIZONTAL_ALIGNMENT_LEFT, 126, 9, col_text if is_selected else col_text_dim)
		item_y += 30

	# Seçili Görev Detayı
	var sel_quest = quest_manager.get_quest(selected_quest_id) if quest_manager else null
	if sel_quest:
		_draw_quest_details(font, detail_rect, sel_quest)
	else:
		draw_string(font, Vector2(detail_rect.position.x + 20, detail_rect.position.y + 90), "Bir kayıt veya söylenti seçin.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_text_muted)

func _draw_quest_details(font: Font, rect: Rect2, q: QuestData) -> void:
	var dx = rect.position.x + 10
	var dy = rect.position.y + 18

	# Başlık
	draw_string(font, Vector2(dx, dy), q.title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 11, col_gold_bright)
	dy += 16

	# Aşama
	var stage_str = "Durum: "
	var stage_col = col_gold
	match q.stage:
		QuestData.QuestStage.AVAILABLE:
			stage_str += "Keşfedilmeyi Bekliyor (Söylenti)"
			stage_col = Color("9ca3af")
		QuestData.QuestStage.ACTIVE:
			stage_str += "Devam Ediyor"
			stage_col = Color("facc15")
		QuestData.QuestStage.COMPLETED:
			stage_str += "Tamamlandı"
			stage_col = Color("4ade80")
		QuestData.QuestStage.FAILED:
			stage_str += "Başarısız / Kaçırıldı"
			stage_col = Color("ef4444")
	draw_string(font, Vector2(dx, dy), stage_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, stage_col)
	dy += 15

	# Söylenti Kaynağı
	if q.rumor_source != "":
		draw_string(font, Vector2(dx, dy), "Duyum: " + q.rumor_source, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 8, Color("d1d5db"))
		dy += 14

	# Hedef Açıklaması
	draw_string(font, Vector2(dx, dy), "İpucu / Hedef:", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_gold)
	dy += 12
	draw_string(font, Vector2(dx, dy), q.objective_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 8, col_text)
	dy += 24

	# Günlük Notları
	draw_string(font, Vector2(dx, dy), "Seyahat Notları:", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col_gold)
	dy += 14
	for note in q.log_entries:
		draw_string(font, Vector2(dx + 4, dy), "• " + note, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 25, 8, col_text_dim)
		dy += 14

func _draw_general_notes(font: Font, detail_rect: Rect2, list_rect: Rect2) -> void:
	draw_string(font, Vector2(list_rect.position.x + 8, list_rect.position.y + 20), "Köy Söylentileri", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_gold)
	draw_string(font, Vector2(list_rect.position.x + 8, list_rect.position.y + 45), "Vadi boyunca halkın", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_dim)
	draw_string(font, Vector2(list_rect.position.x + 8, list_rect.position.y + 60), "ağzından dökülen", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_dim)
	draw_string(font, Vector2(list_rect.position.x + 8, list_rect.position.y + 75), "güncel havadisler.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_dim)

	var dx = detail_rect.position.x + 10
	var dy = detail_rect.position.y + 18
	draw_string(font, Vector2(dx, dy), "Dünya Olayları & Kayıtlar", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col_gold_bright)
	dy += 18

	if not quest_manager or quest_manager.general_journal_notes.is_empty():
		draw_string(font, Vector2(dx, dy), "Henüz önemli bir dünya olayı kaydedilmedi.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col_text_muted)
		return

	for note in quest_manager.general_journal_notes:
		draw_string(font, Vector2(dx, dy), "• " + note, HORIZONTAL_ALIGNMENT_LEFT, detail_rect.size.x - 20, 8, col_text)
		dy += 16
