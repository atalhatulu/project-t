@tool
extends BaseInteractable
class_name AncientRuin

# Project T - İncelenebilen Kadim Harabeler ve Dikilitaşlar
# Keşif ve çevre anlatısı (environmental storytelling) sunar

@export var ruin_title: String = "Kadim Dikilitaş Harabesi"
@export_multiline var ruin_lore_text: String = "Yosun tutmuş taş yüzeyinde rüzgar ve şimşek tasvirleri oyulmuş. Binlerce yıl önce bu vadide yaşamış eski bir halkın sınır anıtı gibi duruyor."

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "ruin_" + str(get_instance_id())
	interactable_name = ruin_title
	prompt_action_text = "İncele"
	super._ready()

func _on_interacted(player: CharacterBody2D) -> void:
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_interact_sound("default")

		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue(ruin_title, ruin_lore_text)

func _draw() -> void:
	_draw_oval_shadow(Vector2(0, 6), 18.0, 8.0, Color(0, 0, 0, 0.45))

	var col_stone_dark = Color("383e47")
	var col_stone_mid = Color("525a66")
	var col_stone_light = Color("717b8a")
	var col_rune = Color("68d8d6")
	var col_moss = Color("38572b")

	# Yıkık monolit tabanı
	var pts_pillar = PackedVector2Array([
		Vector2(-12, 6), Vector2(-10, -22), Vector2(6, -26),
		Vector2(12, -18), Vector2(10, 6)
	])
	draw_colored_polygon(pts_pillar, col_stone_mid)
	# Gölgeli sol yüzey
	draw_line(Vector2(-11, 5), Vector2(-9, -21), col_stone_dark, 2.5)
	# Kırık üst yüzey ve ışık
	draw_line(Vector2(-10, -22), Vector2(6, -26), col_stone_light, 2.0)
	# Yosun lekeleri
	draw_circle(Vector2(-6, 2), 3.5, col_moss)
	draw_circle(Vector2(5, 0), 2.5, col_moss)
	# Taş üzerindeki parlayan soluk runik sembol
	draw_line(Vector2(0, -14), Vector2(0, -6), col_rune, 1.5)
	draw_line(Vector2(-3, -10), Vector2(3, -10), col_rune, 1.5)
