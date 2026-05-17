class_name BossReflectDamageEffect
extends CardEffect

## 보스 현재 방어도만큼 플레이어 피해 (웅크리기 발동).
## 피해 후 보스 방어도는 *유지* (반사이지 소모 X).
## 피 냄새 / 공격력 보너스는 적용 안 함 (이미 누적된 방어도가 값이라서).

func execute(ctx: GameContext) -> void:
	if ctx.boss_block <= 0:
		return
	ctx.deal_damage_to_player(ctx.boss_block)

func get_description() -> String:
	return "보스 방어도만큼 플레이어 반사 피해"
