class_name WarriorRageSystem
extends RefCounted

## 전사 전용 — 투기 발산 시스템.
## 플레이어 턴 종료 시 남은 AP를 투기 스택으로 치환하고,
## 최대 스택 도달 시 발동하여 보스에게 피해 + 플레이어 방어도를 부여한다.
##
## 수치 조정: scripts/data/game_balance.gd 참고
##   - RAGE_MAX_STACKS   : 최대 스택 수
##   - RAGE_BURST_DAMAGE : 발산 시 보스 피해
##   - RAGE_BURST_BLOCK  : 발산 시 획득 방어도

signal rage_changed(stacks: int, max_stacks: int)

var stacks: int = 0
var ctx: GameContext


func _init(game_ctx: GameContext) -> void:
	ctx = game_ctx


func add(amount: int) -> void:
	if amount <= 0:
		return
	stacks = mini(stacks + amount, GameBalance.RAGE_MAX_STACKS)
	rage_changed.emit(stacks, GameBalance.RAGE_MAX_STACKS)


func can_consume() -> bool:
	return stacks >= GameBalance.RAGE_MAX_STACKS


func consume() -> bool:
	if not can_consume():
		return false
	ctx.deal_damage_to_boss(GameBalance.RAGE_BURST_DAMAGE)
	ctx.add_block(GameBalance.RAGE_BURST_BLOCK)
	stacks = 0
	rage_changed.emit(stacks, GameBalance.RAGE_MAX_STACKS)
	return true
