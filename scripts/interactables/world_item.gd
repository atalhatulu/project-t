@tool
extends BaseInteractable
class_name WorldItem

# Project T - Dünyada Fiziksel Olarak Duran Eşya (WorldItem)
# E tuşu ile toplanabilir, envanter doluysa yerde kalır
# Düşme/sıçrama yay animasyonu (bounce/drop arc) ve pixel art eşya görseli

signal picked_up(player: CharacterBody2D, item_id: String, amount: int)

@export var item_id: String = "wood"
@export var amount: int = 1
@export var is_owned: bool = false
@export var owner_faction: String = "villagers" # "villagers", "guards", etc.

# Sıçrama ve yay animasyonu parametreleri
var is_bouncing: bool = false
var bounce_timer: float = 0.0
var bounce_duration: float = 0.45
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var bounce_height: float = 14.0
var current_arc_y: float = 0.0

# Yerde süzülme / hafif parıldama animasyonu
var idle_float_timer: float = 0.0

func _init() -> void:
	super._init()
	prompt_action_text = "Topla"
	current_state = "idle"

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "world_item_" + str(get_instance_id())
	_update_item_presentation()
	super._ready()

func setup_item(p_item_id: String, p_amount: int = 1) -> void:
	item_id = p_item_id
	amount = p_amount
	_update_item_presentation()
	queue_redraw()

func _update_item_presentation() -> void:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data:
		interactable_name = item_data.name + (" x" + str(amount) if amount > 1 else "")
	else:
		interactable_name = item_id

func get_action_prompt_text() -> String:
	if is_owned:
		return "Çal: " + interactable_name
	return "Al: " + interactable_name

func launch_bounce(from_pos: Vector2, to_pos: Vector2, height: float = 14.0, duration: float = 0.45) -> void:
	start_pos = from_pos
	target_pos = to_pos
	global_position = from_pos
	bounce_height = height
	bounce_duration = duration
	bounce_timer = 0.0
	is_bouncing = true
	is_interactable = false

func _process(delta: float) -> void:
	if is_bouncing:
		bounce_timer += delta
		var t = clampf(bounce_timer / bounce_duration, 0.0, 1.0)
		# X-Y taban interpolasyonu
		var base_pos = start_pos.lerp(target_pos, t)
		# Parabolik yay yüksekliği: sin(t * PI)
		current_arc_y = -sin(t * PI) * bounce_height
		global_position = base_pos + Vector2(0, current_arc_y)

		if t >= 1.0:
			is_bouncing = false
			global_position = target_pos
			current_arc_y = 0.0
			is_interactable = true
			if is_inside_tree():
				var am = get_node_or_null("/root/AudioManager")
				if am:
					am.play_footstep(AudioManager.SurfaceType.GRASS)
		queue_redraw()
	else:
		idle_float_timer += delta
		if idle_float_timer > TAU:
			idle_float_timer -= TAU
		queue_redraw()

func _on_interacted(player: CharacterBody2D) -> void:
	if not is_interactable or is_bouncing:
		return

	if player != null and player.has_method("get_inventory"):
		var inv: Inventory = player.get_inventory()
		if inv != null:
			if not inv.can_add_item(item_id, amount):
				if is_inside_tree():
					var dm = get_node_or_null("/root/DialogueManager")
					if dm:
						dm.start_dialogue("Envanter Dolu", "Çantanda yer yok! " + interactable_name + " yerde kaldı.")
				return

			var remaining = inv.add_item(item_id, amount)
			if remaining <= 0:
				picked_up.emit(player, item_id, amount)
				if is_inside_tree():
					if is_owned:
						var fm = get_node_or_null("/root/FactionManager")
						if fm:
							fm.report_crime("theft", owner_faction, global_position, player)
					var qm = get_node_or_null("/root/QuestManager")
					if qm:
						qm.advance_quest_condition(QuestData.ConditionType.ITEM_COLLECT, item_id, amount)
					var am = get_node_or_null("/root/AudioManager")
					if am:
						am.play_interact_sound("plant")
				queue_free()
				return
			else:
				# Kısmi ekleme durumu olursa (asla olmamalı can_add_item kontrolü sayesinde)
				amount = remaining
				_update_item_presentation()

func _draw() -> void:
	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
		return

	# Hafif taban gölgesi (nesne havadayken küçülür, yerdeyken sabittir)
	var shadow_scale = 1.0
	if is_bouncing:
		shadow_scale = clampf(1.0 - (-current_arc_y / (bounce_height * 1.5)), 0.3, 1.0)
	var shadow_rect = Rect2(-6 * shadow_scale, -2 * shadow_scale - current_arc_y, 12 * shadow_scale, 5 * shadow_scale)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.35))

	# Yerde hafif süzülme nefesi (idle bobbing)
	var bob_y = 0.0
	if not is_bouncing:
		bob_y = sin(idle_float_timer * 3.0) * 1.5

	var draw_pos = Vector2(0, bob_y)

	# Eşya İkon Çizimi (Pixel Art stilinde mini şekil)
	match item_data.icon_shape:
		"circle":
			draw_circle(draw_pos, 5.0, item_data.icon_color)
			draw_circle(draw_pos, 2.5, item_data.secondary_color)
		"rect":
			draw_rect(Rect2(draw_pos.x - 5, draw_pos.y - 4, 10, 8), item_data.icon_color)
			draw_rect(Rect2(draw_pos.x - 3, draw_pos.y - 2, 6, 4), item_data.secondary_color)
		"gem":
			var pts = PackedVector2Array([
				draw_pos + Vector2(0, -6),
				draw_pos + Vector2(5, 0),
				draw_pos + Vector2(0, 6),
				draw_pos + Vector2(-5, 0)
			])
			draw_colored_polygon(pts, item_data.icon_color)
			draw_circle(draw_pos, 2.0, item_data.secondary_color)
		"cross":
			draw_rect(Rect2(draw_pos.x - 1.5, draw_pos.y - 6, 3, 12), item_data.icon_color)
			draw_rect(Rect2(draw_pos.x - 5, draw_pos.y - 2, 10, 3), item_data.secondary_color)
		"potion":
			draw_rect(Rect2(draw_pos.x - 1.5, draw_pos.y - 6, 3, 3), item_data.secondary_color)
			draw_circle(draw_pos + Vector2(0, 1), 4.5, item_data.icon_color)
		_:
			draw_circle(draw_pos, 4.0, item_data.icon_color)

	# Adet > 1 ise küçük adet gösterge noktası
	if amount > 1:
		draw_circle(draw_pos + Vector2(4, 4), 2.0, Color.WHITE)

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["item_id"] = item_id
	data["amount"] = amount
	data["global_position_x"] = global_position.x
	data["global_position_y"] = global_position.y
	return data
