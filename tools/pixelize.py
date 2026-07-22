#!/usr/bin/env python3
"""Gemini 픽셀아트풍 출력 → 진짜 픽셀아트 에셋.

Gemini는 "픽셀아트처럼 보이는 그림"을 낸다. 픽셀 크기가 제각각이고
안티에일리어싱이 껴 있어 nearest 확대 시 뭉갠다. 이 도구가 격자를 강제한다.

파이프라인:
  1. 배경 키아웃 (--key)      마젠타 등 단색 배경 → 알파
  2. 고립 조각 제거            Gemini가 구워넣는 4점 별 로고를 잡아낸다
  3. 알파 침식 (--erode)       키잉 프린지(배경색 번짐) 제거
  4. 알파 bbox 크롭 (--crop)   --height가 프레임이 아닌 캐릭터 높이를 뜻하게
  5. BOX 축소                  가짜 픽셀을 실제 격자로 뭉친다 ← 여기서 픽셀이 생김
  6. 팔레트 양자화             기본 maxcov (medcut은 횃불 같은 소수 광원을 버림)

배율 규칙: 1 아트픽셀 = 3 화면픽셀. --height = 화면 목표 높이 / 3.

예시:
  # 배경 (1920x1080 화면 → 640x360)
  python tools/pixelize.py bg_raw.png bg.png --height 360 --method maxcov

  # 캐릭터 (화면 441px → 147)
  python tools/pixelize.py warrior_raw.png warrior.png --height 147 \
      --key FF00FF --tol 120 --erode 4 --crop --method medcut --colors 48
"""
import argparse
from collections import deque

from PIL import Image

# 양자화 방식은 콘텐츠에 따라 갈린다 (실측 비교 결과):
#   배경   → maxcov. 화면의 1%뿐인 횃불을 medcut이 팔레트에서 버려 광원이 꺼졌다.
#   캐릭터 → medcut. 얼굴 살색이 주인공인데 maxcov가 희귀 극단색에 슬롯을 쓰느라
#            살색을 분홍 얼룩으로 뭉갰다. 48색이면 충분.
METHODS = {
    "maxcov": Image.MAXCOVERAGE,   # 색 공간 커버리지 우선 — 소수 극단색(광원)을 지킴
    "octree": Image.FASTOCTREE,
    "medcut": Image.MEDIANCUT,     # 픽셀 수 가중 — 주요 색조(살색)를 지킴
}


