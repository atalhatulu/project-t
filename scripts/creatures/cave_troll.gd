@tool
extends BaseCreature
class_name CaveTroll

# Project T - Yankılı Mağara Mini-Boss'u: Mağara Trolü (CaveTroll)
# Davranışlar:
# 1. Faz 1 (%100 - %50 Can): Ağır takip, yakın yumruk vuruşu, yere vurma alan saldırısı (slam telegraph)
# 2. Faz 2 (%50 - %0 Can): Öfkeli kükreme, hız artışı, kısa hücum (charge) ve daha sık slam
# 3. Ölüm: Boss kapısını açar ve ganimet sandığını serbest bırakır.

signal boss_phase_changed(new_phase: int)
signal boss_defeated

enum BossPhase { PHASE_1, ENRAGED }
enum AttackPattern { IDLE_FOLLOW, SLAM_PREPARE, SLAM_IMPACT, CHARGE_PREPARE, CHARGING }

var current_phase: BossPhase = BossPhase.PHASE_1
var current_pattern: AttackPattern = AttackPattern.IDLE_FOLLOW

var pattern_timer: float = 0.0
var slam_radius: float = 64.0
var charge_direction: Vector2 = Vector2.ZERO

@export var boss_door_path: NodePath
@export var reward_chest_path: NodePath

func _ready() -> void:
	category = CreatureCategory.HOSTILE
	creature_name = "Kadim Mağara Trolü"
	max_health = 180
	current_health = 180
	attack_damage = 22
	base_speed = 38.0
	flee_or_chase_speed = 65.0
	detection_range = 280.0
	attack_range = 36.0
	max_chase_distance_from_origin = 450.0
	
	loot_table = [
		{"item_id": "iron_ore", "amount": 4, "chance": 1.0},
		{"item_id": "ancient_medallion", "amount": 1, "chance": 1.0}
	]
	
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == CreatureState.DEAD:
		return
	
	# Faz 2 Kontrolü
	if current_phase == BossPhase.PHASE_1 and current_health <= max_health * 0.5:
		_enter_enraged_phase()

	# Pattern Mantığı
	match current_pattern:
		AttackPattern.IDLE_FOLLOW:
			pattern_timer += delta
			var slam_cooldown = 3.5 if current_phase == BossPhase.PHASE_1 else 2.2
			if pattern_timer >= slam_cooldown:
				pattern_timer = 0.0
				if current_phase == BossPhase.ENRAGED and randf() < 0.45:
					_start_charge()
				else:
					_start_slam()
		
		AttackPattern.SLAM_PREPARE:
			velocity = Vector2.ZERO
			pattern_timer -= delta
			queue_redraw()
			if pattern_timer <= 0.0:
				_execute_slam_impact()
		
		AttackPattern.SLAM_IMPACT:
			velocity = Vector2.ZERO
			pattern_timer -= delta
			if pattern_timer <= 0.0:
				current_pattern = AttackPattern.IDLE_FOLLOW
				queue_redraw()
		
		AttackPattern.CHARGE_PREPARE:
			velocity = Vector2.ZERO
			pattern_timer -= delta
			queue_redraw()
			if pattern_timer <= 0.0:
				_execute_charge()
		
		AttackPattern.CHARGING:
			velocity = charge_direction * (flee_or_chase_speed * 2.2)
			pattern_timer -= delta
			_check_charge_collision()
			if pattern_timer <= 0.0:
				current_pattern = AttackPattern.IDLE_FOLLOW
				queue_redraw()

	if current_pattern == AttackPattern.IDLE_FOLLOW:
		super._physics_process(delta)
	else:
		move_and_slide()

func _enter_enraged_phase() -> void:
	current_phase = BossPhase.ENRAGED
	base_speed = 52.0
	flee_or_chase_speed = 88.0
	attack_damage = 28
	boss_phase_changed.emit(2)
	
	# Kükreme efekti ve kamera sarsıntısı
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(5.0, 0.4)
	
	modulate = Color(1.3, 0.8, 0.8, 1.0)

