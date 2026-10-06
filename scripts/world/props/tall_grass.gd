@tool
extends Area2D

# Project T - Etkileşimli Uzun Ot Kümesi (TallGrass)
# Oyuncu veya NPC içinden geçerken otlar yaylanarak yana yatar, ardından eski haline döner.

@export var grass_color: Color = Color("38672d")
@export var grass_highlight: Color = Color("529e46")

var bend_angle: float = 0.0
var bend_velocity: float = 0.0
var is_being_trampled: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 # Player (2) ve NPC (4)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	queue_redraw()

func _process(delta: float) -> void:
	# Yay simülasyonu (Spring physics - otun eski dik haline dönmesi)
	var spring_k = 45.0
	var damping = 7.5
	var force = -spring_k * bend_angle
	bend_velocity += force * delta
	bend_velocity -= damping * bend_velocity * delta
	bend_angle += bend_velocity * delta

	if abs(bend_angle) > 0.02 or abs(bend_velocity) > 0.05:
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	is_being_trampled = true
	var move_x = 0.0
	if body is CharacterBody2D:
		move_x = (body as CharacterBody2D).velocity.x

	# Geçiş yönüne göre bükülme itkisi
	var impulse = 0.6 if move_x >= 0.0 else -0.6
	bend_velocity += impulse * 12.0

	# Çimen parçacıkları
	if body.is_in_group("player"):
		var step_fx = body.get_node_or_null("StepParticles")
		if step_fx and step_fx.has_method("spawn_particles"):
			step_fx.spawn_particles(global_position + Vector2(0, -4), grass_highlight, 3)

	# Çimen ayak sesi efekti
	var am = get_node_or_null("/root/AudioManager")
	if am and body.is_in_group("player"):
		am.play_footstep(am.SurfaceType.GRASS)

func _on_body_exited(_body: Node2D) -> void:
	is_being_trampled = false
	bend_velocity -= bend_angle * 6.0 # Çıkışta ters yaylanma

func _draw() -> void:
	# 5 adet uzun ot sapı
	var stems = [
		Vector2(-6, 0), Vector2(-3, -1), Vector2(0, 0),
		Vector2(3, -1), Vector2(6, 0)
	]
	var heights = [10.0, 14.0, 16.0, 13.0, 11.0]

	for i in range(stems.size()):
		var base = stems[i]
		var h = heights[i]
		var sway_x = bend_angle * (h * 0.75)
		var tip = base + Vector2(sway_x, -h)
		var mid = base + Vector2(sway_x * 0.4, -h * 0.5)

		# Ot sapı
		draw_line(base, mid, grass_color, 2.0)
		draw_line(mid, tip, grass_highlight, 1.5)
