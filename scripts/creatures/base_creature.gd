@tool
extends CharacterBody2D
class_name BaseCreature

# Project T - Temel Canlı ve Yapay Zekâ Varlığı (BaseCreature)
# Pasif Canlılar: Tavşan, Geyik, Kuş
# Tehlikeli Canlılar: Kurt, Yaban Domuzu
# İnsan Düşman: Haydut
# Davranış Durumları: IDLE (Dolaşma/Bekleme), WANDER (Dolaşma), FLEE (Kaçma), CHASE (Takip), ATTACK (Saldırı), RETREAT (Geri Çekilme), DEAD (Ölü)

signal health_changed(current_hp: int, max_hp: int)
signal died(killer: Node)

enum CreatureCategory { PASSIVE, HOSTILE }
enum CreatureState { IDLE, WANDER, FLEE, CHASE, ATTACK, RETREAT, DEAD }

@export var creature_name: String = "Canlı"
@export var category: CreatureCategory = CreatureCategory.PASSIVE
@export var max_health: int = 30
@export var current_health: int = 30
@export var attack_damage: int = 10
@export var base_speed: float = 65.0
@export var flee_or_chase_speed: float = 110.0
@export var detection_range: float = 140.0
@export var attack_range: float = 24.0
@export var max_chase_distance_from_origin: float = 260.0 # Sınırlı takip mesafesi

# Ganimet listesi (WorldItem sistemine bağlı)
@export var loot_table: Array[Dictionary] = [
	{"item_id": "wood", "amount": 1, "chance": 0.5}
]

var current_state: CreatureState = CreatureState.IDLE
var origin_position: Vector2 = Vector2.ZERO
var target_player: CharacterBody2D = null

# Zamanlayıcılar ve yönler
var state_timer: float = 0.0
var move_direction: Vector2 = Vector2.ZERO
var attack_cooldown_timer: float = 0.0
var hit_flash_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

var hurtbox: Area2D = null
var hit_col: CollisionShape2D = null

func _ready() -> void:
	add_to_group("creature")
	if category == CreatureCategory.HOSTILE:
		add_to_group("enemy")
	collision_layer = 4 # Layer 3: NPC/Creature
	collision_mask = 1 # World_Solid

	origin_position = global_position
	current_health = max_health
	state_timer = randf_range(1.5, 3.5)

	_setup_combat_components()
	queue_redraw()

func _setup_combat_components() -> void:
	# Hurtbox (Kılıç saldırılarını algılamak için: Layer 5, Mask 4)
	hurtbox = get_node_or_null("CreatureHurtbox")
	if not hurtbox:
		hurtbox = Area2D.new()
		hurtbox.name = "CreatureHurtbox"
		hurtbox.collision_layer = 16 # Layer 5: Hurtboxes
		hurtbox.collision_mask = 8   # Layer 4: Hitboxes
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		hurtbox.add_child(col)
		add_child(hurtbox)

	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	if current_state == CreatureState.DEAD:
		return

	# Hasar geri tepmesi (Knockback)
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return

	# Görsel flaş efekti
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			queue_redraw()

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	_update_ai_state(delta)
	move_and_slide()

