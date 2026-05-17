class_name BossBloodScentEffect
extends CardEffect

## 피 냄새 활성화 — HP ≤50% 시 모든 보스 공격 ×1.3.
## value 미사용 (단일 발동 트리거).

func execute(ctx: GameContext) -> void:
	ctx.activate_blood_scent()

func get_description() -> String:
	return "피 냄새 활성 (HP 50% 이하 시 공격 +30%)"
