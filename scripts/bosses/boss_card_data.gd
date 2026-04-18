class_name BossCardData
extends Resource

# 보스 카드 타입
# ATTACK: 즉시 실행 후 버린 카드 더미로
# POWER: 파워 존에 놓이며 카운트다운 시작, 0 도달 시 발동
enum BossCardType { ATTACK, POWER }

@export var card_name: String = ""
@export var card_type: BossCardType = BossCardType.ATTACK
@export var countdown: int = 0          # POWER 전용: 발동까지 남은 보스 턴 수
@export var intent_icon: String = "⚔️"  # 배너 표시용 아이콘
@export var description: String = ""
@export var effects: Array[CardEffect] = []


func get_intent_text() -> String:
	return "%s %s — %s" % [intent_icon, card_name, description]
