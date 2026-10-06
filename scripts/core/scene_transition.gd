extends CanvasLayer

# Project T - Ekran Kararması ve Kesintisiz Mekân Geçiş Yöneticisi (SceneTransition)
# Karakter envanteri, zaman akışı ve oyuncu durumunu koruyarak sahneler arası geçiş sağlar

var color_rect: ColorRect
var is_transitioning: bool = false
var next_portal_target_id: String = ""

var saved_inventory_data: Array = []
var saved_time_hour: int = -1
var saved_health: int = 100
var saved_elevation: int = 0

func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func change_scene(scene_path: String, target_portal_id: String = "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	next_portal_target_id = target_portal_id

	# Oyuncu verilerini yedekle
	_cache_player_data()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if "current_state" in player:
			player.current_state = 5 # INVENTORY / INPUT_LOCKED

	# 1. Ekran Karartma (Fade Out)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.22)
	tween.tween_callback(func():
		_load_and_switch(scene_path)
	)

func _cache_player_data() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("get_inventory"):
			var inv = player.get_inventory()
			if inv and inv.has_method("get_save_data"):
				saved_inventory_data = inv.get_save_data()
		saved_health = player.current_health
		saved_elevation = player.elevation_level

func _restore_player_data() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("get_inventory") and not saved_inventory_data.is_empty():
			var inv = player.get_inventory()
			if inv and inv.has_method("load_save_data"):
				inv.load_save_data(saved_inventory_data)
		player.current_health = saved_health
		player.elevation_level = saved_elevation

	# Hedef portal konumuna yerleştir
	if next_portal_target_id != "":
		var portals = get_tree().get_nodes_in_group("scene_portal")
		for p in portals:
			if p.get("portal_tag") == next_portal_target_id:
				if player != null and p.has_method("get_arrival_position"):
					player.global_position = p.get_arrival_position()
				break
		next_portal_target_id = ""

func _load_and_switch(scene_path: String) -> void:
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Sahne yüklenemedi: " + scene_path)
		is_transitioning = false
		color_rect.color.a = 0.0
		return

	# Sahne ağacının hazır olmasını bekle
	await get_tree().process_frame
	await get_tree().process_frame

	_restore_player_data()

	# RegionManager durumunu ve açık dünya nesnelerini yeniden senkronize et
	var rm = get_node_or_null("/root/RegionManager")
	if rm and rm.has_method("resync_world_state"):
		rm.resync_world_state()

	# Kamera limitlerini ve konumunu anında güncelle
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("update_camera_limits"):
			player.update_camera_limits()
		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.reset_smoothing()

	# 2. Ekran Aydınlatma (Fade In)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 0.22)
	tween.tween_callback(func():
		is_transitioning = false
		var p = get_tree().get_first_node_in_group("player")
		if p and "current_state" in p and p.current_state == 5: # INVENTORY / LOCK
			p.current_state = 0 # IDLE
	)
