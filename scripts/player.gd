extends CharacterBody2D

# Project T - Gelişmiş Karakter Durum Makinesi (State Machine)
# İyileştirilmiş hareket ivmesi, zemin algılama (çimen/toprak/taş/ahşap), adım parçacıkları ve ayak sesleri

enum State { IDLE, MOVE, ROLL, ATTACK, TALKING, INVENTORY, SWIM, CLIMB, HURT, GRAPPLE, DEAD }
var current_state: State = State.IDLE
var hurt_timer: float = 0.0

# Kanca (Grapple) Parametreleri
var grapple_target_pos: Vector2 = Vector2.ZERO
@export var grapple_speed: float = 340.0

signal health_changed(current_hp: int, max_hp: int)
signal player_died
signal player_respawned

@export var max_health: int = 100
@export var current_health: int = 100
var respawn_point: Vector2 = Vector2(480, 320) # Köy Meydanı
var invincibility_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

@export var max_speed: float = 125.0
@export var swim_speed: float = 65.0 # Suda yavaşlama
@export var climb_speed: float = 45.0 # Tırmanma hızı
@export var acceleration: float = 900.0
@export var friction: float = 1100.0

# Yüzme ve Tırmanma Parametreleri
var current_cliff: ClimbableCliff = null
var elevation_level: int = 0 # 0: Zemin, 1: Tepe / Kayalık
var is_in_water: bool = false
var is_in_deep_water: bool = false
var water_splash_timer: float = 0.0

# Yuvarlanma / Kaçınma (Roll)
@export var roll_speed: float = 235.0
@export var roll_duration: float = 0.28
var roll_timer: float = 0.0
var roll_direction: Vector2 = Vector2.DOWN

# Saldırı (Attack)
@export var attack_duration: float = 0.32
var attack_timer: float = 0.0

var facing_direction: Vector2 = Vector2.DOWN

# Kamera ve Game Feel Parametreleri
@onready var camera: Camera2D = get_node_or_null("Camera2D")
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var hitstop_timer: float = 0.0

@export var shallow_water_speed: float = 85.0 # Sığ suda direnç hissi

# Ayak sesi ve zemin adımı zamanlayıcısı
var footstep_distance_accumulator: float = 0.0
const STEP_DISTANCE: float = 16.0

@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var step_particles: Node2D = $StepParticles
var inventory: Inventory = null
@onready var inventory_ui: InventoryUI = get_node_or_null("UI/InventoryUI")
@onready var journal_ui: JournalUI = get_node_or_null("UI/JournalUI")
@onready var shop_ui: ShopUI = get_node_or_null("UI/ShopUI")
@onready var map_ui: Node = get_node_or_null("UI/MapUI")

var nearby_interactables: Array[Node2D] = []
var active_target: Node2D = null

func open_shop_for(merchant_id: String) -> void:
	if shop_ui:
		shop_ui.open_shop(merchant_id, get_inventory())
		current_state = State.INVENTORY
		velocity = Vector2.ZERO

func get_inventory() -> Inventory:
	if not inventory:
		inventory = get_node_or_null("Inventory") as Inventory
	return inventory

func _ready() -> void:
	if not inventory:
		inventory = get_node_or_null("Inventory") as Inventory
	add_to_group("player")
	if sword_hitbox:
		sword_hitbox.monitoring = false

	# Envanter UI bağlantısı
	if inventory and inventory_ui:
		inventory_ui.set_inventory(inventory)
		if not inventory_ui.visibility_toggled.is_connected(_on_inventory_visibility_toggled):
			inventory_ui.visibility_toggled.connect(_on_inventory_visibility_toggled)
		if not inventory_ui.item_drop_requested.is_connected(_on_item_drop_requested):
			inventory_ui.item_drop_requested.connect(_on_item_drop_requested)

	# Günlük UI bağlantısı
	if journal_ui:
		if not journal_ui.visibility_toggled.is_connected(_on_journal_visibility_toggled):
			journal_ui.visibility_toggled.connect(_on_journal_visibility_toggled)

	# Dükkân UI bağlantısı
	if shop_ui:
		if not shop_ui.shop_closed.is_connected(_on_shop_closed):
			shop_ui.shop_closed.connect(_on_shop_closed)

	# Harita UI bağlantısı
	if map_ui:
		if not map_ui.visibility_toggled.is_connected(_on_map_visibility_toggled):
			map_ui.visibility_toggled.connect(_on_map_visibility_toggled)

	# Diyalog sistemi sinyallerini dinle
	if is_inside_tree():
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			if not dm.dialogue_started.is_connected(_on_dialogue_started):
				dm.dialogue_started.connect(_on_dialogue_started)
			if not dm.dialogue_ended.is_connected(_on_dialogue_ended):
				dm.dialogue_ended.connect(_on_dialogue_ended)

	if interaction_detector:
		if not interaction_detector.area_entered.is_connected(_on_interaction_area_entered):
			interaction_detector.area_entered.connect(_on_interaction_area_entered)
		if not interaction_detector.area_exited.is_connected(_on_interaction_area_exited):
			interaction_detector.area_exited.connect(_on_interaction_area_exited)

	update_camera_limits()

