@tool
extends Node2D
class_name InteractablePrompt

# Project T - Etkileşim İpucu Göstergesi ([E] Etkileşim)
# Oyuncu nesneye yaklaştığında hafif süzülen pixel-art ipucu paneli

@export var prompt_text: String = "Etkileşim"
@export var prompt_key: String = "E"
@export var float_offset_y: float = -28.0

var is_prompt_visible: bool = false
var anim_time: float = 0.0

func _ready() -> void:
	z_index = 50
	visible = false

func _process(delta: float) -> void:
	if visible:
		anim_time += delta * 4.0
		queue_redraw()

func show_prompt(action_name: String = "") -> void:
	if action_name != "":
		prompt_text = action_name
	visible = true
	is_prompt_visible = true
	queue_redraw()

func hide_prompt() -> void:
	visible = false
	is_prompt_visible = false
	queue_redraw()

func _draw() -> void:
	if not visible:
		return

	var bob_offset = sin(anim_time) * 2.0
	var draw_pos = Vector2(0, float_offset_y + bob_offset)

	# Metin boyutunu hesapla
	var font = ThemeDB.fallback_font
	var font_size = 9
	var full_str = "[" + prompt_key + "] " + prompt_text
	var text_w = font.get_string_size(full_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var box_w = max(42.0, text_w + 10.0)
	var box_h = 14.0

	var rect = Rect2(draw_pos.x - box_w * 0.5, draw_pos.y - box_h * 0.5, box_w, box_h)

	# 1. Gölge ve Arka Plan Paneli
	draw_rect(Rect2(rect.position + Vector2(1, 1), rect.size), Color(0, 0, 0, 0.45))
	draw_rect(rect, Color(0.1, 0.12, 0.16, 0.92))
	# Kenar çerçevesi (World of Anterra stili altın sarısı/amber vurgulu)
	draw_rect(rect, Color("e5a93b"), false, 1.0)

	# Küçük üçgen ok (Aşağıyı gösterir)
	var arrow_pts = PackedVector2Array([
		Vector2(draw_pos.x - 3, rect.end.y),
		Vector2(draw_pos.x + 3, rect.end.y),
		Vector2(draw_pos.x, rect.end.y + 3)
	])
	draw_colored_polygon(arrow_pts, Color("e5a93b"))

	# Metin çizimi
	var text_pos = Vector2(rect.position.x + (box_w - text_w) * 0.5, rect.position.y + 10.0)
	draw_string(font, text_pos, full_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("f3f4f6"))
