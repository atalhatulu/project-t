extends PointLight2D

# Project T - Akıllı Köy Feneri / Sokak Lambası
# Gece ve alacakaranlıkta otomatik yanar, gündüz söner.
# Titrek alev efekti (flicker) ile sıcak atmosfer oluşturur.

@export var max_energy: float = 1.0
@export var enable_flicker: bool = true

var base_energy: float = 0.0
var flicker_offset: float = 0.0

func _ready() -> void:
	flicker_offset = randf() * 100.0
	color = Color("ffba66") # Sıcak sarı-turuncu alev ışığı
	texture_scale = 1.2
	_setup_texture()

func _setup_texture() -> void:
	if texture != null:
		return
	# Yumuşak radyal ışık dokusu (GradientTexture2D)
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])

	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 128
	grad_tex.height = 128
	texture = grad_tex

func _process(delta: float) -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var hour_dec = tm.get_decimal_hour() if tm else 22.0

	# 19:00 ile 06:00 arasında yanar
	var target_energy = 0.0
	if hour_dec >= 18.5 or hour_dec < 6.0:
		if hour_dec >= 18.5 and hour_dec < 20.0:
			# Yavaşça parlar
			target_energy = ((hour_dec - 18.5) / 1.5) * max_energy
		elif hour_dec >= 5.0 and hour_dec < 6.0:
			# Şafakta yavaşça söner
			target_energy = (1.0 - ((hour_dec - 5.0) / 1.0)) * max_energy
		else:
			target_energy = max_energy

	base_energy = lerp(base_energy, target_energy, delta * 3.0)

	if enable_flicker and base_energy > 0.05:
		var noise = sin(Time.get_ticks_msec() * 0.008 + flicker_offset) * 0.08
		energy = clamp(base_energy + noise, 0.0, 2.0)
	else:
		energy = base_energy

	enabled = (energy > 0.01)