func update_camera_limits() -> void:
	var cam: Camera2D = get_node_or_null("Camera2D")
	if not cam:
		return

	# 1. İç Mekân kontrolü (InteriorRoom)
	var room = get_tree().get_first_node_in_group("interior_room") if is_inside_tree() else null
	if not room and get_parent() != null:
		room = get_parent().get_node_or_null("RoomVisual")
	if not room and is_inside_tree() and get_tree().current_scene != null:
		room = get_tree().current_scene.get_node_or_null("RoomVisual")

	if room and "room_width" in room and "room_height" in room:
		var w = float(room.room_width)
		var h = float(room.room_height)
		var r_pos = room.global_position
		cam.limit_left = int(r_pos.x - w * 0.5)
		cam.limit_right = int(r_pos.x + w * 0.5)
		cam.limit_top = int(r_pos.y - h * 0.5)
		cam.limit_bottom = int(r_pos.y + h * 0.5)
		cam.reset_smoothing()
		return

	# 2. Açık Dünya / Bölge Kontrolü
	var rm = get_node_or_null("/root/RegionManager")
	if rm and rm.registered_regions.has(rm.active_region_id):
		var reg_info = rm.registered_regions[rm.active_region_id]
		var bounds: Rect2 = reg_info["bounds"]
		cam.limit_left = int(bounds.position.x)
		cam.limit_top = int(bounds.position.y)
		cam.limit_right = int(bounds.end.x)
		cam.limit_bottom = int(bounds.end.y)
		cam.reset_smoothing()
		return

	# 3. Varsayılan Dünya Sınırları (1920x1280)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 1920
	cam.limit_bottom = 1280
	cam.reset_smoothing()

func _unhandled_input(event: InputEvent) -> void:
	# I tuşu ile Envanteri Aç/Kapat
	if event.is_action_pressed("toggle_inventory") and not event.is_echo():
		if current_state != State.TALKING:
			if inventory_ui:
				get_viewport().set_input_as_handled()
				inventory_ui.toggle()
				return

	# J tuşu ile Günlüğü Aç/Kapat
	if event.is_action_pressed("toggle_journal") and not event.is_echo():
		if current_state != State.TALKING:
			if journal_ui:
				get_viewport().set_input_as_handled()
				journal_ui.toggle()
				return

	# M tuşu ile Haritayı Aç/Kapat
	if event.is_action_pressed("toggle_map") and not event.is_echo():
		if current_state != State.TALKING:
			if map_ui:
				get_viewport().set_input_as_handled()
				map_ui.toggle()
				return

	if current_state == State.TALKING or current_state == State.INVENTORY:
		return

	# E tuşu ile en uygun hedefe etkileşim yap
	if event.is_action_pressed("interact") and not event.is_echo():
		var dm = get_node_or_null("/root/DialogueManager")
		if dm and dm.is_dialogue_active:
			return

		_update_active_interaction_target()
		if active_target != null:
			get_viewport().set_input_as_handled()
			if active_target is BaseNPC:
				var npc = active_target as BaseNPC
				if dm:
					dm.start_dialogue(npc.npc_name, npc.get_current_dialogue())
			elif active_target is BaseInteractable:
				var interactable = active_target as BaseInteractable
				interactable.interact_with(self)
			elif active_target.has_method("get_interaction_text"):
				if dm:
					dm.start_dialogue("Keşif Noktası", active_target.get_interaction_text())

