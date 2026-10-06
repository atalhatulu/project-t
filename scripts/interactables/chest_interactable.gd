@tool
extends BaseInteractable
class_name ChestInteractable

# Project T - Açılıp Kapanabilen Hazine / Malzeme Sandığı
# Durumlar: "closed", "opened"

@export var item_reward_name: String = "Demir Parçası & Eski Madalyon"
@export var reward_item_ids: Array[String] = ["iron_ore", "ancient_medallion"]
@export var reward_item_amounts: Array[int] = [3, 1]
@export var is_owned: bool = false
@export var owner_faction: String = "villagers"
var is_looted: bool = false
var is_open: bool = false

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "chest_" + str(get_instance_id())
	interactable_name = "Ahşap Sandık"
	prompt_action_text = "Aç"
	super._ready()

func get_action_prompt_text() -> String:
	if is_open:
		return "Kapat"
	if is_owned and not is_looted:
		return "Çal (Aç)"
	return "Aç"

func _on_interacted(player: CharacterBody2D) -> void:
	# Eğer ilk kez açılıyorsa ve eşya varsa, envanter kontrolü yap
	if not is_looted and not is_open and player != null and player.get("inventory") != null:
		var inv: Inventory = player.get("inventory")
		# Bütün ödüller için yer var mı?
		if not inv.can_add_items(reward_item_ids, reward_item_amounts):
			if is_inside_tree():
				var dm = get_node_or_null("/root/DialogueManager")
				if dm:
					dm.start_dialogue("Envanter Dolu", "Sandıktaki ganimetleri alabilmek için çantanda yeterli boş yer yok!")
			return

		# Eşyaları envantere aktar
		for i in range(reward_item_ids.size()):
			var amt = reward_item_amounts[i] if i < reward_item_amounts.size() else 1
			inv.add_item(reward_item_ids[i], amt)
		is_looted = true

		if is_owned and is_inside_tree():
			var fm = get_node_or_null("/root/FactionManager")
			if fm:
				fm.report_crime("theft", owner_faction, global_position, player)

	is_open = not is_open
	current_state = "opened" if is_open else "closed"

	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_interact_sound("chest")

		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			if is_open:
				if is_looted:
					dm.start_dialogue(interactable_name, "Sandığın paslı kapağını gıcırdayarak açtın. " + item_reward_name + " çantana eklendi!")
				else:
					dm.start_dialogue(interactable_name, "Sandığı açtın ancak içi boş görünüyor.")
			else:
				dm.start_dialogue(interactable_name, "Sandığın kapağını dikkatlice kapattın.")

	state_changed.emit(current_state)
	_apply_state()

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["is_looted"] = is_looted
	return data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	if data.has("is_looted"):
		is_looted = data["is_looted"]


func _apply_state() -> void:
	is_open = (current_state == "opened")
	if prompt_node:
		prompt_node.prompt_text = get_action_prompt_text()
	queue_redraw()

func _draw() -> void:
	# 1. Taban Gölgesi
	_draw_oval_shadow(Vector2(0, 6), 14.0, 6.0, Color(0, 0, 0, 0.4))

	var col_wood_dark = Color("3d2612")
	var col_wood_mid = Color("5c3a1c")
	var col_wood_light = Color("784d26")
	var col_gold = Color("d4af37")
	var col_gold_dark = Color("8c7324")

	if not is_open:
		# Kapalı Sandık
		# Ana Gövde
		draw_rect(Rect2(-10, -8, 20, 14), col_wood_mid)
		# Üst Kapak
		draw_rect(Rect2(-11, -12, 22, 5), col_wood_light)
		# Yan gölge şeritleri
		draw_rect(Rect2(-10, -8, 2, 14), col_wood_dark)
		draw_rect(Rect2(8, -8, 2, 14), col_wood_dark)
		# Metal Kilit ve Şeritler
		draw_rect(Rect2(-7, -12, 2, 18), col_gold_dark)
		draw_rect(Rect2(5, -12, 2, 18), col_gold_dark)
		draw_rect(Rect2(-2, -8, 4, 5), col_gold) # Kilit mandalı
	else:
		# Açık Sandık
		# Sandık İçi (Karanlık derinlik)
		draw_rect(Rect2(-10, -6, 20, 12), col_wood_dark)
		draw_rect(Rect2(-8, -4, 16, 6), Color("150d06")) # İç oyuk
		# Açık Kapak (Geriye doğru kalkık)
		draw_rect(Rect2(-11, -16, 22, 6), col_wood_light)
		draw_rect(Rect2(-7, -16, 2, 6), col_gold_dark)
		draw_rect(Rect2(5, -16, 2, 6), col_gold_dark)
		# Ön Çerçeve
		draw_rect(Rect2(-10, 0, 20, 6), col_wood_mid)
		draw_rect(Rect2(-2, 0, 4, 3), col_gold)
