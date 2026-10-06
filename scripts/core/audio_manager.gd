extends Node

# Project T - Küresel Çevresel Ses Yöneticisi (AudioManager)
# Autoload Singleton: AudioManager
# Çimen, toprak, taş, ahşap ayak sesleri ve orman kuş sesleri için sentetik ses altyapısı (AudioStreamGenerator)

enum SurfaceType { GRASS, DIRT, STONE, WOOD }

var sample_rate: float = 22050.0
var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

var ambient_player: AudioStreamPlayer
var ambient_playback: AudioStreamGeneratorPlayback

var bird_chirp_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()

func _setup_audio_players() -> void:
	# Ayak sesi generatorü
	sfx_player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = 0.1
	sfx_player.stream = gen
	sfx_player.volume_db = -12.0
	add_child(sfx_player)
	sfx_player.play()
	sfx_playback = sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback

	# Kuş sesleri ambient generatorü
	ambient_player = AudioStreamPlayer.new()
	var amb_gen = AudioStreamGenerator.new()
	amb_gen.mix_rate = sample_rate
	amb_gen.buffer_length = 0.2
	ambient_player.stream = amb_gen
	ambient_player.volume_db = -18.0
	add_child(ambient_player)
	ambient_player.play()
	ambient_playback = ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback

	bird_chirp_timer = randf_range(4.0, 9.0)

func _process(delta: float) -> void:
	# Rastgele kuş cıvıltısı zamanlayıcısı (Sadece yağmursuz açık havalarda öter)
	var wm = get_tree().get_first_node_in_group("weather_manager")
	var is_raining = wm.is_raining() if wm and wm.has_method("is_raining") else false

	if not is_raining:
		bird_chirp_timer -= delta
		if bird_chirp_timer <= 0.0:
			bird_chirp_timer = randf_range(5.0, 12.0)
			play_ambient_bird_chirp()
	else:
		# Yağmur uğultusu akışı
		_stream_rain_ambient()

func _stream_rain_ambient() -> void:
	if not ambient_playback:
		return
	var frames_to_push = int(sample_rate * 0.05)
	if ambient_playback.get_frames_available() < frames_to_push:
		return
	for i in range(frames_to_push):
		var noise = (randf() * 2.0 - 1.0) * 0.12 # Yumuşak beyaz gürültü / yağmur şırıltısı
		ambient_playback.push_frame(Vector2(noise, noise))

# Zemin türüne göre ayak sesi üretimi
func play_footstep(surface: SurfaceType) -> void:
	if not sfx_playback:
		return

	var frames_to_push = int(sample_rate * 0.045) # 45ms kısa adım sesi
	if sfx_playback.get_frames_available() < frames_to_push:
		return

	var base_freq = 180.0
	var decay = 0.85
	match surface:
		SurfaceType.GRASS:
			base_freq = 120.0 # Yumuşak hışırtı tonu
			decay = 0.80
		SurfaceType.DIRT:
			base_freq = 160.0 # Tok toprak darbesi
			decay = 0.84
		SurfaceType.STONE:
			base_freq = 340.0 # Sert taş tıkırtısı
			decay = 0.90
		SurfaceType.WOOD:
			base_freq = 240.0 # İçi boş ahşap yankısı
			decay = 0.88

	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 85.0)
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var tone = sin(TAU * base_freq * t) * 0.6
		var sample = (tone + noise) * envelope * 0.35
		sfx_playback.push_frame(Vector2(sample, sample))

# Rastgele orman kuşu cıvıltısı
func play_ambient_bird_chirp() -> void:
	if not ambient_playback:
		return

	var frames_to_push = int(sample_rate * 0.12) # 120ms kuş ötüşü
	if ambient_playback.get_frames_available() < frames_to_push:
		return

	var start_freq = randf_range(1600.0, 2200.0)
	var end_freq = start_freq + randf_range(300.0, 600.0)

	for i in range(frames_to_push):
		var t = float(i) / float(frames_to_push)
		var freq = lerp(start_freq, end_freq, sin(t * PI))
		var envelope = sin(t * PI)
		var sample = sin(TAU * freq * (float(i) / sample_rate)) * envelope * 0.2
		ambient_playback.push_frame(Vector2(sample, sample))

# Etkileşim sesi (Sandık, bitki toplama, tabela okuma)
func play_interact_sound(type: String = "default") -> void:
	if not sfx_playback:
		return
	var frames_to_push = int(sample_rate * 0.08) # 80ms
	if sfx_playback.get_frames_available() < frames_to_push:
		return
	var base_freq = 520.0
	match type:
		"chest":
			base_freq = 280.0
		"plant":
			base_freq = 640.0
		"sign":
			base_freq = 420.0
	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 35.0)
		var sample = sin(TAU * base_freq * t) * envelope * 0.35
		sfx_playback.push_frame(Vector2(sample, sample))

# Kasa kırılma / darbe sesi
func play_break_sound() -> void:
	if not sfx_playback:
		return
	var frames_to_push = int(sample_rate * 0.1) # 100ms
	if sfx_playback.get_frames_available() < frames_to_push:
		return
	for i in range(frames_to_push):
		var t = float(i) / sample_rate
		var envelope = exp(-t * 40.0)
		var noise = (randf() * 2.0 - 1.0) * 0.6
		var tone = sin(TAU * 110.0 * t) * 0.4
		var sample = (noise + tone) * envelope * 0.45
		sfx_playback.push_frame(Vector2(sample, sample))
