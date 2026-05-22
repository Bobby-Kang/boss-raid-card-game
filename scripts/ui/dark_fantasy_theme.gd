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


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16

	# ─── PanelContainer / Panel ───
	var panel := _panel_style(SURFACE, GOLD_DIM, 2, 8)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel.duplicate())

	# ─── Label ───
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	theme.set_constant("outline_size", "Label", 0)
	theme.set_font_size("font_size", "Label", 16)

	# ─── Button (구매 / 턴 종료 / 리롤 등) ───
	var btn_normal := _panel_style(SURFACE_LIGHT, GOLD_DIM, 2, 6)
	var btn_hover  := _panel_style(SURFACE_LIGHT.lightened(0.12), GOLD, 2, 6)
	var btn_pressed := _panel_style(SURFACE.darkened(0.1), GOLD_BRIGHT, 2, 6)
	var btn_disabled := _panel_style(Color(0.14, 0.12, 0.10, 0.6), GOLD_DIM.darkened(0.3), 1, 6)
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
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
