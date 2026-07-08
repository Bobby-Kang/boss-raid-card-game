class_name PushBossCardEffect
extends CardEffect

## 밀어내기 — 보스 덱 맨 앞(다음 예고) 카드를 맨 뒤로 보낸다.
## 위험한 예고를 회피하는 보스 타임라인 간섭 동사.

func execute(ctx: GameContext) -> void:
	if ctx.boss_deck_system:
		ctx.boss_deck_system.push_front_to_back()


func get_description() -> String:
	return "보스의 다음 카드를 덱 맨 뒤로"