func _physics_process(delta: float) -> void:
	# 1. Hit-Stop (Darbe Duraklaması)
	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		return

	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if invincibility_timer > 0.0:
		invincibility_timer -= delta

	# Hasar geri tepmesi (Knockback)
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return

	# Su durumu denetimi
	_update_water_and_climb_environment(delta)

	match current_state:
		State.TALKING, State.INVENTORY, State.DEAD:
			velocity = Vector2.ZERO
		State.HURT:
			hurt_timer -= delta
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if hurt_timer <= 0.0:
				current_state = State.IDLE
		State.GRAPPLE:
			process_grapple_state(delta)
		State.IDLE, State.MOVE:
			process_movement_state(delta)
		State.SWIM:
			process_swim_state(delta)
		State.CLIMB:
			process_climb_state(delta)
		State.ROLL:
			process_roll_state(delta)
		State.ATTACK:
			process_attack_state(delta)

	var prev_pos = global_position
	move_and_slide()

	# Kamera Efektleri: Shake ve Look-ahead
	_update_camera_effects(delta)

	# Hareket ederken en yakın etkileşim hedefini güncelle
	if not nearby_interactables.is_empty():
		_update_active_interaction_target()

	# Adım ve zemin etkileşimi takibi (Sadece kara hareketinde)
	if current_state == State.MOVE or current_state == State.ROLL:
		var moved_dist = global_position.distance_to(prev_pos)
		footstep_distance_accumulator += moved_dist
		if footstep_distance_accumulator >= STEP_DISTANCE:
			footstep_distance_accumulator = 0.0
			_trigger_footstep_effects()

func _update_camera_effects(delta: float) -> void:
	if not camera:
		return

	# Smoothing hızını duruma göre uyarla
	match current_state:
		State.ROLL:
			camera.position_smoothing_speed = 10.0 # Hızlı takip
		State.ATTACK:
			camera.position_smoothing_speed = 7.5
		State.SWIM, State.CLIMB:
			camera.position_smoothing_speed = 5.0 # Daha sakin ve ağır akış
		_:
			camera.position_smoothing_speed = 6.5 # Standart

	# Roll sırasında hafif look-ahead
	var target_offset = Vector2.ZERO
	if current_state == State.ROLL:
		target_offset = roll_direction * 22.0
	elif current_state == State.MOVE:
		target_offset = facing_direction * 8.0

	# Shake efekti
	var shake_offset = Vector2.ZERO
	if shake_timer > 0.0:
		shake_timer -= delta
		var cur_intensity = shake_intensity * (shake_timer / 0.18)
		shake_offset = Vector2(randf_range(-cur_intensity, cur_intensity), randf_range(-cur_intensity, cur_intensity))

	camera.offset = camera.offset.move_toward(target_offset + shake_offset, 140.0 * delta)

func apply_camera_shake(intensity: float = 3.5, duration: float = 0.18) -> void:
	shake_intensity = intensity
	shake_timer = duration

func trigger_hitstop(duration: float = 0.07) -> void:
	hitstop_timer = duration

func process_movement_state(delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Derin suya girdiyse doğrudan yüzme durumuna geç
	if is_in_deep_water:
		current_state = State.SWIM
		_trigger_water_splash(true)
		return

	# Tırmanılabilir bir uçurum önündeyse ve yukarı hareket ediyorsa tırman
	if current_cliff != null and input_vector.y < -0.2:
		current_state = State.CLIMB
		return

	# Sığ suda güçlü direnç hissi (shallow_water_speed: 85.0)
	var target_speed = shallow_water_speed if is_in_water else max_speed

	# Biyom ve Hava Durumu Hız Çarpanları
	var location = get_tree().get_first_node_in_group("location")
	if location and location.has_method("get_biome_at_world_pos"):
		var biome: BiomeData = location.get_biome_at_world_pos(global_position)
		if biome:
			target_speed *= biome.movement_speed_multiplier

	var wm = get_tree().get_first_node_in_group("weather_manager")
	if wm and "speed_multiplier" in wm:
		target_speed *= wm.speed_multiplier

	if input_vector != Vector2.ZERO:
		# Ters yöne dönmede anlık frenleme (snappy turn-around / gereksiz kaymayı önler)
		var dot = velocity.normalized().dot(input_vector.normalized())
		var cur_accel = acceleration
		if dot < -0.2 and velocity.length() > 20.0:
			cur_accel = acceleration * 2.2 # Hızlı dönüş freni

		facing_direction = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * target_speed, cur_accel * delta)
		current_state = State.MOVE
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		current_state = State.IDLE

	# Yuvarlanma (Suda ve tırmanmada engellenir)
	if Input.is_action_just_pressed("roll"):
		if not is_in_water:
			start_roll(facing_direction if input_vector == Vector2.ZERO else input_vector)
		return

	# Saldırı (Suda ve tırmanmada engellenir)
	if Input.is_action_just_pressed("attack"):
		if not is_in_water:
			start_attack()
		return