def key_out(img: Image.Image, key: tuple, tol: int) -> Image.Image:
    """tol = 키 색과의 RGB 유클리드 거리. 이 안쪽이 투명해진다.

    너무 키우면 배경이 아니라 내용을 먹는다. 마젠타 기준 살색은 거리 ~215라
    tol 200을 넘기면 얼굴이 통째로 사라진다 (실제로 그랬다). 120이 안전선.
    """
    kr, kg, kb = key
    lim = tol * tol
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if (r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2 <= lim:
                px[x, y] = (0, 0, 0, 0)
    return img


def drop_small_parts(img: Image.Image, min_ratio: float) -> Image.Image:
    """가장 큰 덩어리 대비 min_ratio 미만인 고립 조각을 지운다.

    Gemini가 배경에 찍는 4점 별 로고는 배경색이 아니라서 키아웃으로는
    안 지워지지만, 캐릭터와 떨어져 있으므로 여기서 걸린다.
    """
    w, h = img.size
    alpha = img.getchannel("A").load()
    label = [0] * (w * h)
    sizes = [0]
    cur = 0

    for sy in range(h):
        for sx in range(w):
            i = sy * w + sx
            if label[i] or not alpha[sx, sy]:
                continue
            cur += 1
            n = 0
            q = deque([(sx, sy)])
            label[i] = cur
            while q:
                x, y = q.popleft()
                n += 1
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if not label[j] and alpha[nx, ny]:
                            label[j] = cur
                            q.append((nx, ny))
            sizes.append(n)

    if cur <= 1:
        return img

    biggest = max(sizes)
    doomed = {i for i, n in enumerate(sizes) if i and n < biggest * min_ratio}
    if not doomed:
        return img

    px = img.load()
    for y in range(h):
        for x in range(w):
            if label[y * w + x] in doomed:
                px[x, y] = (0, 0, 0, 0)
    print(f"  dropped {len(doomed)} stray part(s) of {cur}")
    return img


def erode_alpha(img: Image.Image, rounds: int) -> Image.Image:
    """불투명 영역을 1px씩 깎아 키잉 프린지를 제거."""
    w, h = img.size
    for _ in range(rounds):
        src = img.getchannel("A").load()
        keep = bytearray(w * h)
        for y in range(h):
            for x in range(w):
                if not src[x, y]:
                    continue
                edge = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and not src[nx, ny]:
                        edge = True
                        break
                if not edge:
                    keep[y * w + x] = 255
        na = Image.frombytes("L", (w, h), bytes(keep))
        img.putalpha(na)
    return img


def quantize_keep_alpha(img: Image.Image, colors: int, method: str,
                        alpha_cut: int) -> Image.Image:
    # 축소하면 가장자리 알파가 소수값이 된다 — 픽셀아트는 경계가 딱 떨어져야
    # 하므로 이진화한다. alpha_cut=0이면 반투명 유지.
    alpha = img.getchannel("A")
    if alpha_cut:
        alpha = alpha.point(lambda v: 255 if v >= alpha_cut else 0)
    q = img.convert("RGB").quantize(colors=colors, method=METHODS[method],
                                    dither=Image.Dither.NONE)
    out = q.convert("RGBA")
    out.putalpha(alpha)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--height", type=int, required=True,
                    help="네이티브 높이(px) = 화면 목표 높이 / 3")
    ap.add_argument("--key", help="배경 키 색 16진수 (예: FF00FF)")
    ap.add_argument("--tol", type=int, default=120,
                    help="키 색과의 RGB 거리. 200+면 살색까지 먹는다")
    ap.add_argument("--erode", type=int, default=0, help="알파 침식 횟수")
    ap.add_argument("--crop", action="store_true", help="알파 bbox로 크롭")
    ap.add_argument("--crop-box", help="크롭 박스를 직접 지정 'x1,y1,x2,y2'. "
                                       "애니메이션 프레임은 반드시 이걸로 **공통 박스**를 "
                                       "써야 한다 — 프레임마다 bbox로 자르면 동작이 "
                                       "정규화돼 사라지고 프레임 간 크기도 어긋난다")
    ap.add_argument("--min-part", type=float, default=0.02,
                    help="이 비율 미만의 고립 조각 제거 (0이면 끔)")
    ap.add_argument("--colors", type=int, default=32, help="팔레트 색 수")
    ap.add_argument("--alpha-cut", type=int, default=128,
                    help="축소 후 알파 이진화 문턱 (0이면 반투명 유지)")
    ap.add_argument("--method", choices=list(METHODS), default="maxcov",
                    help="양자화 방식 (medcut은 작은 광원을 버림)")
    ap.add_argument("--preview", type=int, default=0, help="N배 nearest 확대본도 저장")
    a = ap.parse_args()

    img = Image.open(a.src).convert("RGBA")
    src_size = img.size

    if a.key:
        img = key_out(img, tuple(int(a.key[i:i + 2], 16) for i in (0, 2, 4)), a.tol)
        if a.min_part > 0:
            img = drop_small_parts(img, a.min_part)
        if a.erode:
            img = erode_alpha(img, a.erode)

    if a.crop_box:
        box = tuple(int(v) for v in a.crop_box.split(","))
        img = img.crop(box)
        print(f"  cropped to shared box {box} -> {img.size[0]}x{img.size[1]}")
    elif a.crop:
        box = img.getbbox()
        if box:
            img = img.crop(box)
            print(f"  cropped to {img.size[0]}x{img.size[1]}")

    w = max(1, round(img.size[0] * a.height / img.size[1]))
    img = img.resize((w, a.height), Image.BOX)
    img = quantize_keep_alpha(img, a.colors, a.method, a.alpha_cut)
    img.save(a.dst)

    n = len(img.convert("RGB").getcolors(maxcolors=1 << 24) or [])
    print(f"{a.src} {src_size[0]}x{src_size[1]} -> {a.dst} {w}x{a.height} ({n} colors)")

    if a.preview:
        p = img.resize((w * a.preview, a.height * a.preview), Image.NEAREST)
        pv = a.dst.replace(".png", f"_x{a.preview}.png")
        p.save(pv)
        print(f"  preview {pv} {p.width}x{p.height}")


if __name__ == "__main__":
    main()
