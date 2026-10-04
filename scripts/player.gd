extends CharacterBody2D

# Project T - Gelişmiş Karakter Durum Makinesi (State Machine)

enum State { IDLE, MOVE, ROLL, ATTACK, TALKING }
var current_state: State = State.IDLE

@export var max_speed: float = 120.0
@export var acceleration: float = 850.0
@export var friction: float = 950.0

# Yuvarlanma / Kaçınma (Roll)
@export var roll_speed: float = 230.0
@export var roll_duration: float = 0.28
var roll_timer: float = 0.0
var roll_direction: Vector2 = Vector2.DOWN

# Saldırı (Attack)
@export var attack_duration: float = 0.32
var attack_timer: float = 0.0

var facing_direction: Vector2 = Vector2.DOWN

@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_detector: Area2D = $InteractionDetector

var nearby_npc: BaseNPC = null

func _ready() -> void:
	if sword_hitbox:
		sword_hitbox.monitoring = false

	# Diyalog sistemi sinyallerini dinle
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.dialogue_started.connect(_on_dialogue_started)
		dm.dialogue_ended.connect(_on_dialogue_ended)

	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)

func _unhandled_input(event: InputEvent) -> void:
	# Eğer diyalogdaysak oyuncu girdilerini alma
	if current_state == State.TALKING:
		return

	# E tuşu ile yakındaki NPC ile konuşma başlat
	if event.is_action_pressed("interact") and not event.is_echo():
		if nearby_npc != null:
			var dm = get_node_or_null("/root/DialogueManager")
			if dm and not dm.is_dialogue_active:
				get_viewport().set_input_as_handled()
				dm.start_dialogue(nearby_npc.npc_name, nearby_npc.get_current_dialogue())

func _physics_process(delta: float) -> void:
	match current_state:
		State.TALKING:
			velocity = Vector2.ZERO
		State.IDLE, State.MOVE:
			process_movement_state(delta)
		State.ROLL:
			process_roll_state(delta)
		State.ATTACK:
			process_attack_state(delta)

	move_and_slide()

func process_movement_state(delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
		current_state = State.MOVE
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		current_state = State.IDLE

	# Yuvarlanma
	if Input.is_action_just_pressed("roll"):
		start_roll(facing_direction if input_vector == Vector2.ZERO else input_vector)
		return

	# Saldırı
	if Input.is_action_just_pressed("attack"):
		start_attack()
		return

func start_roll(direction: Vector2) -> void:
	current_state = State.ROLL
	roll_timer = roll_duration
	roll_direction = direction.normalized()
	velocity = roll_direction * roll_speed

func process_roll_state(delta: float) -> void:
	roll_timer -= delta
	velocity = roll_direction * roll_speed
	if roll_timer <= 0.0:
		current_state = State.IDLE

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

func _on_dialogue_started(_speaker: String, _text: String) -> void:
	current_state = State.TALKING
	velocity = Vector2.ZERO

func _on_dialogue_ended() -> void:
	current_state = State.IDLE

func _on_interaction_area_entered(area: Area2D) -> void:
	var parent_node = area.get_parent()
	if parent_node is BaseNPC:
		nearby_npc = parent_node

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent_node = area.get_parent()
	if parent_node == nearby_npc:
		nearby_npc = null
