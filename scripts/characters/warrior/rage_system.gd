class_name WarriorRageSystem
extends RefCounted

## 전사 전용 — 투기 발산 시스템.
## 플레이어 턴 종료 시 남은 AP를 투기 스택으로 치환하고,
## 10스택 도달 시 발동하여 보스 10 피해 + 플레이어 방어도 10을 부여한다.
##
## GameContext에는 이 시스템 관련 상태가 존재하지 않는다.
## main_scene에서 GameContext 참조를 주입받아 피해/방어도 부여를 위임한다.

signal rage_changed(stacks: int, max_stacks: int)

const MAX_RAGE := 10

var stacks: int = 0
var ctx: GameContext


func _init(game_ctx: GameContext) -> void:
	ctx = game_ctx


func add(amount: int) -> void:
	if amount <= 0:
		return
	stacks = mini(stacks + amount, MAX_RAGE)
	rage_changed.emit(stacks, MAX_RAGE)


func can_consume() -> bool:
	return stacks >= MAX_RAGE


func consume() -> bool:
	if not can_consume():
		return false
	ctx.deal_damage_to_boss(10)
	ctx.add_block(10)
	stacks = 0
	rage_changed.emit(stacks, MAX_RAGE)
	return true
