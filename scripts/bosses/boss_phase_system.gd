class_name BossPhaseSystem
extends RefCounted

# 보스 페이즈 시스템
# - 3단계 페이즈 (1, 2, 3)
# - 전환 트리거: ① HP 임계값 도달 ② 보스 덱이 상위 페이즈 카드에 진입 (둘 중 먼저 = OR)
# - 단방향: 페이즈는 올라가기만 함

signal phase_changed(new_phase: int, old_phase: int)

# 페이즈 전환 HP 임계 (boss_max_hp 기준 비율)
const HP_THRESHOLDS := [0.66, 0.33]   # Phase 2 진입, Phase 3 진입

var current_phase: int = 1
var ctx: GameContext


func _init(game_ctx: GameContext) -> void:
	ctx = game_ctx


# 보스 HP 변경 시 호출
func check_hp_trigger() -> void:
	if ctx == null:
		return
	var hp_ratio: float = 1.0
	if ctx.boss_max_hp > 0:
		hp_ratio = float(ctx.boss_hp) / float(ctx.boss_max_hp)
	var target_phase := 1
	for i in range(HP_THRESHOLDS.size()):
		if hp_ratio <= float(HP_THRESHOLDS[i]):
			target_phase = i + 2  # i=0 → phase 2, i=1 → phase 3
	_advance_to(target_phase)


# 보스 덱이 card_phase 페이즈 카드에 진입하면 게임 페이즈도 맞춰 올린다 (단방향)
func check_deck_trigger(card_phase: int) -> void:
	_advance_to(card_phase)


# 공통 승격 — target이 현재보다 높을 때만 전환
func _advance_to(target_phase: int) -> void:
	if target_phase > current_phase:
		var old := current_phase
		current_phase = target_phase
		phase_changed.emit(current_phase, old)
