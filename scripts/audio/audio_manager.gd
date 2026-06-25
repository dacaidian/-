extends Node
class_name AudioManager

const CONFIG_KEY_BGM := "bgm"
const CONFIG_KEY_SFX := "sfx"
const DEFAULT_BGM_BUS := "Music"
const DEFAULT_SFX_BUS := "SFX"
const FALLBACK_BUS := "Master"
const DEFAULT_SFX_POOL_SIZE := 12
const PROCEDURAL_SAMPLE_RATE := 22050.0

var audio_config: Dictionary = {}
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_bgm_key := ""

var _procedural_playback: AudioStreamGeneratorPlayback
var _procedural_music_active := false
var _music_time := 0.0
var _procedural_chords := [
	[146.83, 220.00, 293.66],
	[164.81, 246.94, 329.63],
	[130.81, 196.00, 261.63],
	[174.61, 261.63, 349.23]
]


func setup(config_path: String, sfx_pool_size := DEFAULT_SFX_POOL_SIZE) -> void:
	load_config(config_path)
	setup_players(sfx_pool_size)


func load_config(config_path: String) -> void:
	audio_config.clear()
	if config_path == "" or not FileAccess.file_exists(config_path):
		return

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return

	var parsed_data = JSON.parse_string(file.get_as_text())
	if parsed_data is Dictionary:
		audio_config = parsed_data


func setup_players(sfx_pool_size: int) -> void:
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BgmPlayer"
		bgm_player.bus = get_existing_bus(DEFAULT_BGM_BUS)
		add_child(bgm_player)

	for player in sfx_players:
		if is_instance_valid(player):
			player.queue_free()
	sfx_players.clear()

	var pool_size := maxi(sfx_pool_size, 1)
	for index in range(pool_size):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.name = "SfxPlayer_%02d" % index
		sfx_player.bus = get_existing_bus(DEFAULT_SFX_BUS)
		add_child(sfx_player)
		sfx_players.append(sfx_player)


func play_bgm(audio_key: String) -> void:
	if bgm_player == null or audio_key == "":
		return
	if current_bgm_key == audio_key and bgm_player.playing:
		return

	var entry := get_audio_entry(CONFIG_KEY_BGM, audio_key)
	current_bgm_key = audio_key
	_procedural_music_active = false
	_procedural_playback = null

	var stream := load_stream_from_entry(entry)
	if stream != null:
		bgm_player.stream = stream
		bgm_player.volume_db = float(entry.get("volume_db", -8.0))
		bgm_player.bus = get_existing_bus(str(entry.get("bus", DEFAULT_BGM_BUS)))
		bgm_player.play()
		return

	if bool(entry.get("procedural", false)):
		play_procedural_bgm(entry)


func stop_bgm() -> void:
	current_bgm_key = ""
	_procedural_music_active = false
	_procedural_playback = null
	if bgm_player != null:
		bgm_player.stop()


func play_sfx(audio_key: String) -> void:
	if audio_key == "":
		return

	var entry := get_audio_entry(CONFIG_KEY_SFX, audio_key)
	var stream := load_stream_from_entry(entry)
	if stream == null:
		return

	var player := get_available_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.volume_db = float(entry.get("volume_db", 0.0))
	player.pitch_scale = float(entry.get("pitch_scale", 1.0))
	player.bus = get_existing_bus(str(entry.get("bus", DEFAULT_SFX_BUS)))
	player.play()


func play_spell_sfx(spell_data: Dictionary) -> void:
	var audio_key := resolve_spell_audio_key(spell_data)
	if audio_key != "":
		play_sfx(audio_key)


func resolve_spell_audio_key(spell_data: Dictionary) -> String:
	var explicit_audio := str(spell_data.get("audio", ""))
	if explicit_audio != "":
		return explicit_audio

	var animation_key := str(spell_data.get("animation", ""))
	if animation_key == "":
		return ""

	var candidate := "spell_%s" % animation_key
	if has_audio_entry(CONFIG_KEY_SFX, candidate):
		return candidate

	if has_audio_entry(CONFIG_KEY_SFX, animation_key):
		return animation_key

	return ""


func get_audio_entry(section: String, audio_key: String) -> Dictionary:
	var section_data = audio_config.get(section, {})
	if section_data is Dictionary:
		var entry = section_data.get(audio_key, {})
		if entry is Dictionary:
			return entry
	return {}


func has_audio_entry(section: String, audio_key: String) -> bool:
	var section_data = audio_config.get(section, {})
	return section_data is Dictionary and section_data.has(audio_key)


func load_stream_from_entry(entry: Dictionary) -> AudioStream:
	var path := str(entry.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null

	var resource := ResourceLoader.load(path)
	return resource as AudioStream


func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	if not sfx_players.is_empty():
		return sfx_players[0]
	return null


func get_existing_bus(bus_name: String) -> String:
	if bus_name != "" and AudioServer.get_bus_index(bus_name) >= 0:
		return bus_name
	return FALLBACK_BUS


func play_procedural_bgm(entry: Dictionary) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = PROCEDURAL_SAMPLE_RATE
	stream.buffer_length = 0.5

	bgm_player.stream = stream
	bgm_player.volume_db = float(entry.get("volume_db", -18.0))
	bgm_player.bus = get_existing_bus(str(entry.get("bus", DEFAULT_BGM_BUS)))
	bgm_player.play()

	_procedural_playback = bgm_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_procedural_music_active = _procedural_playback != null
	_music_time = 0.0


func _process(_delta: float) -> void:
	if not _procedural_music_active or _procedural_playback == null:
		return

	var frames_available := _procedural_playback.get_frames_available()
	for _frame_index in range(frames_available):
		var sample := generate_procedural_bgm_sample(_music_time)
		_procedural_playback.push_frame(Vector2(sample, sample))
		_music_time += 1.0 / PROCEDURAL_SAMPLE_RATE


func generate_procedural_bgm_sample(time: float) -> float:
	var chord_index := int(floor(time / 4.0)) % _procedural_chords.size()
	var chord: Array = _procedural_chords[chord_index]
	var pulse := 0.55 + 0.45 * sin(TAU * 0.25 * time)
	var shimmer := 0.0

	for tone_index in range(chord.size()):
		var tone_freq := float(chord[tone_index])
		var slow_voice := sin(TAU * tone_freq * time) * 0.055
		var high_voice := sin(TAU * tone_freq * 2.0 * time + float(tone_index) * 0.7) * 0.018
		shimmer += slow_voice + high_voice

	var bass_freq := float(chord[0]) * 0.5
	var bass := sin(TAU * bass_freq * time) * 0.075
	var heartbeat_phase := fmod(time, 2.0)
	var heartbeat := exp(-heartbeat_phase * 7.0) * 0.035

	return clamp((shimmer * pulse + bass + heartbeat) * 0.55, -0.35, 0.35)