func process_swim_state(delta: float) -> void:
	# Derin sudan sığ suya veya karaya çıktı mı?
	if not is_in_deep_water:
		current_state = State.MOVE if velocity.length() > 5.0 else State.IDLE
		_trigger_water_splash(false)
		return

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * swim_speed, (acceleration * 0.7) * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, (friction * 0.8) * delta)

	# Yüzme sırasında köpük/dalga parçacıkları
	water_splash_timer += delta
	if velocity.length() > 10.0 and water_splash_timer >= 0.35:
		water_splash_timer = 0.0
		if step_particles and step_particles.has_method("spawn_particles"):
			step_particles.spawn_particles(global_position + Vector2(0, 4), Color("4ca1a3"), 3)

func process_climb_state(delta: float) -> void:
	# Tırmanma sırasında saldırı ve yuvarlanma YASAK
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		# Tırmanırken dikey hareket ağırlıklı, yatay hareket kısıtlı (duvara tutunma hissi)
		velocity = Vector2(input_vector.x * climb_speed * 0.45, input_vector.y * climb_speed)
		# Tırmanma sırasında küçük kaya tozu döküntüsü
		if randf() < 0.12 and step_particles and step_particles.has_method("spawn_particles"):
			step_particles.spawn_particles(global_position + Vector2(0, -6), Color("8c857b"), 1)
	else:
		velocity = Vector2.ZERO

	# Uçurum alanından çıktı mı veya tepeye ulaştı mı?
	if current_cliff != null:
		# Tepeye tırmanıp bittiğinde
		if global_position.y <= current_cliff.global_position.y - current_cliff.cliff_height:
			elevation_level = current_cliff.top_elevation
			current_state = State.IDLE
			global_position.y -= 4.0 # Tepe düzlüğüne adım at
			return
		# Aşağı inip tabana vardığında
		elif global_position.y >= current_cliff.global_position.y + 8.0:
			elevation_level = current_cliff.base_elevation
			current_state = State.IDLE
			return
	else:
		current_state = State.IDLE

func grapple_to_point(target_pos: Vector2) -> void:
	current_state = State.GRAPPLE
	grapple_target_pos = target_pos
	# İleriye doğru çekilme
	velocity = (grapple_target_pos - global_position).normalized() * grapple_speed
	# Kanca atıldığında hafif kamera sarsıntısı ve parçacık
	apply_camera_shake(2.0, 0.15)
	if step_particles and step_particles.has_method("spawn_particles"):
		step_particles.spawn_particles(global_position + Vector2(0, 8), Color("38bdf8"), 4)

func process_grapple_state(delta: float) -> void:
	var dist = global_position.distance_to(grapple_target_pos)
	if dist <= 12.0:
		global_position = grapple_target_pos
		velocity = Vector2.ZERO
		current_state = State.IDLE
		# Varış toparlanma efekti
		if step_particles and step_particles.has_method("spawn_particles"):
			step_particles.spawn_particles(global_position + Vector2(0, 10), Color("64748b"), 3)
		return
	
	global_position = global_position.move_toward(grapple_target_pos, grapple_speed * delta)
	velocity = (grapple_target_pos - global_position).normalized() * grapple_speed