func _update_ai_state(delta: float) -> void:
	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	var dist_to_player = 9999.0
	if target_player != null and is_instance_valid(target_player):
		dist_to_player = global_position.distance_to(target_player.global_position)

	var dist_from_origin = global_position.distance_to(origin_position)

	match current_state:
		CreatureState.IDLE:
			velocity = Vector2.ZERO
			state_timer -= delta
			if category == CreatureCategory.PASSIVE and dist_to_player < detection_range * 0.7:
				current_state = CreatureState.FLEE
			elif category == CreatureCategory.HOSTILE and dist_to_player < detection_range and dist_from_origin < max_chase_distance_from_origin:
				current_state = CreatureState.CHASE
			elif state_timer <= 0.0:
				current_state = CreatureState.WANDER
				move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				state_timer = randf_range(1.5, 3.0)

		CreatureState.WANDER:
			velocity = move_direction * base_speed
			state_timer -= delta
			if category == CreatureCategory.PASSIVE and dist_to_player < detection_range * 0.7:
				current_state = CreatureState.FLEE
			elif category == CreatureCategory.HOSTILE and dist_to_player < detection_range and dist_from_origin < max_chase_distance_from_origin:
				current_state = CreatureState.CHASE
			elif state_timer <= 0.0:
				current_state = CreatureState.IDLE
				state_timer = randf_range(1.0, 2.5)

		CreatureState.FLEE:
			# Pasif canlılar oyuncunun ters yönüne kaçar
			if target_player != null:
				var flee_dir = (global_position - target_player.global_position).normalized()
				velocity = flee_dir * flee_or_chase_speed
			if dist_to_player > detection_range * 1.5:
				current_state = CreatureState.IDLE
				state_timer = randf_range(1.5, 3.0)

		CreatureState.CHASE:
			# Takip mesafesini aştıysa veya oyuncu uzaklaştıysa geri çekil
			if dist_from_origin > max_chase_distance_from_origin or dist_to_player > detection_range * 1.6:
				current_state = CreatureState.RETREAT
				return

			if target_player != null:
				var chase_dir = (target_player.global_position - global_position).normalized()
				velocity = chase_dir * flee_or_chase_speed

				if dist_to_player <= attack_range and attack_cooldown_timer <= 0.0:
					current_state = CreatureState.ATTACK
					state_timer = 0.35

		CreatureState.ATTACK:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0:
				# Oyuncuya hasar ver
				if target_player != null and global_position.distance_to(target_player.global_position) <= attack_range + 6.0:
					if target_player.has_method("take_damage"):
						var knock_dir = (target_player.global_position - global_position).normalized()
						target_player.take_damage(attack_damage, knock_dir * 180.0)
				attack_cooldown_timer = 1.2
				current_state = CreatureState.CHASE

		CreatureState.RETREAT:
			# Doğduğu başlangıç alanına geri çekil
			var home_dir = (origin_position - global_position).normalized()
			velocity = home_dir * base_speed
			if global_position.distance_to(origin_position) <= 16.0:
				current_state = CreatureState.IDLE
				state_timer = randf_range(1.5, 3.0)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if current_state == CreatureState.DEAD:
		return
	# Oyuncunun kılıç hitbox'ı çarptığında (Layer 4)
	if area.name == "SwordHitbox" or area.collision_layer == 8:
		var player = area.get_parent() as CharacterBody2D
		var sword_dmg = 15
		var knock_dir = Vector2.DOWN
		if player != null:
			knock_dir = (global_position - player.global_position).normalized()
			if player.has_method("trigger_hitstop"):
				player.trigger_hitstop(0.06) # 60ms hitstop
			if player.has_method("apply_camera_shake"):
				player.apply_camera_shake(2.8, 0.16) # Hafif kamera sarsıntısı
		take_damage(sword_dmg, knock_dir * 140.0, player)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, attacker: Node = null) -> void:
	if current_state == CreatureState.DEAD:
		return

	current_health -= amount
	knockback_velocity = knockback
	hit_flash_timer = 0.15
	health_changed.emit(current_health, max_health)

	# Görsel Beyaz/Kırmızı darbe flaşı (Flicker)
	modulate = Color(2.0, 1.2, 1.2, 1.0) # Parlak darbe flaşı
	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	# Ses
	if is_inside_tree():
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_break_sound"):
			am.play_break_sound()

	queue_redraw()

	if current_health <= 0:
		die(attacker)
	else:
		# Hasar alınca pasifse kaç, düşmansa hedefe odaklan
		if category == CreatureCategory.PASSIVE:
			current_state = CreatureState.FLEE
		elif category == CreatureCategory.HOSTILE and current_state != CreatureState.CHASE:
			current_state = CreatureState.CHASE

func die(killer: Node = null) -> void:
	current_state = CreatureState.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		hurtbox.queue_free()

	died.emit(killer)
	if is_inside_tree():
		var qm = get_node_or_null("/root/QuestManager")
		if qm:
			qm.advance_quest_condition(QuestData.ConditionType.ENEMY_KILL, creature_name)
		var fm = get_node_or_null("/root/FactionManager")
		if fm and "enemy_type" in self:
			fm.on_enemy_defeated(self.enemy_type)
	
	_drop_loot.call_deferred()

	# Kısa ölüm kararması / silinme
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _drop_loot() -> void:
	if loot_table.is_empty():
		return

	for entry in loot_table:
		var chance = entry.get("chance", 1.0)
		if randf() <= chance:
			var item_id = entry.get("item_id", "")
			var amount = entry.get("amount", 1)
			if item_id != "":
				_spawn_world_item(item_id, amount)

func _spawn_world_item(item_id: String, amount: int) -> void:
	_deferred_spawn_item.call_deferred(item_id, amount, global_position)

func _deferred_spawn_item(item_id: String, amount: int, spawn_pos: Vector2) -> void:
	var item_scene = preload("res://scenes/props/world_item.tscn")
	var world_item = item_scene.instantiate() as WorldItem
	world_item.setup_item(item_id, amount)

	var p_parent = get_parent()
	if p_parent != null:
		p_parent.add_child(world_item)
	elif is_inside_tree():
		get_tree().root.add_child(world_item)
	else:
		return

	var offset_dir = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.8)).normalized()
	var dest = spawn_pos + offset_dir * randf_range(14.0, 24.0)
	world_item.launch_bounce(spawn_pos, dest, 14.0, 0.4)
