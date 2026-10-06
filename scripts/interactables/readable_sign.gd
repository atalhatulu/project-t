@tool
extends BaseInteractable
class_name ReadableSign

# Project T - Okunabilen Ahşap ve Taş Yol Tabelaları

@export_multiline var sign_message: String = "Kuzey: Kadim Orman Açıklığı\nDoğu: Antik Gözetleme Kulesi ve Mağara\nBatı: Köy Meydanı & Kızıl Han"

func _init() -> void:
	super._init()
	prompt_action_text = "Oku"
	interactable_name = "Eski Tabela"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "sign_" + str(get_instance_id())
	super._ready()

func _on_interacted(player: CharacterBody2D) -> void:
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_interact_sound("sign")

		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(interactable_name, sign_message)

func _draw() -> void:
	_draw_oval_shadow(Vector2(0, 4), 8.0, 3.5, Color(0, 0, 0, 0.35))

	var col_post = Color("4a3319")
	var col_board = Color("6d4c27")
	var col_board_light = Color("855f34")
	var col_text_lines = Color("382312")

	# Direk
	draw_rect(Rect2(-2, -8, 4, 12), col_post)
	# Tabela Levhası
	draw_rect(Rect2(-12, -18, 24, 12), col_board)
	draw_rect(Rect2(-11, -17, 22, 2), col_board_light) # Üst ışık
	# Kazınmış yazı sembol çizgileri
	draw_line(Vector2(-8, -13), Vector2(8, -13), col_text_lines, 1.0)
	draw_line(Vector2(-8, -9), Vector2(4, -9), col_text_lines, 1.0)