func _start_slam() -> void:
	current_pattern = AttackPattern.SLAM_PREPARE
	pattern_timer = 0.8 # 800ms hazırlık / telegraph süresi

func _execute_slam_impact() -> void:
	current_pattern = AttackPattern.SLAM_IMPACT
	pattern_timer = 0.4
	
	# Alan hasarı ve kamera sarsıntısı
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= slam_radius and player.has_method("take_damage"):
			var knock_dir = (player.global_position - global_position).normalized()
			player.take_damage(attack_damage, knock_dir * 220.0)
		if player.has_method("apply_camera_shake"):
			player.apply_camera_shake(4.5, 0.28)

func _start_charge() -> void:
	current_pattern = AttackPattern.CHARGE_PREPARE
	pattern_timer = 0.6
	var player = get_tree().get_first_node_in_group("player")
	if player:
		charge_direction = (player.global_position - global_position).normalized()
	else:
		charge_direction = Vector2.DOWN

func _execute_charge() -> void:
	current_pattern = AttackPattern.CHARGING
	pattern_timer = 0.7 # 700ms hücum

func _check_charge_collision() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 32.0 and player.has_method("take_damage"):
			player.take_damage(attack_damage + 6, charge_direction * 250.0)
			pattern_timer = 0.0 # Hücumu bitir

func die(killer: Node = null) -> void:
	super.die(killer)
	boss_defeated.emit()
	
	# Kapıyı ve sandığı aç
	if boss_door_path != NodePath(""):
		var door = get_node_or_null(boss_door_path)
		if door and door.has_method("unlock_and_open"):
			door.unlock_and_open()
	
	# Büyük kamera sarsıntısı ve zafer sesi
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_camera_shake"):
		player.apply_camera_shake(6.0, 0.5)

func _draw() -> void:
	# Taban gölgesi (Büyük)
	draw_circle(Vector2(0, 10), 20.0, Color(0, 0, 0, 0.45))
	
	# Slam Telegraph Alanı (Hazırlık aşamasında kırmızı tehlike dairesi)
	if current_pattern == AttackPattern.SLAM_PREPARE:
		var alpha = (0.8 - pattern_timer) / 0.8
		draw_circle(Vector2.ZERO, slam_radius, Color(0.9, 0.2, 0.2, 0.25 * alpha))
		draw_arc(Vector2.ZERO, slam_radius, 0, TAU, 32, Color(0.9, 0.2, 0.2, 0.75), 2.0)
	
	# Hücum Tehlike Oku
	if current_pattern == AttackPattern.CHARGE_PREPARE:
		draw_line(Vector2.ZERO, charge_direction * 48.0, Color("f59e0b", 0.75), 3.0)
	
	# Trol Gövdesi (Heybetli, yosunlu gri dev)
	var col_skin = Color("3f4f44") if current_phase == BossPhase.PHASE_1 else Color("633535")
	var col_belly = Color("566b5c") if current_phase == BossPhase.PHASE_1 else Color("7f4242")
	
	# Kollar
	draw_circle(Vector2(-18, -4), 8.0, col_skin)
	draw_circle(Vector2(18, -4), 8.0, col_skin)
	# Gövde
	draw_circle(Vector2(0, -6), 18.0, col_skin)
	draw_circle(Vector2(0, -2), 12.0, col_belly)
	# Kafa ve Çene
	draw_circle(Vector2(0, -24), 10.0, col_skin)
	draw_rect(Rect2(-6, -20, 12, 6), Color("28332c")) # Alt çene
	# Gözler (Öfkeli kırmızı/sarı parıltı)
	var eye_col = Color("facc15") if current_phase == BossPhase.PHASE_1 else Color("ef4444")
	draw_circle(Vector2(-3.5, -26), 2.0, eye_col)
	draw_circle(Vector2(3.5, -26), 2.0, eye_col)
	# Sivri Taş Dişler
	draw_line(Vector2(-4, -18), Vector2(-4, -22), Color("f8fafc"), 2.0)
	draw_line(Vector2(4, -18), Vector2(4, -22), Color("f8fafc"), 2.0)
