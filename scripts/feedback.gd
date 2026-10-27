extends Node2D
## Short feedback effects. Hit-stop uses a monotonic clock and never blocks input.
var particles: Array = []
var captions: Array = []
var traces: Array = []
var rng = RandomNumberGenerator.new()
var stop_until = 0
var enabled = true
var shake_level = 1.0
var flash_level = 1.0
var sound_enabled = true
var trauma = 0.0
var clock = 0.0
var camera: Camera2D
var font: Font
var sounds: Dictionary = {}
var voices: Array = []
var voice_index = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = 1805
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "sans-serif"])
	for i in range(10):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)
	build_sounds()

func build_sounds():
	# Filtered noise plus soft decaying resonances, not square-wave beeps.
	var params = {"swing": [0.12, 150.0, 0.8], "hit": [0.14, 98.0, 0.32], "heavy": [0.24, 65.0, 0.35], "break": [0.30, 135.0, 0.5], "dash": [0.15, 90.0, 0.9], "shot": [0.15, 200.0, 0.45], "hurt": [0.23, 73.0, 0.3], "heal": [0.34, 370.0, 0.08], "pickup": [0.16, 530.0, 0.05]}
	for key in params:
		var p = params[key]
		var bytes = PackedByteArray()
		var sample_count = int(p[0] * 22050)
		bytes.resize(sample_count * 2)
		var filtered = 0.0
		for i in range(sample_count):
			var t = float(i) / 22050.0
			var u = float(i) / sample_count
			filtered = lerpf(filtered, rng.randf_range(-1, 1), 0.16)
			var envelope = sin(minf(u * 16, PI / 2)) * pow(1 - u, 2.6)
			var wave = sin(TAU * p[1] * t * (1 - u * 0.25)) * (1 - p[2]) + filtered * p[2] * 2
			bytes.encode_s16(i * 2, int(clampf(wave * envelope * 22000, -32767, 32767)))
		var audio = AudioStreamWAV.new()
		audio.format = AudioStreamWAV.FORMAT_16_BITS
		audio.mix_rate = 22050
		audio.data = bytes
		sounds[key] = audio

func sound(key: String):
	if not sound_enabled or not sounds.has(key): return
	var voice = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = sounds[key]
	voice.pitch_scale = rng.randf_range(0.94, 1.06)
	voice.play()

func freeze(milliseconds: int):
	if not enabled: return
	# Extend to the largest current deadline rather than summing per victim.
	stop_until = maxi(stop_until, Time.get_ticks_msec() + milliseconds)
	Engine.time_scale = 0.05

func reset():
	stop_until = 0
	Engine.time_scale = 1.0
	trauma = 0
	particles.clear()
	captions.clear()
	traces.clear()

func impact(pos: Vector2, amount: int, heavy: bool, broken: bool = false):
	var color = Color("f6df9f") if not broken else Color("8bd2c5")
	burst(pos, color, 12 if heavy else 7)
	float_text(str(amount), pos - Vector2(0, 9), color)
	trauma = minf(1, trauma + (0.30 if heavy else 0.10))
	freeze(75 if broken else (50 if heavy else 25))
	sound("break" if broken else ("heavy" if heavy else "hit"))

func burst(pos: Vector2, color: Color, count: int):
	for i in range(count):
		particles.append({"p": pos, "v": Vector2(rng.randf_range(-95, 95), rng.randf_range(-100, 25)), "life": rng.randf_range(0.15, 0.38), "color": color})

func float_text(value: String, pos: Vector2, color: Color):
	captions.append({"text": value, "p": pos, "life": 0.7, "color": color})

func _process(dt):
	var real_dt = minf(dt / maxf(Engine.time_scale, 0.01), 0.05)
	if stop_until > 0 and Time.get_ticks_msec() >= stop_until:
		stop_until = 0
		Engine.time_scale = 1.0
	if get_tree().paused: return
	clock += real_dt
	trauma = maxf(0, trauma - real_dt * 3.3)
	if is_instance_valid(camera): camera.offset = Vector2(sin(clock * 83), sin(clock * 107)) * trauma * trauma * 7 * shake_level
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= dt
		p.p += p.v * dt
		p.v.y += dt * 280
		if p.life <= 0: particles.remove_at(i)
	for i in range(captions.size() - 1, -1, -1):
		captions[i].life -= dt
		captions[i].p.y -= dt * 25
		if captions[i].life <= 0: captions.remove_at(i)
	for i in range(traces.size() - 1, -1, -1):
		traces[i].life -= dt
		if traces[i].life <= 0: traces.remove_at(i)
	queue_redraw()

func _draw():
	for trace in traces: draw_rect(Rect2(trace.p - Vector2(6, 27), Vector2(12, 25)), Color(0.45, 0.8, 0.79, trace.life * 2))
	for p in particles: draw_rect(Rect2(p.p.floor(), Vector2(2, 2)), p.color)
	for caption in captions:
		var color: Color = caption.color
		color.a = minf(1, caption.life * 3)
		draw_string(font, caption.p.floor(), caption.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, color)

func _exit_tree():
	Engine.time_scale = 1.0
