extends CharacterBody2D
class_name BaseNPC

# Project T - Gelişmiş Yaşayan NPC Kontrolcüsü
# Durumlar: IDLE, WALK, WORK, SOCIALIZE, SLEEP, EAT, REST, CHATTING
# TimeManager, NavigationAgent2D, NPCNeeds, NPCMemory, NPCSocial ve Histerezisli Karar Sistemi

enum State { IDLE, WALK, WORK, SOCIALIZE, SLEEP, EAT, REST, CHATTING }

@export_group("NPC Kimlik")
@export var npc_id: String = "boran"
@export var npc_name: String = "Demirci Boran"
@export var npc_occupation: String = "Demirci Ustası"

@export_group("Hareket")
@export var walk_speed: float = 45.0
@export var arrival_tolerance: float = 12.0

var current_state: State = State.IDLE
var target_destination: Vector2 = Vector2.ZERO
var current_schedule_entry: Dictionary = {}

# Sıkışma & Görünürlük Kurtarma
var stuck_timer: float = 0.0
var stuck_wait_timer: float = 0.0
var is_repathing: bool = false
var last_position: Vector2 = Vector2.ZERO

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var visual_node: Node2D = $Visual
@onready var needs: NPCNeeds = $Needs
@onready var memory: NPCMemory = $Memory
@onready var social: NPCSocial = $Social

# Veri Odaklı Günlük Program
var schedule: Array[Dictionary] = []

# Karar Sistemi Zamanlayıcısı (Her karede değil, 1.5 saniyede bir veya saat değişiminde)
var decision_timer: float = 0.0
const DECISION_INTERVAL: float = 1.5

# Sosyal Tarama Zamanlayıcısı (Her kare değil, 2.5 saniyede bir yakın NPC kontrolü)
var social_scan_timer: float = 0.0
const SOCIAL_SCAN_INTERVAL: float = 2.5

# İhtiyaç Lokasyonları (Alt sınıfta doldurulur)
var location_eat: Vector2 = Vector2.ZERO
var location_rest: Vector2 = Vector2.ZERO
var location_social: Vector2 = Vector2.ZERO

# İhtiyaç Geçersiz Kılması (Override)
var is_need_override: bool = false
var override_state: State = State.IDLE

# Sohbet Öncesi Durum Saklama
var pre_chat_state: State = State.IDLE

func _ready() -> void:
	add_to_group("npc")
	collision_layer = 4 # Layer 3: NPC
	collision_mask = 1  # Layer 1: World_Solid

	if nav_agent:
		nav_agent.path_desired_distance = 6.0
		nav_agent.target_desired_distance = arrival_tolerance
		nav_agent.avoidance_enabled = false

	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.hour_changed.connect(_on_hour_changed)
		_evaluate_schedule_for_hour(tm.current_hour, true)

func _physics_process(delta: float) -> void:
	# 1. İhtiyaçları güncelle (Zaman hızına göre)
	var tm = get_node_or_null("/root/TimeManager")
	if tm and needs:
		var game_seconds_per_sec = (86400.0 / tm.real_seconds_per_day) * tm.time_scale
		var game_hours_delta = (delta * game_seconds_per_sec) / 3600.0
		needs.update_needs(game_hours_delta, current_state)

	# 2. Periyodik Karar Değerlendirmesi
	decision_timer += delta
	if decision_timer >= DECISION_INTERVAL:
		decision_timer = 0.0
		evaluate_decisions()

	# 3. Periyodik Sosyal Tarama
	social_scan_timer += delta
	if social_scan_timer >= SOCIAL_SCAN_INTERVAL:
		social_scan_timer = 0.0
		_check_for_nearby_npc_chat()

	# 4. Durum Hareketi
	match current_state:
		State.WALK:
			_process_walk_state(delta)
		State.CHATTING:
			velocity = Vector2.ZERO
			move_and_slide()
			if social and not social.is_chatting:
				_end_npc_chat()
		State.IDLE, State.WORK, State.SOCIALIZE, State.SLEEP, State.EAT, State.REST:
			velocity = Vector2.ZERO
			move_and_slide()

func evaluate_decisions() -> void:
	if not needs or current_state == State.CHATTING:
		return

	# Histerezisli Karar Mekanizması:
	if needs.is_critically_hungry() and not (current_state == State.EAT or (current_state == State.WALK and override_state == State.EAT)):
		is_need_override = true
		override_state = State.EAT
		set_destination(location_eat)
		return
	elif current_state == State.EAT and needs.hunger >= NPCNeeds.SATISFIED_HUNGER_THRESHOLD:
		is_need_override = false
		_return_to_schedule()
		return

	if needs.is_critically_exhausted() and not (current_state == State.REST or current_state == State.SLEEP or (current_state == State.WALK and override_state == State.REST)):
		is_need_override = true
		override_state = State.REST
		set_destination(location_rest)
		return
	elif current_state == State.REST and needs.energy >= NPCNeeds.SATISFIED_ENERGY_THRESHOLD:
		is_need_override = false
		_return_to_schedule()
		return

