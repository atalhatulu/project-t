@tool
extends BaseInteractable
class_name GrapplePoint

# Project T - Kanca Tutunma Noktası (GrapplePoint)
# Oyuncunun kanca ile boşluk veya uçurum karşısına çekilebilmesini sağlar.

signal player_hooked(player: CharacterBody2D)

@export var point_id: String = "grapple_point_01"
@export var is_active: bool = true
@export var arrival_offset: Vector2 = Vector2(0, 14) # Çekilince oyuncunun ineceği nokta

func _init() -> void:
	super._init()
	prompt_action_text = "Kanca At"
	interactable_name = "Kadim Tutunma Halkası"

func _ready() -> void:
	add_to_group("grapple_point")
	if interactable_id == "":
		interactable_id = point_id
	super._ready()

func get_action_prompt_text() -> String:
	return "Kanca At (E)"

func _on_interacted(player: CharacterBody2D) -> void:
	if not is_active or player == null:
		return
	
	# Oyuncunun envanterinde grappling_hook var mı?
	if player.has_method("get_inventory"):
		var inv = player.get_inventory()
		if not inv or not inv.has_item("grappling_hook", 1):
			var dm = get_node_or_null("/root/DialogueManager")
			if dm and is_inside_tree():
				dm.start_dialogue("Kanca Gerekiyor", "Karşıya geçmek için sağlam bir kancaya ihtiyacın var!")
			return

	# Oyuncuyu bu noktaya doğru hızla çek
	if player.has_method("grapple_to_point"):
		player.grapple_to_point(global_position + arrival_offset)
		player_hooked.emit(player)
		
		var am = get_node_or_null("/root/AudioManager")
		if am and is_inside_tree() and am.has_method("play_interact_sound"):
			am.play_interact_sound("chest")

func _draw() -> void:
	# Taban gölgesi
	_draw_oval_shadow(Vector2(0, 4), 8.0, 3.5, Color(0, 0, 0, 0.4))
	
	# Direk kaidesi
	draw_rect(Rect2(-4, -6, 8, 10), Color("334155"))
	
	# Metalik parlak halka
	draw_arc(Vector2(0, -9), 6.0, 0, TAU, 16, Color("38bdf8"), 2.0)
	draw_circle(Vector2(0, -9), 2.0, Color("f8fafc"))
