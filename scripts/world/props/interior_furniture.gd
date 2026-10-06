@tool
extends BaseInteractable
class_name InteriorFurniture

# Project T - Etkileşimli İç Mekân Mobilyası (Yatak, Masa, Şömine, Tezgah)

@export_enum("table", "bed", "fireplace", "counter", "bookshelf", "anvil") var furniture_type: String = "table"
@export var interaction_message: String = "Eski ve sağlam bir mobilya."

func _init() -> void:
	super._init()
	prompt_action_text = "İncele"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "furniture_" + str(get_instance_id())
	match furniture_type:
		"table":
			interactable_name = "Ahşap Masa"
		"bed":
			interactable_name = "Kuş Tüyü Yatak"
		"fireplace":
			interactable_name = "Taş Şömine"
		"counter":
			interactable_name = "Han Tezgahı"
		"bookshelf":
			interactable_name = "Kitaplık"
		"anvil":
			interactable_name = "Demirci Örsü"
	super._ready()
	queue_redraw()

func _on_interacted(_player: CharacterBody2D) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and is_inside_tree():
		dm.start_dialogue(interactable_name, interaction_message)

func _draw() -> void:
	match furniture_type:
		"table":
			# Ahşap Masa
			draw_rect(Rect2(-16, -6, 32, 16), Color("5c3a1c"))
			draw_rect(Rect2(-14, -4, 28, 12), Color("784d26"))
			# Bardak / kupa
			draw_circle(Vector2(-4, 0), 2.5, Color("d4a373"))
		"bed":
			# Yatak
			draw_rect(Rect2(-12, -18, 24, 36), Color("4a2d14")) # Karyola
			draw_rect(Rect2(-10, -10, 20, 26), Color("942d2d")) # Kırmızı örtü
			draw_rect(Rect2(-8, -16, 16, 6), Color("e2e8f0"))  # Beyaz yastık
		"fireplace":
			# Taş Şömine ve yanan odun
			draw_rect(Rect2(-20, -24, 40, 28), Color("383e47"))
			draw_rect(Rect2(-14, -18, 28, 20), Color("1a1d24")) # Baca oyuğu
			draw_circle(Vector2(0, -6), 6.0, Color("e67e22"))   # Ateş
			draw_circle(Vector2(0, -7), 3.5, Color("f1c40f"))
		"counter":
			# Han Tezgahı
			draw_rect(Rect2(-32, -8, 64, 16), Color("4a2e16"))
			draw_rect(Rect2(-30, -6, 60, 12), Color("694321"))
		"bookshelf":
			# Kitaplık
			draw_rect(Rect2(-16, -24, 32, 28), Color("3b1f0b"))
			draw_rect(Rect2(-14, -20, 28, 6), Color("2c3e50")) # Kitap sırtları
			draw_rect(Rect2(-14, -10, 28, 6), Color("8e44ad"))
		"anvil":
			# Örs
			draw_rect(Rect2(-10, -8, 20, 14), Color("4b5563"))
			draw_rect(Rect2(-12, -8, 24, 5), Color("6b7280"))
