class_name PixelFrame
extends RefCounted

## 픽셀 다크판타지 9-slice 패널 프레임을 Control 배경에 공용 적용하는 헬퍼.
## panel_frame.png (256×256): 모서리 청동 장식 ≈60px.
##   - texture_filter NEAREST: 확대 시 흐려지지 않게
##   - TILE_FIT: 벽돌 테두리를 늘리지 않고 원본 크기로 반복
## 사용: PixelFrame.apply_panel(some_panel_container)

const PANEL_TEX_PATH := "res://assets/art/pixel-lab/panel_frame.png"
const CORNER_MARGIN := 60   # 모서리 장식 고정 여백(px)


# content_margin: 내용물이 테두리 안쪽에서 시작하는 여백
# corner: 9-slice 모서리 고정 크기. 얇은 바(높이<130px)는 22 정도로 줄여야 깨지지 않는다.
static func apply_panel(ctrl: Control, content_margin: int = 16, corner: int = CORNER_MARGIN) -> void:
	if ctrl == null:
		return
	var tex := load(PANEL_TEX_PATH)
	if tex == null:
		return
	# 픽셀 텍스처는 nearest 로 그려야 확대 시 뭉개지지 않는다
	ctrl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left   = corner
	sb.texture_margin_top    = corner
	sb.texture_margin_right  = corner
	sb.texture_margin_bottom = corner
	# 가장자리(벽돌)를 늘리지 말고 원본 크기로 반복해 채운다
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical   = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	# 내용물이 돌 테두리 안쪽에서 시작하도록
	sb.content_margin_left   = content_margin
	sb.content_margin_right  = content_margin
	sb.content_margin_top    = content_margin
	sb.content_margin_bottom = content_margin
	ctrl.add_theme_stylebox_override("panel", sb)
