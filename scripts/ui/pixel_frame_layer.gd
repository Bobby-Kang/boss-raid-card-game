class_name PixelFrameLayer
extends Control

## 픽셀 프레임을 기능 UI와 분리된 "배경 레이어"로 그린다.
## 기능 패널(드롭존 등)은 투명하게 두고, 이 레이어의 NinePatchRect가
## 각 대상 패널의 위치·크기를 매 프레임 따라간다.
##
## 분리의 이점:
##  - 드롭존 등의 stylebox 변경이 프레임을 지우는 문제 원천 차단
##  - expand 로 프레임을 내용보다 크게(바깥으로) 확장 가능
##  - 프레임과 내용의 크기·위치를 독립 조절
##
## 사용 (main_scene):
##   _frame_layer = PixelFrameLayer.new()
##   add_child(_frame_layer); move_child(_frame_layer, 1)  # Background 바로 위
##   _frame_layer.register(%ActiveZone)

# 두 가지 액자 스타일:
#   STONE — 두꺼운 돌 액자(panel_frame.png), 안쪽 돌바닥까지 채움. 큰 영역 배경용.
#   THIN  — 얇은 청동 테두리(panel_frame_thin.png), 안쪽 투명(뒤 돌바닥이 비침). 영역 구획용.
enum { STONE, THIN }

const FILL_TEX_PATH := "res://assets/art/pixel-lab/panel_fill.png"
const FILL_INSET := 20     # STONE 안쪽 돌바닥이 테두리 밑으로 들어가는 여백
const FILL_COLOR := Color(0.14, 0.11, 0.09, 0.95)   # fill 텍스처 없을 때 대체 단색

# 스타일별 설정
const STYLE := {
	STONE: {
		tex = "res://assets/art/pixel-lab/panel_frame.png",
		patch = 60, draw_center = true, fill = true,
		boost = Color(1, 1, 1),
	},
	THIN: {
		tex = "res://assets/art/pixel-lab/panel_frame_thin.png",
		patch = 22, draw_center = false, fill = false,
		boost = Color(2.2, 1.9, 1.5),   # 어두운 얇은 테두리를 청동톤으로 밝힘
	},
}

var _entries: Array = []   # [{target, rect, fill, expand}]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## target 패널 뒤에 프레임을 붙인다.
##   expand > 0 이면 내용보다 사방 expand px 크게.
##   style = STONE(두꺼운 돌 배경) / THIN(얇은 청동 테두리, 안쪽 비침)
func register(target: Control, expand: int = 0, style: int = STONE) -> void:
	if target == null:
		return
	var cfg: Dictionary = STYLE[style]
	# 안쪽 돌바닥 — STONE 스타일만 채운다 (THIN은 뒤가 비쳐야 하므로 없음)
	var fill: Control = null
	if cfg.fill:
		var fill_tex := load(FILL_TEX_PATH) if ResourceLoader.exists(FILL_TEX_PATH) else null
		if fill_tex:
			var tr := TextureRect.new()
			tr.texture = fill_tex
			tr.stretch_mode = TextureRect.STRETCH_TILE   # 늘리지 않고 반복 — 픽셀 밀도 유지
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fill = tr
		else:
			var cr := ColorRect.new()
			cr.color = FILL_COLOR
			fill = cr
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	var np := NinePatchRect.new()
	np.texture = load(cfg.tex)
	np.patch_margin_left   = cfg.patch
	np.patch_margin_top    = cfg.patch
	np.patch_margin_right  = cfg.patch
	np.patch_margin_bottom = cfg.patch
	# 가장자리를 늘리지 말고 원본 크기로 반복 (벽돌 뭉개짐 방지)
	np.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	np.axis_stretch_vertical   = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	np.self_modulate = cfg.boost
	np.draw_center = cfg.draw_center
	add_child(np)
	_entries.append({target = target, rect = np, fill = fill, expand = expand})


func _process(_dt: float) -> void:
	# 대상 패널의 전역 rect를 추적 — 레이아웃/애니메이션 변화 자동 반영
	for e in _entries:
		var t: Control = e.target
		var np: NinePatchRect = e.rect
		var fill: Control = e.fill
		if not is_instance_valid(t):
			np.visible = false
			if fill:
				fill.visible = false
			continue
		np.visible = t.is_visible_in_tree()
		if fill:
			fill.visible = np.visible
		if not np.visible:
			continue
		var r: Rect2 = t.get_global_rect()
		var ex := float(e.expand)
		np.global_position = r.position - Vector2(ex, ex)
		np.size = r.size + Vector2(ex * 2.0, ex * 2.0)
		# 안쪽 배경은 테두리 밑으로 살짝 들어가게 (모서리 삐져나옴 방지)
		if fill:
			fill.global_position = np.global_position + Vector2(FILL_INSET, FILL_INSET)
			fill.size = np.size - Vector2(FILL_INSET * 2.0, FILL_INSET * 2.0)
