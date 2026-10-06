@tool
extends BaseInteractable
class_name BreakableCrate

# Project T - Kırılabilen Ahşap Kasa
# E tuşu ile etkileşime girilerek veya kılıç saldırısıyla kırılır
# Parçacık efekti ve tahta parçaları saçar

var is_broken: bool = false
var wood_splinters: Array[Dictionary] = []
var break_anim_timer: float = 0.0

# Kırılınca düşebilecek ganimetler
@export var loot_chance: float = 0.85
@export var possible_loot_ids: Array[String] = ["wood", "wild_apple", "iron_ore"]
var has_dropped_loot: bool = false

var hurtbox: Area2D = null

func _ready() -> void:
	if interactable_id == "":
		interactable_id = "crate_" + str(get_instance_id())
	interactable_name = "Ahşap Kasa"
	prompt_action_text = "Parçala"
	super._ready()

	# Kılıç saldırısını algılamak için Hurtbox (Layer 5: Hurtboxes, Mask 4: Hitboxes)
	hurtbox = get_node_or_null("Hurtbox")
	if not hurtbox:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		hurtbox.collision_layer = 16 # Layer 5
		hurtbox.collision_mask = 8   # Layer 4: Hitbox
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(16, 16)
		col.shape = shape
		hurtbox.add_child(col)
		add_child(hurtbox)

	hurtbox.area_entered.connect(_on_hurtbox_entered)

func _process(delta: float) -> void:
	if is_broken and break_anim_timer > 0.0:
		break_anim_timer -= delta
		for s in wood_splinters:
			s["pos"] += s["vel"] * delta
			s["vel"] = s["vel"].move_toward(Vector2.ZERO, 140.0 * delta)
		queue_redraw()

func _on_hurtbox_entered(area: Area2D) -> void:
	if not is_broken:
		break_crate()

func _on_interacted(player: CharacterBody2D) -> void:
	if not is_broken:
		break_crate()

func break_crate() -> void:
	is_broken = true
	current_state = "broken"
	is_interactable = false

	# Fizik çarpışmasını kapat
	collision_layer = 0

	if prompt_node:
		prompt_node.hide_prompt()

	# Ses
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am:
			am.play_break_sound()

	# Tahta kıymık parçacıkları oluştur
	wood_splinters.clear()
	break_anim_timer = 1.2
	for i in range(10):
		var ang = randf() * TAU
		var spd = randf_range(30.0, 75.0)
		wood_splinters.append({
			"pos": Vector2(randf_range(-4, 4), randf_range(-6, 2)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"size": Vector2(randf_range(2, 4), randf_range(2, 4)),
			"color": Color("5c3a1c") if randf() > 0.4 else Color("784d26")
		})

	# Ganimet eşyası düşürme
	if not has_dropped_loot and not possible_loot_ids.is_empty() and randf() <= loot_chance:
		has_dropped_loot = true
		_spawn_crate_loot()

	state_changed.emit(current_state)
	_apply_state()

func _spawn_crate_loot() -> void:
	var picked_id = possible_loot_ids.pick_random()
	if picked_id == "":
		return

	var world_item = preload("res://scenes/props/world_item.tscn").instantiate() as WorldItem
	world_item.setup_item(picked_id, 1)

	var p_parent = get_parent()
	if p_parent != null:
		p_parent.add_child(world_item)
	elif is_inside_tree():
		get_tree().root.add_child(world_item)
	else:
		return

	# Kasadan dışarı doğru sıçrama yönü
	var offset_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.8)).normalized()
	var dest = global_position + offset_dir * randf_range(16.0, 26.0)
	world_item.launch_bounce(global_position, dest, 16.0, 0.4)

func _apply_state() -> void:
	is_broken = (current_state == "broken")
	if is_broken:
		collision_layer = 0
		is_interactable = false
	queue_redraw()

func _draw() -> void:
	if not is_broken:
		# Sağlam Kasa
		_draw_oval_shadow(Vector2(0, 5), 11.0, 5.0, Color(0, 0, 0, 0.4))
		# Ahşap Kutu
		draw_rect(Rect2(-8, -10, 16, 15), Color("5c3a1c"))
		draw_rect(Rect2(-8, -10, 16, 2), Color("784d26")) # Üst ışık
		# Tahta Çapraz Çerçeveler
		draw_rect(Rect2(-7, -9, 14, 13), Color("4a2d14"), false, 1.5)
		draw_line(Vector2(-6, -8), Vector2(6, 3), Color("784d26"), 1.5)
	else:
		# Kırılmış Tahta Döküntüsü
		_draw_oval_shadow(Vector2(0, 4), 10.0, 4.0, Color(0, 0, 0, 0.25))
		draw_rect(Rect2(-6, -1, 5, 3), Color("4a2d14"))
		draw_rect(Rect2(2, -2, 6, 2), Color("5c3a1c"))
		draw_rect(Rect2(-2, 1, 4, 2), Color("784d26"))

		# Sıçrayan parçacıklar
		if break_anim_timer > 0.0:
			for s in wood_splinters:
				draw_rect(Rect2(s["pos"], s["size"]), s["color"])