func _trigger_footstep_effects() -> void:
	var surface_type = _detect_current_surface()

	# 1. Ses efekti (AudioManager)
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_footstep(surface_type)

	# 2. Hıza göre ölçeklenen parçacık efekti (Hızlı koşarken/yuvarlanırken daha fazla toz)
	if step_particles and step_particles.has_method("spawn_particles"):
		var p_col = Color("5c442c") # Toprak tozu
		if surface_type == 0: # GRASS
			p_col = Color("3e7b35") # Yeşil çimen kırıntısı
		elif surface_type == 2: # STONE
			p_col = Color("78828f") # Taş tozu
		elif surface_type == 3: # WOOD
			p_col = Color("6d4c2b") # Ahşap tozu

		var p_count = 2
		if current_state == State.ROLL:
			p_count = 5
		elif velocity.length() > 100.0:
			p_count = 3
		step_particles.spawn_particles(global_position + Vector2(0, 10), p_col, p_count)

		# 3. Yere ayak izi bırakma (Toprak, kum ve bataklık çamurunda)
		if step_particles.has_method("spawn_footprint"):
			var fp_col = Color("3d2c1d", 0.55) # Toprak izi
			if surface_type == 1: # DIRT / SAND / MUD
				fp_col = Color("2e1f14", 0.7)
			elif surface_type == 0: # GRASS
				fp_col = Color("23401d", 0.45)
			var angle = facing_direction.angle()
			step_particles.spawn_footprint(global_position + Vector2(0, 8), fp_col, angle)
func _update_water_and_climb_environment(_delta: float) -> void:
	var location = get_node_or_null("../..")
	if not location:
		location = get_tree().get_first_node_in_group("location")
	if not location:
		return

	var tile_pos = Vector2i(int(global_position.x / 16.0), int(global_position.y / 16.0))

	# Paths katmanında köprü var mı? (Köprüdeyse suya girmiş sayılmaz!)
	var paths_layer = location.get_node_or_null("Paths") as TileMapLayer
	var on_bridge = false
	if paths_layer:
		var path_atlas = paths_layer.get_cell_atlas_coords(tile_pos)
		if path_atlas == Vector2i(4, 0): # Ahşap Köprü Kalasları
			on_bridge = true

	# Water katmanı kontrolü
	var water_layer = location.get_node_or_null("Water") as TileMapLayer
	if water_layer and not on_bridge:
		var water_atlas = water_layer.get_cell_atlas_coords(tile_pos)
		if water_atlas == Vector2i(3, 1):
			# Derin su
			is_in_deep_water = true
			is_in_water = true
		elif water_atlas == Vector2i(2, 0) or water_atlas == Vector2i(7, 0):
			# Sığ su / köpüklü akıntı
			is_in_deep_water = false
			is_in_water = true
		else:
			is_in_deep_water = false
			is_in_water = false
	else:
		is_in_deep_water = false
		is_in_water = false

func _trigger_water_splash(is_entering: bool) -> void:
	if step_particles and step_particles.has_method("spawn_particles"):
		var col = Color("ffffff") if is_entering else Color("4ca1a3")
		step_particles.spawn_particles(global_position + Vector2(0, 8), col, 6)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_interact_sound"):
		am.play_interact_sound("plant") # Su hışırtısı hissi veren tını

func _detect_current_surface() -> int:
	# 0: GRASS, 1: DIRT, 2: STONE, 3: WOOD
	if is_in_water:
		return 1 # Su sıçraması / kum zemin tınısı
	# TestLocation altındaki katmanları kontrol et
	var location = get_node_or_null("../..")
	if not location:
		location = get_tree().get_first_node_in_group("location")
	if not location:
		return 0 # Varsayılan çimen

	var tile_pos = Vector2i(int(global_position.x / 16.0), int(global_position.y / 16.0))

	# Paths katmanı kontrolü (Köprü, taş meydan veya toprak yol)
	var paths_layer = location.get_node_or_null("Paths") as TileMapLayer
	if paths_layer:
		var path_atlas = paths_layer.get_cell_atlas_coords(tile_pos)
		if path_atlas == Vector2i(4, 0):
			return 3 # WOOD (Ahşap Köprü)
		elif path_atlas == Vector2i(0, 1) or path_atlas == Vector2i(5, 1) or path_atlas == Vector2i(4, 1):
			return 2 # STONE (Taş Meydan / Kule / Mağara)
		elif path_atlas == Vector2i(1, 0):
			return 1 # DIRT (Toprak Yol)

	# Ground katmanı kontrolü
	var ground_layer = location.get_node_or_null("Ground") as TileMapLayer
	if ground_layer:
		var ground_atlas = ground_layer.get_cell_atlas_coords(tile_pos)
		if ground_atlas == Vector2i(5, 0):
			return 2 # STONE (Kayalık Tepe)
		elif ground_atlas == Vector2i(1, 1) or ground_atlas == Vector2i(7, 1):
			return 1 # DIRT (Kum / Kıyı)

	return 0 # GRASS (Çimen)

