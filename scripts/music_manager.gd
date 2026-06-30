class_name MusicManager extends Node
## Procedural music system - rhythmic, layered, dynamic.
## Layers: 1) Sub-bass kick on beat  2) Bass pulse  3) Pad chords (evolving)
## 4) Mid arpeggio (rhythmic)  5) Bright lead (intro/highlight)
## 6) Subtle space hiss (always-on ambient)
## State-adaptive: calmer chords on menu, intense arpeggio during play,
## softer on game over. Tempo adapts to combat intensity.

const SR := 44100
const INV_SR := 1.0 / 44100.0

# Chord progression - Am -> F -> C -> G (i-VI-III-VII in A minor)
# These create an atmospheric, slightly melancholic space feel.
const CHORD_HZ := [
	[220.00, 261.63, 329.63],  # Am (A3, C4, E4)
	[174.61, 220.00, 261.63],  # F (F3, A3, C4)
	[261.63, 329.63, 392.00],  # C (C4, E4, G4)
	[196.00, 246.94, 293.66],  # G (G3, B3, D4)
]
const CHORD_BEATS := 4  # beats per chord

# Beat / tempo
const BPM_CALM := 84.0
const BPM_INTENSE := 124.0
var _bpm: float = 84.0

var _player: AudioStreamPlayer
var _stream: AudioStreamGenerator
var _playback: AudioStreamPlayback

# Phases (one per oscillator channel)
var _p_bass: float = 0.0
var _p_sub: float = 0.0
var _p_pad: float = 0.0
var _p_arp: float = 0.0
var _p_lead: float = 0.0
var _p_hiss: float = 0.0
var _p_kick: float = 0.0

# Musical state
var _sample_count: int = 0
var _bar_start_sample: int = 0
var _bar_index: int = 0
var _chord_index: int = 0
var _arp_step: int = 0
var _kick_env: float = 0.0  # envelope state

# Dynamic control
var _intensity: float = 0.3
var _target_intensity: float = 0.3
var _running: bool = false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = SR
	_stream.buffer_length = 0.4
	_player.stream = _stream
	_player.play()
	_playback = _player.get_stream_playback()
	_player.volume_db = linear_to_db(Game.volume)
	SignalBus.state_changed.connect(_on_state_changed)
	SignalBus.volume_changed.connect(_on_volume_changed)
	_running = true


func _on_state_changed(state: int) -> void:
	match state:
		Game.State.MENU: _target_intensity = 0.25
		Game.State.PLAYING: _target_intensity = 0.95
		Game.State.GAME_OVER: _target_intensity = 0.15


func _on_volume_changed(v: float) -> void:
	_player.volume_db = linear_to_db(clampf(v, 0.0, 1.0))


func _process(delta: float) -> void:
	if not _running:
		return
	_intensity = lerpf(_intensity, _target_intensity, delta * 1.5)
	_bpm = lerpf(BPM_CALM, BPM_INTENSE, _intensity)
	_fill_buffer()


func _bar_samples() -> int:
	# 4 beats per bar, 60/BPM seconds per beat, 4 beats/bar
	return int(60.0 / _bpm * 4.0 * SR)


func _fill_buffer() -> void:
	var frames_available: int = _playback.get_frames_available()
	if frames_available <= 0:
		return
	var buf := PackedVector2Array()
	buf.resize(frames_available)
	var bar_len: int = _bar_samples()
	for i in frames_available:
		# Advance bar/chord/arp timing
		var local := _sample_count - _bar_start_sample
		if local >= bar_len:
			_bar_start_sample = _sample_count
			local = 0
			_bar_index += 1
			_chord_index = (_chord_index + 1) % CHORD_HZ.size()
			_arp_step = 0
		var beat: int = (local * 4) / bar_len  # 0..3
		var in_beat: float = float((local * 4) % bar_len) / float(bar_len)  # 0..1 within beat
		# Trigger kick on beat 1 and 3 of every bar (with slight swing when intense)
		if (beat == 0 or beat == 2) and in_beat < 0.04:
			_kick_env = 1.0
		# Advance arp step every 1/8 note
		var eighth: int = (local * 8) / bar_len
		if eighth != _arp_step:
			_arp_step = eighth
		var sample: float = _mix(beat, in_beat, eighth)
		# Slight stereo width
		buf[i] = Vector2(sample, sample * 0.92)
		_sample_count += 1
	_playback.push_buffer(buf)


