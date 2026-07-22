#!/usr/bin/env python3
"""단일 스프라이트에서 idle 호흡 프레임을 합성한다.

**AI로 프레임을 따로 생성하지 말 것.** 정합은 맞출 수 있어도 매 프레임 그림을
다시 그려서 잡음이 낀다(실측: 다리가 37% 변함 — 호흡이면 미동도 없어야 하는 부위).
애니메이션으로 돌리면 호흡이 아니라 지글거림으로 보인다.

픽셀아트 idle의 정석대로 **원본 한 장에서 상체만 1px 올려** 만든다.
잡음 0, 완전 제어, 비용 0.

사용:
  python tools/make_idle.py sprite.png --pivot 85 --out-dir dir/
    → sprite_idle1.png(원본) / sprite_idle2.png(들숨) 생성
"""
import argparse
import os

from PIL import Image


def shift_upper(img: Image.Image, pivot: int, dy: int) -> Image.Image:
    """pivot 위쪽(상체)만 dy만큼 세로 이동. 경계는 한 줄 겹쳐 이어 붙여 틈을 막는다."""
    out = img.copy()
    # pivot 행까지 한 줄 더 포함해서 옮겨야 경계에 빈 줄이 생기지 않는다
    upper = img.crop((0, 0, img.width, pivot + abs(dy)))
    out.paste(upper, (0, dy))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", help="처리된 스프라이트(최종 해상도)")
    ap.add_argument("--pivot", type=int, required=True,
                    help="허리 y좌표. 이 위쪽이 호흡으로 움직인다")
    ap.add_argument("--amount", type=int, default=1, help="들숨 이동량(px). 기본 1")
    ap.add_argument("--exhale", action="store_true",
                    help="날숨 프레임(상체 +1px)도 만들어 4프레임 루프용으로")
    ap.add_argument("--out-dir", default=None, help="출력 폴더(기본: 원본과 같은 곳)")
    a = ap.parse_args()

    img = Image.open(a.src).convert("RGBA")
    # 위로 올릴 여유 1px 확보 (머리가 캔버스 위로 잘리지 않게)
    pad = Image.new("RGBA", (img.width, img.height + a.amount), (0, 0, 0, 0))
    pad.paste(img, (0, a.amount))
    img = pad
    pivot = a.pivot + a.amount

    base = os.path.splitext(os.path.basename(a.src))[0]
    out_dir = a.out_dir or os.path.dirname(a.src)
    os.makedirs(out_dir, exist_ok=True)

    frames = [("idle1", img)]
    frames.append(("idle2", shift_upper(img, pivot, -a.amount)))   # 들숨
    if a.exhale:
        frames.append(("idle3", shift_upper(img, pivot, a.amount)))  # 날숨

    for name, f in frames:
        p = os.path.join(out_dir, f"{base}_{name}.png")
        f.save(p)
        print(f"  {p}  {f.width}x{f.height}")


if __name__ == "__main__":
    main()
