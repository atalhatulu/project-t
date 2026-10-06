extends Node2D

# Project T - Adım Parçacıkları (StepParticles)
# Çimen veya toprak üzerinde koşarken küçük pixel toz/yaprak parçacıkları saçar

var particles: Array[Dictionary] = []
var footprints: Array[Dictionary] = []

func spawn_particles(pos: Vector2, particle_color: Color, count: int = 3) -> void:
	for i in range(count):
		particles.append({
			"pos": pos + Vector2(randf_range(-4, 4), randf_range(-2, 2)),
			"vel": Vector2(randf_range(-12, 12), randf_range(-8, -2)),
			"color": particle_color,
			"alpha": 1.0,
			"life": 0.35 + randf() * 0.15
		})
	queue_redraw()

func spawn_footprint(pos: Vector2, surface_color: Color, angle: float = 0.0) -> void:
	footprints.append({
		"pos": pos,
		"color": surface_color,
		"angle": angle,
		"alpha": 0.65,
		"life": 3.2
	})
	if footprints.size() > 40:
		footprints.pop_front()
	queue_redraw()

func _process(delta: float) -> void:
	var needs_redraw = false
	if not particles.is_empty():
		needs_redraw = true
		var i = particles.size() - 1
		while i >= 0:
			var p = particles[i]
			p["life"] -= delta
			p["pos"] += p["vel"] * delta
			p["vel"].y += 35.0 * delta # Hafif yerçekimi
			p["alpha"] = clamp(p["life"] / 0.45, 0.0, 1.0)

			if p["life"] <= 0.0:
				particles.remove_at(i)
			i -= 1

	if not footprints.is_empty():
		needs_redraw = true
		var j = footprints.size() - 1
		while j >= 0:
			var fp = footprints[j]
			fp["life"] -= delta
			fp["alpha"] = clamp(fp["life"] / 3.2 * 0.65, 0.0, 0.65)
			if fp["life"] <= 0.0:
				footprints.remove_at(j)
			j -= 1

	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	# 1. Önce zemindeki ayak izleri çizilir
	for fp in footprints:
		var col = fp["color"] as Color
		col.a = fp["alpha"]
		var local_pos = to_local(fp["pos"])
		draw_set_transform(local_pos, fp["angle"], Vector2(1, 1))
		draw_rect(Rect2(-2, -1, 4, 2), col)
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))

	# 2. Havada uçuşan toz/yaprak parçacıkları
	for p in particles:
		var col = p["color"] as Color
		col.a = p["alpha"]
		draw_rect(Rect2(to_local(p["pos"]), Vector2(2, 2)), col)
