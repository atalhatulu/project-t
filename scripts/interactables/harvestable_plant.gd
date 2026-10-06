@tool
extends BaseInteractable
class_name HarvestablePlant

# Project T - Toplanabilen ve Yeniden Yetişen Yabani Bitkiler
# Durumlar: "ready", "harvested"
# TimeManager ile senkronize yeniden büyüme süresi

@export var plant_name: String = "Kızıl Vadi Otu"
@export var item_id: String = "red_herb"
@export var harvest_amount: int = 1
@export var respawn_game_hours: float = 6.0

var respawn_timer_hours: float = 0.0

func _init() -> void:
	super._init()
	prompt_action_text = "Topla"
	current_state = "ready"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "plant_" + str(get_instance_id())
	interactable_name = plant_name
	super._ready()

	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.hour_changed.connect(_on_hour_changed)

func _on_hour_changed(_new_hour: int) -> void:
	if current_state == "harvested":
		respawn_timer_hours -= 1.0
		if respawn_timer_hours <= 0.0:
			respawn_plant()

func respawn_plant() -> void:
	current_state = "ready"
	is_interactable = true
	state_changed.emit(current_state)
	_apply_state()

func _on_interacted(player: CharacterBody2D) -> void:
	if current_state != "ready":
		return

	# Eğer oyuncunun envanteri varsa ve doluysa toplanamaz!
	if player != null and player.get("inventory") != null:
		var inv: Inventory = player.get("inventory")
		if not inv.can_add_item(item_id, harvest_amount):
			var dm = get_node_or_null("/root/DialogueManager")
			if dm:
				dm.start_dialogue("Envanter Dolu", "Çantan tamamen dolu! " + plant_name + " toplayabilmek için yer açmalısın.")
			return
		inv.add_item(item_id, harvest_amount)

	current_state = "harvested"
	is_interactable = false
	respawn_timer_hours = respawn_game_hours

	if prompt_node:
		prompt_node.hide_prompt()

	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_interact_sound("plant")

		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue("Hasat Edildi", "Toprağın kokusunu taşıyan taze " + plant_name + " topladın ve çantana koydun.")

	state_changed.emit(current_state)
	_apply_state()

func _apply_state() -> void:
	is_interactable = (current_state == "ready")
	queue_redraw()

func _draw() -> void:
	_draw_oval_shadow(Vector2(0, 3), 7.0, 3.5, Color(0, 0, 0, 0.3))

	if current_state == "ready":
		# Dolgun şifalı bitki
		# Saplar
		draw_line(Vector2(0, 2), Vector2(-4, -6), Color("2e5a27"), 1.5)
		draw_line(Vector2(0, 2), Vector2(4, -7), Color("35692d"), 1.5)
		draw_line(Vector2(0, 2), Vector2(0, -9), Color("4b8c3f"), 1.5)
		# Yapraklar
		draw_circle(Vector2(-5, -6), 2.5, Color("35692d"))
		draw_circle(Vector2(5, -7), 2.5, Color("4b8c3f"))
		draw_circle(Vector2(0, -10), 3.0, Color("529e46"))
		# Şifalı Çiçek Taçları (Canlı kırmızı/mor polen)
		draw_rect(Rect2(-1, -12, 3, 3), Color("e74c3c"))
		draw_rect(Rect2(-4, -8, 2, 2), Color("f39c12"))
	else:
		# Toplanmış, sadece küçük filiz kökü
		draw_line(Vector2(0, 2), Vector2(-1, -1), Color("3d5a2b"), 1.0)
		draw_line(Vector2(0, 2), Vector2(2, 0), Color("2b401e"), 1.0)