func start_roll(direction: Vector2) -> void:
	current_state = State.ROLL
	roll_timer = roll_duration
	roll_direction = direction.normalized()
	velocity = roll_direction * roll_speed

	# Roll başlangıç squash & stretch (İleriye doğru uzama)
	var vis = get_node_or_null("Visual")
	if vis:
		var tween = create_tween()
		if tween:
			tween.tween_property(vis, "scale", Vector2(1.25, 0.75), 0.08)
			tween.tween_property(vis, "scale", Vector2(1.0, 1.0), 0.12)

	# Roll başlangıç toz parçacığı
	if step_particles and step_particles.has_method("spawn_particles"):
		step_particles.spawn_particles(global_position + Vector2(0, 10), Color("6b543e"), 5)

func process_roll_state(delta: float) -> void:
	roll_timer -= delta
	velocity = roll_direction * roll_speed
	if roll_timer <= 0.0:
		current_state = State.IDLE
		# Roll bitiş toparlanma squash
		var vis = get_node_or_null("Visual")
		if vis:
			var tween = create_tween()
			if tween:
				tween.tween_property(vis, "scale", Vector2(0.85, 1.15), 0.08)
				tween.tween_property(vis, "scale", Vector2(1.0, 1.0), 0.1)

func start_attack() -> void:
	current_state = State.ATTACK
	attack_timer = attack_duration
	velocity = facing_direction * 40.0
	if sword_hitbox:
		sword_hitbox.rotation = facing_direction.angle()
		sword_hitbox.monitoring = true

func process_attack_state(delta: float) -> void:
	attack_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if attack_timer <= 0.0:
		if sword_hitbox:
			sword_hitbox.monitoring = false
		current_state = State.IDLE

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD or invincibility_timer > 0.0:
		return

	current_health = max(0, current_health - amount)
	invincibility_timer = 0.5 # Yarım saniye hasar dokunulmazlığı
	knockback_velocity = knockback
	health_changed.emit(current_health, max_health)

	if current_health > 0:
		current_state = State.HURT
		hurt_timer = 0.22

	# Hasar efekti: Kırmızı yanıp sönme
	modulate = Color(1, 0.3, 0.3, 1)
	if is_inside_tree():
		var t = create_tween()
		if t:
			t.tween_property(self, "modulate", Color.WHITE, 0.25)

	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_break_sound"):
			am.play_break_sound()

	if current_health <= 0:
		die()

func die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	player_died.emit()

	if is_inside_tree():
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue("Yenilgi", "Ağır yaralar aldın ve bilincini kaybettin...")

	# Yeniden doğma zamanlayıcısı
	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_interval(1.8)
			tween.tween_callback(respawn)

func respawn() -> void:
	current_health = max_health
	global_position = respawn_point
	current_state = State.IDLE
	knockback_velocity = Vector2.ZERO
	invincibility_timer = 1.0
	health_changed.emit(current_health, max_health)
	player_respawned.emit()

	if is_inside_tree():
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start_dialogue("Köy Meydanı", "Gözlerini köyün güvenli meydanında açtın.")

func _on_dialogue_started(_speaker: String, _text: String) -> void:
	current_state = State.TALKING
	velocity = Vector2.ZERO

func _on_dialogue_ended() -> void:
	current_state = State.IDLE

func _on_inventory_visibility_toggled(is_open: bool) -> void:
	if is_open:
		current_state = State.INVENTORY
		velocity = Vector2.ZERO
	else:
		if current_state == State.INVENTORY:
			current_state = State.IDLE

func _on_journal_visibility_toggled(is_open: bool) -> void:
	if is_open:
		current_state = State.INVENTORY
		velocity = Vector2.ZERO
	else:
		if current_state == State.INVENTORY:
			current_state = State.IDLE

func _on_map_visibility_toggled(is_open: bool) -> void:
	if is_open:
		current_state = State.INVENTORY
		velocity = Vector2.ZERO
	else:
		if current_state == State.INVENTORY:
			current_state = State.IDLE

func _on_shop_closed() -> void:
	if current_state == State.INVENTORY:
		current_state = State.IDLE