func _check_for_nearby_npc_chat() -> void:
	# Uyurken veya zaten sohbetteyken başlatma
	if current_state == State.SLEEP or current_state == State.CHATTING:
		return
	if not social or not social.can_initiate_chat():
		return

	# Çevredeki NPC'leri bul
	var all_npcs = get_tree().get_nodes_in_group("npc")
	for other_npc in all_npcs:
		if other_npc == self:
			continue
		var partner = other_npc as BaseNPC
		if not partner or not partner.social:
			continue

		# Mesafe kontrolü (36 pikselden yakınsa)
		if global_position.distance_to(partner.global_position) <= 38.0:
			if partner.current_state != State.SLEEP and partner.current_state != State.CHATTING and partner.social.can_initiate_chat():
				_start_npc_chat_with(partner)
				break

func _start_npc_chat_with(partner: BaseNPC) -> void:
	pre_chat_state = current_state
	current_state = State.CHATTING
	velocity = Vector2.ZERO

	partner.pre_chat_state = partner.current_state
	partner.current_state = State.CHATTING
	partner.velocity = Vector2.ZERO

	# Birbirlerine dönme
	_face_target(partner.global_position)
	partner._face_target(global_position)

	# Sosyal etkileşim başlat
	social.start_chat_with(partner, 4.0)
	partner.social.start_chat_with(self, 4.0)

	# Sosyal ihtiyacı biraz artır
	if needs: needs.social = clamp(needs.social + 15.0, 0.0, 100.0)
	if partner.needs: partner.needs.social = clamp(partner.needs.social + 15.0, 0.0, 100.0)

func _face_target(target_pos: Vector2) -> void:
	var dir = (target_pos - global_position).normalized()
	if visual_node:
		# Sağa veya sola dönme (scale.x ile ayna çevirme)
		if dir.x < -0.1:
			visual_node.scale.x = -1.0
		elif dir.x > 0.1:
			visual_node.scale.x = 1.0

func _end_npc_chat() -> void:
	current_state = pre_chat_state
	if current_state == State.WALK:
		set_destination(target_destination)

func _return_to_schedule() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		_evaluate_schedule_for_hour(tm.current_hour, false)

func _process_walk_state(delta: float) -> void:
	if stuck_wait_timer > 0.0:
		stuck_wait_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if stuck_wait_timer <= 0.0:
			nav_agent.target_position = target_destination
		return

	if nav_agent.is_navigation_finished() or global_position.distance_to(target_destination) <= arrival_tolerance:
		_on_reached_destination()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var move_dir = (next_path_pos - global_position).normalized()
	velocity = move_dir * walk_speed
	move_and_slide()

	if move_dir.x != 0.0 and visual_node:
		visual_node.scale.x = -1.0 if move_dir.x < 0.0 else 1.0

	if global_position.distance_to(last_position) < 1.0:
		stuck_timer += delta
		if stuck_timer > 2.5:
			_handle_stuck_situation()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = global_position

func _handle_stuck_situation() -> void:
	if is_player_nearby():
		stuck_wait_timer = 1.5
		nav_agent.target_position = target_destination
	else:
		global_position = target_destination
		_on_reached_destination()

func is_player_nearby() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("../Player")
	if player:
		return global_position.distance_to(player.global_position) < 420.0
	return false

func set_destination(dest: Vector2) -> void:
	target_destination = dest
	if global_position.distance_to(dest) <= arrival_tolerance:
		_on_reached_destination()
		return

	current_state = State.WALK
	if nav_agent:
		nav_agent.target_position = dest

func _on_reached_destination() -> void:
	velocity = Vector2.ZERO
	if is_need_override:
		current_state = override_state
	elif current_schedule_entry.has("target_state"):
		current_state = current_schedule_entry["target_state"]
	else:
		current_state = State.IDLE

func _on_hour_changed(new_hour: int) -> void:
	if not is_need_override and current_state != State.CHATTING:
		_evaluate_schedule_for_hour(new_hour, false)

func _evaluate_schedule_for_hour(hour: int, immediate: bool) -> void:
	if schedule.is_empty():
		return

	var active_entry: Dictionary = schedule[0]
	for entry in schedule:
		if hour >= entry["hour"]:
			active_entry = entry

	current_schedule_entry = active_entry
	var dest = active_entry["target"]

	if immediate:
		global_position = dest
		current_state = active_entry["target_state"]
	else:
		set_destination(dest)

func get_current_dialogue() -> String:
	if memory:
		memory.on_talked_with_player()

	if current_schedule_entry.has("dialogue"):
		return current_schedule_entry["dialogue"]
	return "Selam sana yolcu."