func _mix(beat: int, in_beat: float, eighth: int) -> float:
	var s: float = 0.0
	var chord: Array = CHORD_HZ[_chord_index]

	# 1. Sub-bass KICK: short, punchy 60Hz sine with fast decay
	if _kick_env > 0.001:
		var kf := 60.0
		_p_kick += INV_SR
		var kick := sin(_p_kick * TAU * kf) * _kick_env
		kick += sin(_p_kick * TAU * kf * 2.0) * _kick_env * 0.3
		kick *= 0.35
		s += kick
		_kick_env *= 0.985  # decay per sample (~exponential)

	# 2. BASS: held root note, soft saw via stacked sines (octave + fifth)
	_p_bass += INV_SR
	var root: float = chord[0] / 2.0  # octave below for low end
	var bass := sin(_p_bass * TAU * root) * 0.10
	bass += sin(_p_bass * TAU * root * 2.0) * 0.04
	bass += sin(_p_bass * TAU * root * 3.0) * 0.02
	# Slight pulse on each beat (0.95..1.05 amplitude) for groove
	var beat_pulse := 1.0 + sin(in_beat * PI) * 0.15
	bass *= beat_pulse
	s += bass

	# 3. PAD: smooth evolving chord - 3 sine waves with slow LFO
	_p_pad += INV_SR
	var pad_lfo := 0.5 + sin(_p_pad * 0.3) * 0.5  # slow filter-like movement
	for n in chord.size():
		s += sin(_p_pad * TAU * chord[n]) * 0.04 * pad_lfo

	# 4. ARP: bright pluck on each 8th note, cycling through chord tones
	_p_arp += INV_SR
	var arp_notes: Array = [chord[0] * 2.0, chord[1] * 2.0, chord[2] * 2.0, chord[1] * 2.0]
	var arp_freq: float = arp_notes[eighth % arp_notes.size()]
	# Pluck envelope: per-beat restart
	var arp_env: float = pow(1.0 - in_beat, 2.0) if in_beat < 1.0 else 0.0
	var arp := sin(_p_arp * TAU * arp_freq) * arp_env * (0.06 + _intensity * 0.08)
	arp += sin(_p_arp * TAU * arp_freq * 2.0) * arp_env * 0.02
	s += arp

	# 5. LEAD: bright melodic layer only on intense moments (gameplay)
	_p_lead += INV_SR
	var lead_freq: float = chord[2] * 4.0  # high octave of fifth
	var lead_env: float = (0.3 + 0.7 * _intensity) * pow(0.5 + 0.5 * sin(_p_lead * 0.7), 2.0)
	var lead := sin(_p_lead * TAU * lead_freq) * 0.025 * lead_env
	lead += sin(_p_lead * TAU * lead_freq * 1.005) * 0.012 * lead_env  # chorus
	s += lead

	# 6. SPACE HISS: very subtle white noise - filtered random
	_p_hiss += INV_SR
	var hiss: float = randf_range(-1.0, 1.0) * 0.008
	s += hiss

	# Master dynamics
	s *= 0.7 + _intensity * 0.3
	# Soft saturation for warmth
	s = tanh(s * 1.3)
	return clampf(s, -0.95, 0.95)


func set_volume(vol: float) -> void:
	_player.volume_db = linear_to_db(clampf(vol, 0.0, 1.0))


func stop() -> void:
	_running = false
	_player.stop()