func _on_item_drop_requested(slot_index: int, drop_count: int = 1) -> void:
	if not inventory or inventory.is_slot_empty(slot_index):
		return

	var slot_data = inventory.get_slot(slot_index)
	var item_id = slot_data["item_id"]
	var count_to_drop = min(drop_count, slot_data["amount"])

	var safe_pos = _find_safe_drop_position()
	var success = inventory.remove_from_slot(slot_index, count_to_drop)
	if success:
		_spawn_world_item(item_id, count_to_drop, safe_pos)

func _spawn_world_item(item_id: String, amount: int, target_pos: Vector2) -> void:
	var item_scene = preload("res://scenes/props/world_item.tscn")
	var world_item = item_scene.instantiate() as WorldItem
	world_item.setup_item(item_id, amount)

	# Ebeveyn düğüm olarak sahnedeki YSort katmanını veya dünya kökünü seç
	var drop_parent = get_parent()
	if drop_parent != null:
		drop_parent.add_child(world_item)
	else:
		get_tree().root.add_child(world_item)

	world_item.launch_bounce(global_position, target_pos, 16.0, 0.42)

func _find_safe_drop_position() -> Vector2:
	# Karakterin baktığı yönden başlayarak 8 radyal açıyı test et
	var base_angle = facing_direction.angle()
	var drop_dist = 22.0

	if not is_inside_tree() or get_world_2d() == null:
		return global_position + facing_direction * drop_dist

	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return global_position + facing_direction * drop_dist

	var angles_to_try = [
		0.0,
		PI * 0.25, -PI * 0.25,
		PI * 0.5, -PI * 0.5,
		PI * 0.75, -PI * 0.75,
		PI
	]

	for offset in angles_to_try:
		var test_angle = base_angle + offset
		var dir = Vector2(cos(test_angle), sin(test_angle))
		var test_target = global_position + dir * drop_dist

		# 1. Işın testi (Raycast): Duvar veya katı engel (Layer 1: World_Solid) var mı?
		var query = PhysicsRayQueryParameters2D.create(global_position, test_target)
		query.collision_mask = 1 # Solid world obstacles / water
		query.exclude = [self]
		var result = space_state.intersect_ray(query)

		if result.is_empty():
			# Engel yok, bu koordinat güvenli
			return test_target

	# Hiçbir yön boş değilse oyuncunun hemen ayak ucuna bırak
	return global_position + facing_direction * 8.0

func _on_interaction_area_entered(area: Area2D) -> void:
	var parent_node = area.get_parent()
	if parent_node == null:
		return

	if parent_node is ClimbableCliff:
		current_cliff = parent_node as ClimbableCliff

	if parent_node is BaseNPC or parent_node is BaseInteractable or parent_node.has_method("get_interaction_text"):
		if not nearby_interactables.has(parent_node):
			nearby_interactables.append(parent_node)
			_update_active_interaction_target()

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent_node = area.get_parent()
	if parent_node != null and parent_node is ClimbableCliff and current_cliff == parent_node:
		current_cliff = null
		if current_state == State.CLIMB:
			current_state = State.IDLE

	if parent_node != null and nearby_interactables.has(parent_node):
		nearby_interactables.erase(parent_node)
		if parent_node is BaseInteractable:
			(parent_node as BaseInteractable).set_prompt_highlight(false)
		_update_active_interaction_target()

# Birden fazla aday varsa oyuncuya en yakın ve geçerli olanı seçer
func _update_active_interaction_target() -> void:
	# Listeyi temizle (geçersiz veya freed olmuş nesneler varsa)
	nearby_interactables = nearby_interactables.filter(func(node): return is_instance_valid(node))

	if nearby_interactables.is_empty():
		if active_target != null and active_target is BaseInteractable and is_instance_valid(active_target):
			(active_target as BaseInteractable).set_prompt_highlight(false)
		active_target = null
		return

	# En yakın adayı bul
	var closest_node: Node2D = null
	var min_dist: float = 999999.0

	for candidate in nearby_interactables:
		if candidate is BaseInteractable and not (candidate as BaseInteractable).is_interactable:
			continue
		var d = global_position.distance_to(candidate.global_position)
		if d < min_dist:
			min_dist = d
			closest_node = candidate

	active_target = closest_node

	# Tüm adayların prompt görünürlüğünü güncelle: Sadece seçilen aktif olsun
	for candidate in nearby_interactables:
		if candidate is BaseInteractable and is_instance_valid(candidate):
			(candidate as BaseInteractable).set_prompt_highlight(candidate == active_target)

