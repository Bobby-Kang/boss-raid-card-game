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
@export var artwork: Texture2D = null   # 카드 일러스트 (없으면 아이콘 폴백)
@export var effects: Array[CardEffect] = []  # ATTACK: 즉시 / POWER: 카운트 0 시 발동

# === POWER 다단 효과 (선택) ===
@export var on_draw_effects: Array[CardEffect] = []   # POWER 드로우 시 즉시 효과
@export var on_tick_effects: Array[CardEffect] = []   # POWER 매 보스 턴 (카운트 -1 직전)


func get_intent_text() -> String:
	return "%s %s — %s" % [intent_icon, card_name, description]
