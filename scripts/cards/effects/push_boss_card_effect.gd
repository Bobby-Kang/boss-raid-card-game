class_name PushBossCardEffect
extends CardEffect

## 밀어내기 — 보스 덱 맨 앞(다음 예고) 카드를 뒤로 value칸 밀어낸다 (기본 3).
## 위험한 예고를 회피하되, 카드가 사라지진 않아 결국 다시 온다.
## .tres: value = 밀어낼 칸 수 (0 이하면 3)

func execute(ctx: GameContext) -> void:
	if ctx.boss_deck_system:
		ctx.boss_deck_system.push_front_back(value if value > 0 else 3)


func get_description() -> String:
	return "보스의 다음 카드를 뒤로 %d장 밀어낸다" % (value if value > 0 else 3)
