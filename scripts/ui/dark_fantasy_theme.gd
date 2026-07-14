class_name DarkFantasyTheme
extends RefCounted

## 다크 판타지 프리미엄 UI 테마 (코드 빌드).
## main_scene 루트에 적용하면 모든 PanelContainer/Panel/Button/Label/HSeparator가 자동 통일.
## 개별 노드가 add_theme_*_override 한 경우는 그 노드가 우선 (의도된 커스텀 유지).

# === 색 팔레트 ===
const BG_DEEP        := Color(0.09, 0.07, 0.05, 1.0)    # 최심부 배경
const BG_MID         := Color(0.13, 0.10, 0.07, 1.0)    # 배경 그라데이션 상단
const SURFACE        := Color(0.16, 0.12, 0.09, 0.92)   # 패널 표면
const SURFACE_LIGHT  := Color(0.22, 0.17, 0.12, 0.95)   # 밝은 패널/버튼
const GOLD           := Color(0.78, 0.62, 0.34, 1.0)    # 액센트 금색
const GOLD_BRIGHT    := Color(0.92, 0.78, 0.48, 1.0)
const GOLD_DIM       := Color(0.45, 0.36, 0.22, 1.0)
const TEXT           := Color(0.91, 0.85, 0.73, 1.0)    # 양피지 텍스트
const TEXT_DIM       := Color(0.62, 0.55, 0.45, 1.0)
const PLAYER_BLUE    := Color(0.42, 0.66, 0.92, 1.0)
const BOSS_RED       := Color(0.85, 0.33, 0.30, 1.0)

# === Kenney 프레임 (2톤 구움: 금속 테두리 + 어두운 중앙) ===
# modulate 단색은 중앙이 진흙색이 되어, 테두리·중앙을 분리해 구운 전용 프레임을 쓴다.
# 스왑: gold / steel / blued 중 파일명만 바꾸면 전체 반영.
const KENNEY_FRAME := "res://assets/art/Kenny/baked/frame_gold.png"


# 카드 타입별 프레임 색 (레인 구분 + 프리미엄). enum CardType 순서: ATTACK,SKILL,POWER,MODULE
const CARD_FRAMES := {
	0: "res://assets/art/Kenny/baked/frame_attack.png",  # ATTACK — 붉은 구리
	1: "res://assets/art/Kenny/baked/frame_blued.png",   # SKILL  — 블루 스틸
	2: "res://assets/art/Kenny/baked/frame_power.png",   # POWER  — 바이올렛
	3: "res://assets/art/Kenny/baked/frame_gold.png",    # MODULE — 골드
}


# 카드 타입에 맞는 프레임 스타일박스
static func card_frame(card_type: int) -> StyleBoxTexture:
	return kenney_panel(true, 8, CARD_FRAMES.get(card_type, KENNEY_FRAME))


# Kenney 버튼 프레임 (#001 기반, 상태별로 구운 텍스처). 버튼은 짧으니 여백 작게.
static func kenney_button(state: String) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load("res://assets/art/Kenny/baked/%s.png" % state)
	s.texture_margin_left = 14
	s.texture_margin_top = 14
	s.texture_margin_right = 14
	s.texture_margin_bottom = 14
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


# 공용 Kenney 프레임 스타일박스.
#   draw_center=true  → 어두운 패널 배경까지 (색은 이미 구워짐 → modulate 없음)
#   draw_center=false → 테두리만(아트·이미지가 깨끗이 보임)
static func kenney_panel(draw_center: bool = true, content_margin: int = 14, tex_path: String = KENNEY_FRAME) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(tex_path)
	s.texture_margin_left = 16
	s.texture_margin_top = 16
	s.texture_margin_right = 16
	s.texture_margin_bottom = 16
	s.draw_center = draw_center
	s.content_margin_left = content_margin
	s.content_margin_right = content_margin
	s.content_margin_top = content_margin
	s.content_margin_bottom = content_margin
	return s


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16

	# ─── PanelContainer / Panel — 기본을 Kenney 프레임으로 (전 화면 통일) ───
	theme.set_stylebox("panel", "PanelContainer", kenney_panel(true, 10))
	theme.set_stylebox("panel", "Panel", kenney_panel(true, 10))

	# ─── Label ───
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	theme.set_constant("outline_size", "Label", 0)
	theme.set_font_size("font_size", "Label", 16)

	# ─── Button — Kenney 프레임(#001) 3상태 + 비활성 ───
	theme.set_stylebox("normal", "Button", kenney_button("btn_normal"))
	theme.set_stylebox("hover", "Button", kenney_button("btn_hover"))
	theme.set_stylebox("pressed", "Button", kenney_button("btn_pressed"))
	theme.set_stylebox("disabled", "Button", kenney_button("btn_disabled"))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_pressed_color", "Button", GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	theme.set_font_size("font_size", "Button", 16)

	# ─── HSeparator / VSeparator (금색 가는 선) ───
	var sep := StyleBoxLine.new()
	sep.color = GOLD_DIM
	sep.thickness = 1
	theme.set_stylebox("separator", "HSeparator", sep)
	var vsep := StyleBoxLine.new()
	vsep.color = GOLD_DIM
	vsep.thickness = 1
	vsep.vertical = true
	theme.set_stylebox("separator", "VSeparator", vsep)

	# ─── ProgressBar / 기타 기본 ───
	return theme


# 표준 패널 StyleBoxFlat — 반투명 표면 + 금색 테두리 + 둥근 모서리 + 내부 여백
static func _panel_style(bg: Color, border: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	# 살짝 떠 보이는 그림자
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s
