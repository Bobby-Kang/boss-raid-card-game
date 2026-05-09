class_name SfxLibrary
extends RefCounted
## SFX 키 → 파일 경로 매핑.
## 에셋이 res:// 에 존재하지 않으면 AudioManager가 조용히 스킵합니다.
##
## 새 SFX 추가 시: 아래 PATHS 딕셔너리에 키와 경로를 추가하세요.

const KENNEY_DIR := "res://assets/audio/kenny_audio"

const PATHS := {
	# === 카드 (Kenney Casino Audio) ===
	"card.draw":          KENNEY_DIR + "/kenney_casino-audio/Audio/card-slide-1.ogg",
	"card.play":          KENNEY_DIR + "/kenney_casino-audio/Audio/card-place-1.ogg",
	"card.discard":       KENNEY_DIR + "/kenney_casino-audio/Audio/card-shove-1.ogg",
	"card.hover":         KENNEY_DIR + "/kenney_ui-audio/Audio/rollover1.ogg",
	"card.shuffle":       KENNEY_DIR + "/kenney_casino-audio/Audio/card-shuffle.ogg",
	"card.exile":         KENNEY_DIR + "/kenney_impact-sounds/Audio/impactGlass_heavy_002.ogg",

	# === 전투 (Kenney Impact Sounds) ===
	"combat.hit_player":  KENNEY_DIR + "/kenney_impact-sounds/Audio/impactPunch_medium_000.ogg",
	"combat.hit_boss":    KENNEY_DIR + "/kenney_impact-sounds/Audio/impactPunch_heavy_000.ogg",
	"combat.block":       KENNEY_DIR + "/kenney_impact-sounds/Audio/impactPlate_medium_000.ogg",
	"combat.heal":        KENNEY_DIR + "/kenney_rpg-audio/Audio/cloth1.ogg",

	# === UI (Kenney UI Audio) ===
	"ui.button":          KENNEY_DIR + "/kenney_ui-audio/Audio/click1.ogg",
	"ui.market_buy":      KENNEY_DIR + "/kenney_rpg-audio/Audio/handleCoins.ogg",
	"ui.reroll":          KENNEY_DIR + "/kenney_casino-audio/Audio/card-shuffle.ogg",
	"ui.turn_end":        KENNEY_DIR + "/kenney_ui-audio/Audio/switch3.ogg",

	# === 보스 (Kenney Impact Sounds) ===
	"boss.power_trigger": KENNEY_DIR + "/kenney_impact-sounds/Audio/impactBell_heavy_000.ogg",
	"boss.phase_change":  KENNEY_DIR + "/kenney_impact-sounds/Audio/impactMetal_heavy_000.ogg",
	"boss.attack":        KENNEY_DIR + "/kenney_impact-sounds/Audio/impactPunch_heavy_001.ogg",

	# === 자원 ===
	"rage.gain":          KENNEY_DIR + "/kenney_impact-sounds/Audio/impactGeneric_light_000.ogg",
	"rage.consume":       KENNEY_DIR + "/kenney_impact-sounds/Audio/impactMetal_heavy_001.ogg",
	"gold.gain":          KENNEY_DIR + "/kenney_rpg-audio/Audio/handleCoins2.ogg",
}


# === BGM 경로 ===
# 현재는 단일 트랙(Pixel-City-Cruising)을 모든 페이즈에서 반복 재생
const BGM_MAIN := "res://assets/audio/Pixel-City-Cruising.ogg"

# 페이즈별 BGM (현재는 동일 트랙으로 매핑 — 추후 개별 트랙 추가 시 변경)
const BGM_PHASE_1 := BGM_MAIN
const BGM_PHASE_2 := BGM_MAIN
const BGM_PHASE_3 := BGM_MAIN
const BGM_TITLE   := BGM_MAIN
const BGM_VICTORY := BGM_MAIN
const BGM_DEFEAT  := BGM_MAIN
