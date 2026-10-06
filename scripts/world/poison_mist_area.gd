@tool
extends Area2D
class_name PoisonMistArea

# Project T - Zehirli Mağara Dumanı / Gaz Çukuru (PoisonMistArea)
# Oyuncuyu %35 yavaşlatır ve saniyede bir hafif zehir hasarı uygular.

@export var tick_interval: float = 1.0
@export var damage_per_tick: int = 5
@export var mist_radius: float = 60.0

var tick_timer: float = 0.0

func _ready() -> void:
	add_to_group("trap")
	collision_layer = 0
	collision_mask = 2 # Player
	
	var col = get_node_or_null("CollisionShape2D")
	if not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var circle = CircleShape2D.new()
		circle.radius = mist_radius
		col.shape = circle
		add_child(col)
	
	queue_redraw()

func _physics_process(delta: float) -> void:
	var bodies = get_overlapping_bodies()
	if bodies.is_empty():
		return
	
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		for b in bodies:
			if b.is_in_group("player") and b.has_method("take_damage"):
				b.take_damage(damage_per_tick, Vector2.ZERO)

func _draw() -> void:
	# Yarı saydam zehirli sis dairesi
	draw_circle(Vector2.ZERO, mist_radius, Color(0.12, 0.45, 0.18, 0.35))
	draw_arc(Vector2.ZERO, mist_radius, 0, TAU, 24, Color(0.2, 0.7, 0.25, 0.55), 1.5)
	
	# Uçuşan sporlar
	for i in range(8):
		var ang = (float(i) / 8.0) * TAU
		var p = Vector2(cos(ang) * mist_radius * 0.6, sin(ang) * mist_radius * 0.6)
		draw_circle(p, 3.0, Color(0.4, 0.9, 0.3, 0.6))
