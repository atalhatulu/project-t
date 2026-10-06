@tool
extends BaseInteractable
class_name MineableRock

# Project T - Maden Damarı / Kazılabilir Taş (Mineable Ore Vein)
# Kılıç saldırıları veya etkileşim ile darbe alır.
# 3 darbede kırılır; çatlama animasyonu, taş/cevher parçaları saçar ve demir cevheri düşürür.

var is_broken: bool = false
var hits_left: int = 3
var max_hits: int = 3
var rock_fragments: Array[Dictionary] = []
var break_anim_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var shake_timer: float = 0.0

@export var possible_loot_ids: Array[String] = ["iron_ore", "cooper_coins"]
@export var loot_count_min: int = 1
@export var loot_count_max: int = 3
var has_dropped_loot: bool = false

var hurtbox: Area2D = null

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "ore_vein_" + str(get_instance_id())
	interactable_name = "Maden Damarı"
	prompt_action_text = "Kaz"
	super._ready()

	# Hurtbox kılıç darbelerini tespit eder (Layer 5: 16, Mask 4: 8)
	hurtbox = get_node_or_null("Hurtbox")
	if not hurtbox:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		hurtbox.collision_layer = 16
		hurtbox.collision_mask = 8
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		hurtbox.add_child(col)
		add_child(hurtbox)

	if not hurtbox.area_entered.is_connected(_on_hurtbox_entered):
		hurtbox.area_entered.connect(_on_hurtbox_entered)

func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		shake_offset = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		if shake_timer <= 0.0:
			shake_offset = Vector2.ZERO
		queue_redraw()

	if is_broken and break_anim_timer > 0.0:
		break_anim_timer -= delta
		for f in rock_fragments:
			f["pos"] += f["vel"] * delta
			f["vel"] = f["vel"].move_toward(Vector2.ZERO, 160.0 * delta)
		queue_redraw()

func _on_hurtbox_entered(_area: Area2D) -> void:
	if not is_broken:
		damage_rock(1)

func _on_interacted(_player: CharacterBody2D) -> void:
	if not is_broken:
		damage_rock(1)

func damage_rock(amount: int = 1) -> void:
	if is_broken:
		return

	hits_left = maxi(0, hits_left - amount)
	shake_timer = 0.2

	# Ses
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_hit_sound"):
			am.play_hit_sound()

	if hits_left <= 0:
		break_rock()
	else:
		# Çatlama efekti için küçük taş parçacıkları fırlat
		for i in range(4):
			var ang = randf() * TAU
			var spd = randf_range(20.0, 45.0)
			rock_fragments.append({
				"pos": Vector2(randf_range(-3, 3), randf_range(-3, 3)),
				"vel": Vector2(cos(ang), sin(ang)) * spd,
				"size": Vector2(randf_range(2, 3), randf_range(2, 3)),
				"color": Color("8a8a8a") if randf() > 0.5 else Color("5a5a60")
			})
		break_anim_timer = 0.5
		queue_redraw()

func break_rock() -> void:
	is_broken = true
	current_state = "broken"
	is_interactable = false

	# Fizik çarpışmalarını deferred kapat (flushing queries hatasını önler)
	set_deferred("collision_layer", 0)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if prompt_node:
		prompt_node.hide_prompt()

	# Kırılma sesi
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_break_sound"):
			am.play_break_sound()

	# Parçacıklar
	rock_fragments.clear()
	break_anim_timer = 1.2
	for i in range(12):
		var ang = randf() * TAU
		var spd = randf_range(35.0, 90.0)
		rock_fragments.append({
			"pos": Vector2(randf_range(-6, 6), randf_range(-6, 4)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"size": Vector2(randf_range(2, 4), randf_range(2, 4)),
			"color": Color("7c756f") if randf() > 0.4 else Color("b87333") # Taş ve bakır/demir ışıltısı
		})

	# Ganimet düşür
	if not has_dropped_loot and not possible_loot_ids.is_empty():
		has_dropped_loot = true
		call_deferred("_spawn_rock_loot")

	state_changed.emit(current_state)
	_apply_state()

func _spawn_rock_loot() -> void:
	var count = randi_range(loot_count_min, loot_count_max)
	for i in range(count):
		var picked_id = possible_loot_ids.pick_random()
		if picked_id == "":
			continue

		var item_scene = preload("res://scenes/props/world_item.tscn")
		var world_item = item_scene.instantiate() as WorldItem
		world_item.setup_item(picked_id, 1)

		var p_parent = get_parent()
		if p_parent != null:
			p_parent.add_child(world_item)
		elif is_inside_tree():
			get_tree().root.add_child(world_item)
		else:
			return

		var offset_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.8)).normalized()
		var dest = global_position + offset_dir * randf_range(16.0, 32.0)
		world_item.launch_bounce(global_position, dest, 20.0, 0.4)

func _apply_state() -> void:
	is_broken = (current_state == "broken")
	if is_broken:
		set_deferred("collision_layer", 0)
		is_interactable = false
	queue_redraw()

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["is_broken"] = is_broken
	data["hits_left"] = hits_left
	data["has_dropped_loot"] = has_dropped_loot
	return data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_broken = data.get("is_broken", false)
	hits_left = data.get("hits_left", 3)
	has_dropped_loot = data.get("has_dropped_loot", false)
	_apply_state()

func _draw() -> void:
	var pos = shake_offset
	if not is_broken:
		# Gölge
		_draw_oval_shadow(pos + Vector2(0, 7), 14.0, 6.0, Color(0, 0, 0, 0.4))
		# Kaya taban gövdesi
		draw_circle(pos + Vector2(0, 1), 10.0, Color("4a4a52"))
		draw_circle(pos + Vector2(-2, -1), 8.0, Color("62626e"))
		# Demir damar parlaklıkları / çentikleri
		draw_rect(Rect2(pos + Vector2(-4, -3), Vector2(3, 3)), Color("9fa4a6"))
		draw_rect(Rect2(pos + Vector2(2, 0), Vector2(4, 2)), Color("b87333"))
		draw_rect(Rect2(pos + Vector2(-1, 4), Vector2(3, 2)), Color("c0c0c8"))

		# Darbe çatlakları
		if hits_left < max_hits:
			var crack_col = Color(0.1, 0.1, 0.1, 0.8)
			draw_line(pos + Vector2(-5, -4), pos + Vector2(0, 2), crack_col, 1.5)
		if hits_left == 1:
			var crack_col = Color(0.1, 0.1, 0.1, 0.9)
			draw_line(pos + Vector2(0, 2), pos + Vector2(5, 5), crack_col, 1.5)
			draw_line(pos + Vector2(2, -5), pos + Vector2(1, 0), crack_col, 1.2)
	else:
		# Kırılmış kalıntı
		_draw_oval_shadow(pos + Vector2(0, 4), 11.0, 4.0, Color(0, 0, 0, 0.25))
		draw_circle(pos + Vector2(-3, 2), 4.0, Color("4a4a52"))
		draw_circle(pos + Vector2(4, 1), 3.0, Color("55555c"))
		draw_circle(pos + Vector2(0, 4), 2.5, Color("3a3a40"))

	# Havada sıçrayan parçalar
	if break_anim_timer > 0.0:
		for f in rock_fragments:
			draw_rect(Rect2(f["pos"], f["size"]), f["color"])
