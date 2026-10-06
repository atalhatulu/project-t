@tool
extends BaseInteractable
class_name CraftingWorkbench

# Project T - Zanaat ve Üretim Tezgâhı (CraftingWorkbench)
# E tuşu ile etkileşime geçilerek odun, demir cevheri gibi malzemelerden balta, sopa üretilir

var economy_manager: Node = null

func _init() -> void:
	super._init()
	prompt_action_text = "Üretim Yap"
	interactable_name = "Demirci Tezgâhı"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "crafting_bench_village"
	super._ready()

func _on_interacted(player: CharacterBody2D) -> void:
	if not player or not player.has_method("get_inventory"):
		return
	
	var inv = player.get_inventory()
	var em = get_node_or_null("/root/EconomyManager") if is_inside_tree() else null
	var dm = get_node_or_null("/root/DialogueManager") if is_inside_tree() else null
	
	if not em:
		return

	# Öncelikli olarak balta üretmeyi dene, yoksa sopa üretmeyi dene
	if em.can_craft_recipe("craft_axe", inv):
		em.craft_recipe("craft_axe", inv)
		if dm:
			dm.start_dialogue("Zanaat Tezgâhı", "2 Odun ve 2 Demir Cevheri kullanarak başarıyla bir [Demirci Baltası] ürettin!")
		var am = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
		if am and am.has_method("play_interact_sound"):
			am.play_interact_sound("chest")
	elif em.can_craft_recipe("craft_club", inv):
		em.craft_recipe("craft_club", inv)
		if dm:
			dm.start_dialogue("Zanaat Tezgâhı", "3 Odun yontarak sağlam bir [Ahşap Sopa] ürettin!")
		var am = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
		if am and am.has_method("play_interact_sound"):
			am.play_interact_sound("chest")
	else:
		if dm:
			dm.start_dialogue("Zanaat Tezgâhı", "Üretim için yeterli malzemen yok.\n• Balta: 2 Odun + 2 Demir Cevheri\n• Sopa: 3 Odun")

func _draw() -> void:
	# Tezgâh gölgesi
	_draw_oval_shadow(Vector2(0, 10), 16.0, 7.0, Color(0, 0, 0, 0.4))
	
	# Ahşap Tezgâh Gövdesi
	draw_rect(Rect2(-16, -8, 32, 18), Color("5c3a1c"), true)
	draw_rect(Rect2(-16, -8, 32, 18), Color("382210"), false, 1.5)
	
	# Üst Örs ve Çekiç Detayı
	draw_rect(Rect2(-8, -12, 16, 5), Color("717b8a"), true)
	draw_rect(Rect2(-2, -7, 4, 3), Color("383e47"), true)
