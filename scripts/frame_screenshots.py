#!/usr/bin/env python3
"""Wrap raw app captures in a desktop window frame for the README.

A bare screenshot of a desktop app reads as a crop of somebody's monitor.
Putting it in a window — rounded corners, a title bar, a soft shadow —
tells the reader at a glance that LingoDesk is a desktop application, and
makes a column of screenshots look like one set rather than several.

The output is a transparent PNG, so the same file sits correctly on
GitHub's light and dark themes.

Usage:
    scripts/frame_screenshots.py raw.png screenshots/dashboard.png \\
        --title "LingoDesk" --theme dark

    # A capture that already includes macOS's own title bar:
    scripts/frame_screenshots.py raw.png out.png --no-chrome
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:  # pragma: no cover - dependency hint
    sys.exit("Pillow is required: python3 -m pip install --user Pillow")

# Chrome geometry, in output pixels at scale 1. Everything scales with the
# rendered width so a 2x capture keeps the same proportions.
TITLEBAR_HEIGHT = 34
CORNER_RADIUS = 12
DOT_RADIUS = 6
DOT_GAP = 20
DOT_INSET = 20

# Traffic lights, in macOS order.
DOT_COLORS = ((0xFF, 0x5F, 0x57), (0xFE, 0xBC, 0x2E), (0x28, 0xC8, 0x40))

# Everything except the title bar fill, which is sampled from the capture
# itself — LingoDesk ships six theme variants, each tinting its own
# neutrals, so a hardcoded chrome colour would clash with five of them.
THEMES = {
    "dark": {
        "border": (0xFF, 0xFF, 0xFF, 0x24),
        "title": (0xFF, 0xFF, 0xFF, 0xB0),
        "shadow_alpha": 150,
    },
    "light": {
        "border": (0x00, 0x00, 0x00, 0x1A),
        "title": (0x00, 0x00, 0x00, 0x8C),
        "shadow_alpha": 70,
    },
}


def sample_titlebar(shot: Image.Image) -> tuple[int, int, int, int]:
    """The sidebar colour at the top-left of the capture.

    Continuing the app's own chrome upward makes the frame read as part of
    the window rather than a sticker on top of it, and it tracks whichever
    theme variant the capture was taken in.
    """
    px = shot.convert("RGB").getpixel((6, 6))
    return (px[0], px[1], px[2], 0xFF)


# Pillow's built-in bitmap font is 11px and has no em-dash, so the title
# is set in a real system face where one is available.
FONT_CANDIDATES = (
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
)


def title_font(size: int):
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    """An L-mode mask of a rounded rectangle filling `size`."""
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255
    )
    return mask


def add_chrome(
    shot: Image.Image, theme: dict, title: str | None, scale: float
) -> Image.Image:
    """Return `shot` with a title bar above it and a hairline around it."""
    bar_h = int(TITLEBAR_HEIGHT * scale)
    card = Image.new("RGBA", (shot.width, shot.height + bar_h), sample_titlebar(shot))
    card.paste(shot, (0, bar_h))

    draw = ImageDraw.Draw(card)
    cy = bar_h // 2
    for index, color in enumerate(DOT_COLORS):
        cx = int((DOT_INSET + index * DOT_GAP) * scale)
        r = DOT_RADIUS * scale
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color + (0xFF,))

    if title:
        font = title_font(max(11, int(13 * scale)))
        bbox = draw.textbbox((0, 0), title, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        # Centred on the bar, and only when it clears the traffic lights.
        dots_end = int((DOT_INSET + 2 * DOT_GAP + DOT_RADIUS * 2) * scale)
        if (card.width - tw) // 2 > dots_end:
            draw.text(
                ((card.width - tw) // 2, cy - th // 2 - bbox[1]),
                title,
                font=font,
                fill=theme["title"],
            )

    # Hairline, drawn last so it sits on top of both bar and content.
    radius = int(CORNER_RADIUS * scale)
    ImageDraw.Draw(card).rounded_rectangle(
        (0, 0, card.width - 1, card.height - 1),
        radius=radius,
        outline=theme["border"],
        width=max(1, int(scale)),
    )
    return card


def frame(
    source: Path,
    dest: Path,
    *,
    width: int,
    chrome: bool,
    theme_name: str,
    title: str | None,
) -> None:
    theme = THEMES[theme_name]
    shot = Image.open(source).convert("RGBA")

    # Captures come off a retina display at 2x; resample once, here, so the
    # chrome is drawn at the final resolution instead of being scaled with
    # the content and going soft.
    if shot.width != width:
        height = round(shot.height * width / shot.width)
        shot = shot.resize((width, height), Image.LANCZOS)

    scale = width / 1400  # 1400px reads as a "normal" window width
    scale = max(0.75, min(scale, 2.0))

    card = add_chrome(shot, theme, title, scale) if chrome else shot

    radius = int(CORNER_RADIUS * scale)
    mask = rounded_mask(card.size, radius)
    card.putalpha(mask)

    # Room for the shadow to fall without being clipped.
    pad = int(28 * scale)
    drop = int(10 * scale)
    canvas = Image.new(
        "RGBA", (card.width + pad * 2, card.height + pad * 2 + drop), (0, 0, 0, 0)
    )

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, theme["shadow_alpha"]), (pad, pad + drop), mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(11 * scale)))

    canvas.alpha_composite(shadow)
    canvas.alpha_composite(card, (pad, pad))

    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest, "PNG", optimize=True)
    kb = dest.stat().st_size / 1024
    print(f"{dest}  {canvas.width}x{canvas.height}  {kb:.0f} KB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("dest", type=Path)
    parser.add_argument(
        "--width",
        type=int,
        default=1400,
        help="rendered width of the app content, in pixels (default 1400)",
    )
    parser.add_argument(
        "--no-chrome",
        dest="chrome",
        action="store_false",
        help="the capture already has a title bar; only round and shadow it",
    )
    parser.add_argument("--theme", choices=sorted(THEMES), default="dark")
    parser.add_argument("--title", default=None)
    args = parser.parse_args()

    frame(
        args.source,
        args.dest,
        width=args.width,
        chrome=args.chrome,
        theme_name=args.theme,
        title=args.title,
    )


if __name__ == "__main__":
    main()
