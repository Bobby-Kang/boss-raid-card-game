class_name BossPhaseSystem
extends RefCounted

# 보스 페이즈 시스템
# - 3단계 페이즈 (1, 2, 3)
# - 전환 트리거: HP 임계 OR 라운드 임계 (둘 중 빠른 쪽)
# - 단방향: 페이즈는 올라가기만 함

signal phase_changed(new_phase: int, old_phase: int)

# 페이즈 전환 임계 (HP는 boss_max_hp 기준 비율, round는 절대값)
const HP_THRESHOLDS := [0.66, 0.33]   # Phase 2 진입, Phase 3 진입
const ROUND_THRESHOLDS := [3, 5]      # 라운드 강제 트리거

var current_phase: int = 1
var ctx: GameContext


func _init(game_ctx: GameContext) -> void:
	ctx = game_ctx


# 보스 HP 변경 시 호출
func check_hp_trigger() -> void:
	_evaluate(-1)


# 라운드 시작 시 호출
func check_round_trigger(current_round: int) -> void:
	_evaluate(current_round)


func _evaluate(round_value: int) -> void:
	if ctx == null:
		return
	var hp_ratio: float = 1.0
	if ctx.boss_max_hp > 0:
		hp_ratio = float(ctx.boss_hp) / float(ctx.boss_max_hp)
	var target_phase := 1
	for i in range(HP_THRESHOLDS.size()):
		var hp_hit: bool = hp_ratio <= float(HP_THRESHOLDS[i])
		var round_hit: bool = round_value > 0 and round_value >= int(ROUND_THRESHOLDS[i])
		if hp_hit or round_hit:
			target_phase = i + 2  # i=0 → phase 2, i=1 → phase 3
	if target_phase > current_phase:
		var old := current_phase
		current_phase = target_phase
		phase_changed.emit(current_phase, old)
