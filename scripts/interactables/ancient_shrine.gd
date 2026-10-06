@tool
extends BaseInteractable
class_name AncientShrine

# Project T - Kadim Dağ Mührü / Sunak (Ancient Mountain Shrine)
# Oyuncudan dağ çiçeği veya kadim madalyon adak olarak kabul eder.
# Adak sunulduğunda sunak aktifleşir, parlar ve oyuncuyu tamamen iyileştirir.

var is_activated: bool = false
var glow_intensity: float = 0.0
var glow_direction: float = 1.0

@export var shrine_name: String = "Kadim Dağ Sunağı"
@export var accepted_item_ids: Array[String] = ["mountain_flower", "ancient_medallion"]

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "ancient_shrine_" + str(get_instance_id())
	interactable_name = shrine_name
	prompt_action_text = "Adak Sun" if not is_activated else "Kutsan"
	super._ready()
	_apply_state()

func _process(delta: float) -> void:
	if is_activated:
		glow_intensity += delta * glow_direction * 1.5
		if glow_intensity >= 1.0:
			glow_intensity = 1.0
			glow_direction = -1.0
		elif glow_intensity <= 0.3:
			glow_intensity = 0.3
			glow_direction = 1.0
		queue_redraw()

func _on_interacted(player: CharacterBody2D) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	var am = get_node_or_null("/root/AudioManager")

	if is_activated:
		# Zaten aktif ise huzur ve hafif kutsama verir
		if player and player.has_method("heal"):
			player.heal(1)
		if dm:
			dm.start_dialogue(shrine_name, "Sunağın etrafındaki kadim aura sakin ve koruyucu bir sıcaklık yayıyor.")
		return

	# Envanterde kabul edilen adak var mı kontrol et
	var found_item_id = ""
	var inv: Object = null
	if player:
		if "inventory" in player and player.inventory != null:
			inv = player.inventory
		elif player.get("inventory") != null:
			inv = player.get("inventory")
		elif player.has_node("Inventory"):
			inv = player.get_node("Inventory")

	if inv != null:
		for item_id in accepted_item_ids:
			if inv.has_method("get_item_count") and inv.get_item_count(item_id) > 0:
				found_item_id = item_id
				break
			elif inv.has_method("has_item") and inv.has_item(item_id):
				found_item_id = item_id
				break

	if found_item_id != "" and inv != null:
		# Adağı tüket
		if inv.has_method("remove_item"):
			inv.remove_item(found_item_id, 1)

		is_activated = true
		current_state = "activated"
		prompt_action_text = "Kutsan"

		if am and am.has_method("play_item_pickup_sound"):
			am.play_item_pickup_sound()

		# Oyuncuyu tamamen iyileştir
		if player.has_method("heal"):
			player.heal(99)

		if dm:
			var item_label = "Dağ Çiçeği" if found_item_id == "mountain_flower" else "Kadim Madalyon"
			dm.start_dialogue(
				shrine_name,
				"Sunağa " + item_label + " sundun. Mavi kadim rünler parıldamaya başladı ve bedenini saran derin bir şifa enerjisi hissettin!"
			)

		state_changed.emit(current_state)
		_apply_state()
	else:
		if dm:
			dm.start_dialogue(
				shrine_name,
				"Sunak sessiz ve uykuda. Üzerinde solgun bir çiçek ve madalyon motifi kazınmış. Bir adak istiyor gibi duruyor."
			)

func _apply_state() -> void:
	is_activated = (current_state == "activated")
	prompt_action_text = "Kutsan" if is_activated else "Adak Sun"
	queue_redraw()

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["is_activated"] = is_activated
	return data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_activated = data.get("is_activated", false)
	_apply_state()

func _draw() -> void:
	# Gölge
	_draw_oval_shadow(Vector2(0, 8), 24.0, 10.0, Color(0, 0, 0, 0.45))

	var col_base = Color("323438")
	var col_altar = Color("4b5059")
	var col_top = Color("686f7c")
	var col_rune_active = Color(0.2, 0.8, 1.0, 0.8 + 0.2 * glow_intensity)
	var col_rune_dormant = Color(0.3, 0.4, 0.45, 0.5)

	# Sunak taban kaidesi
	var base_pts = PackedVector2Array([
		Vector2(-16, 6), Vector2(-12, -4), Vector2(12, -4),
		Vector2(16, 6), Vector2(14, 10), Vector2(-14, 10)
	])
	draw_colored_polygon(base_pts, col_base)

	# Sunak sütun gövdesi
	draw_rect(Rect2(-10, -16, 20, 13), col_altar)
	draw_line(Vector2(-10, -16), Vector2(-10, -3), Color("26282b"), 2.0)
	draw_line(Vector2(10, -16), Vector2(10, -3), Color("5a606b"), 2.0)

	# Üst adak kasesi / tablası
	var bowl_pts = PackedVector2Array([
		Vector2(-14, -16), Vector2(-12, -22), Vector2(12, -22),
		Vector2(14, -16)
	])
	draw_colored_polygon(bowl_pts, col_top)

	# Rünik desenler ve parıldama
	var cur_rune_col = col_rune_active if is_activated else col_rune_dormant
	draw_circle(Vector2(0, -10), 3.0, cur_rune_col)
	draw_line(Vector2(0, -15), Vector2(0, -5), cur_rune_col, 1.5)
	draw_line(Vector2(-5, -10), Vector2(5, -10), cur_rune_col, 1.5)

	if is_activated:
		# Sunak tepesinde parlayan sihirli ışık
		var aura_col = Color(0.3, 0.85, 1.0, 0.25 * glow_intensity)
		draw_circle(Vector2(0, -22), 8.0 + 3.0 * glow_intensity, aura_col)
		draw_circle(Vector2(0, -22), 3.5, Color(0.8, 0.95, 1.0, 0.9))
