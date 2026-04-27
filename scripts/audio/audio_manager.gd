extends Node
## 오디오 매니저 (Autoload 싱글톤)
## - BGM 재생 + 크로스페이드
## - SFX 풀(8슬롯)을 통한 동시 재생
## - 에셋이 없으면 조용히 스킵 (개발 중 크래시 방지)

const SFX_POOL_SIZE := 8

var bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_bgm_path: String = ""

# 사용자가 옵션 메뉴에서 조절할 수 있는 마스터 볼륨 (0.0 ~ 1.0)
var master_volume: float = 1.0
var bgm_volume: float = 0.7
var sfx_volume: float = 1.0


func _ready() -> void:
	# BGM 플레이어 (단일)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	# SFX 풀
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)


# === SFX ===

func play_sfx(key: String, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	var path: String = SfxLibrary.PATHS.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return  # 에셋 미배치 — 조용히 스킵
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var p := _get_free_sfx_player()
	p.stream = stream
	p.volume_db = volume_db + linear_to_db(sfx_volume * master_volume)
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation) if pitch_variation > 0 else 1.0
	p.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	# 모두 재생 중이면 가장 오래된(0번) 재사용
	return _sfx_players[0]


# === BGM ===

func play_bgm(path: String, fade_in: float = 0.0) -> void:
	if path == _current_bgm_path and bgm_player.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_enable_loop(stream)
	_current_bgm_path = path
	bgm_player.stream = stream
	if fade_in > 0:
		bgm_player.volume_db = -60.0
		bgm_player.play()
		var tween := create_tween()
		tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume * master_volume), fade_in)
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()


func crossfade_bgm(path: String, duration: float = 1.5) -> void:
	if path == _current_bgm_path:
		return
	if not ResourceLoader.exists(path):
		return
	var new_stream: AudioStream = load(path)
	if new_stream == null:
		return
	_enable_loop(new_stream)
	_current_bgm_path = path
	var target_db := linear_to_db(bgm_volume * master_volume)
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -60.0, duration * 0.5)
	tween.tween_callback(func() -> void:
		bgm_player.stream = new_stream
		bgm_player.play()
	)
	tween.tween_property(bgm_player, "volume_db", target_db, duration * 0.5)


# 스트림 종류에 따라 loop 속성을 안전하게 활성화
func _enable_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 4 if stream.format == AudioStreamWAV.FORMAT_16_BITS else stream.data.size() / 2


func stop_bgm(fade_out: float = 0.0) -> void:
	_current_bgm_path = ""
	if fade_out <= 0:
		bgm_player.stop()
		return
	var tween := create_tween()
	tween.tween_property(bgm_player, "volume_db", -60.0, fade_out)
	tween.tween_callback(bgm_player.stop)
