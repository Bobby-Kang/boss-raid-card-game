class_name CombatFeedback
extends Node
## 전투 햅틱 효과 모음 — 화면 셰이크 / 캐릭터 펀치 플래시 / Hit-stop.
## main_scene이 child로 추가하고 setup() 으로 셰이크 대상(루트 Control) 주입.

const FLASH_TINT := Color(2.2, 0.45, 0.45, 1)
const FLASH_DURATION := 0.05
const RECOIL_SCALE := Vector2(1.12, 0.92)
const RECOIL_DURATION := 0.06
const RETURN_DURATION := 0.28
const HIT_STOP_TIMESCALE := 0.05
const HIT_STOP_DURATION := 0.04

var _shake_target: Control = null
var _shake_tween: Tween = null
var _hit_stop_active: bool = false


func setup(shake_target: Control) -> void:
	_shake_target = shake_target


# 캐릭터가 피해 받을 때: 빨간 플래시 + 스케일 펀치 + 살짝 기울임
# direction_x 양수=우측(보스), 음수=좌측(플레이어)
func flash_recoil(target: Control, direction_x: float) -> void:
	if target == null:
		return
	target.pivot_offset = target.size / 2.0
	var tilt := deg_to_rad(direction_x * 0.18)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(target, "modulate", FLASH_TINT, FLASH_DURATION)
	tween.tween_property(target, "scale", RECOIL_SCALE, RECOIL_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "rotation", tilt, RECOIL_DURATION)
	tween.chain().tween_property(target, "modulate", Color.WHITE, RETURN_DURATION - 0.06)
	tween.parallel().tween_property(target, "scale", Vector2.ONE, RETURN_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(target, "rotation", 0.0, RETURN_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# 명중 순간 짧은 시간 정지 (타격감)
func hit_stop() -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = HIT_STOP_TIMESCALE
	var timer := get_tree().create_timer(HIT_STOP_DURATION, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


# 화면 흔들림
func shake_screen(intensity: float = 7.0, duration: float = 0.25) -> void:
	if _shake_target == null:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
		_shake_target.position = Vector2.ZERO
	_shake_tween = create_tween()
	var steps := maxi(int(duration / 0.04), 3)
	for i in steps:
		var off := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity * 0.5, intensity * 0.5)
		)
		_shake_tween.tween_property(_shake_target, "position", off, 0.04)
	_shake_tween.tween_property(_shake_target, "position", Vector2.ZERO, 0.04)
