@tool
extends Node2D
class_name FloorSpikes

# Project T - Zamanlamalı Yer Dikeni Tuzağı (FloorSpikes)
# Durumlar: RETRACTED (İçeride/Güvenli) -> WARNING (Sallantı/Uyarı) -> EXTENDED (Dışarıda/Hasar Verici)

enum SpikeState { RETRACTED, WARNING, EXTENDED }

@export var trap_id: String = "spikes_01"
@export var damage_amount: int = 20
@export var cycle_interval: float = 2.4 # Tam döngü süresi
@export var warning_duration: float = 0.6
@export var extended_duration: float = 0.9

var current_state: SpikeState = SpikeState.RETRACTED
var cycle_timer: float = 0.0
var hitbox: Area2D

func _ready() -> void:
	add_to_group("trap")
	
	hitbox = get_node_or_null("Hitbox")
	if not hitbox:
		hitbox = Area2D.new()
		hitbox.name = "Hitbox"
		hitbox.collision_layer = 8 # Layer 4: Hitbox
		hitbox.collision_mask = 2  # Layer 2: Player
		var shape = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = Vector2(28, 28)
		shape.shape = box
		hitbox.add_child(shape)
		add_child(hitbox)
	
	if not hitbox.body_entered.is_connected(_on_body_entered):
		hitbox.body_entered.connect(_on_body_entered)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	cycle_timer += delta
	var t = fmod(cycle_timer, cycle_interval)
	
	var old_state = current_state
	if t < (cycle_interval - warning_duration - extended_duration):
		current_state = SpikeState.RETRACTED
	elif t < (cycle_interval - extended_duration):
		current_state = SpikeState.WARNING
	else:
		current_state = SpikeState.EXTENDED
	
	if old_state != current_state:
		queue_redraw()
		if current_state == SpikeState.EXTENDED:
			_check_player_damage()
			var am = get_node_or_null("/root/AudioManager")
			if am and is_inside_tree() and am.has_method("play_break_sound"):
				am.play_break_sound()

func _check_player_damage() -> void:
	if not hitbox:
		return
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			var knock_dir = (body.global_position - global_position).normalized()
			body.take_damage(damage_amount, knock_dir * 120.0)

func _on_body_entered(body: Node2D) -> void:
	if current_state == SpikeState.EXTENDED and body.is_in_group("player") and body.has_method("take_damage"):
		var knock_dir = (body.global_position - global_position).normalized()
		body.take_damage(damage_amount, knock_dir * 120.0)

func _draw() -> void:
	# Taş ızgara tabanı
	draw_rect(Rect2(-14, -14, 28, 28), Color("0f172a"))
	draw_rect(Rect2(-12, -12, 24, 24), Color("1e293b"))
	
	# Diken delikleri
	for ox in [-6, 6]:
		for oy in [-6, 6]:
			draw_circle(Vector2(ox, oy), 2.5, Color("020617"))
	
	# Duruma göre dikenler
	match current_state:
		SpikeState.WARNING:
			# Titreyen metalik uçlar (sarı/turuncu uyarı parıltısı)
			var w_jitter = randf_range(-1, 1)
			for ox in [-6, 6]:
				for oy in [-6, 6]:
					draw_circle(Vector2(ox + w_jitter, oy), 2.0, Color("f59e0b"))
		SpikeState.EXTENDED:
			# Dışarı fırlamış sivri çelik kazıklar
			for ox in [-6, 6]:
				for oy in [-6, 6]:
					draw_line(Vector2(ox, oy + 4), Vector2(ox, oy - 10), Color("94a3b8"), 3.0)
					draw_line(Vector2(ox, oy - 10), Vector2(ox, oy - 14), Color("e2e8f0"), 2.0)
					draw_circle(Vector2(ox, oy - 14), 1.5, Color("ef4444")) # Kanlı sivri uç
