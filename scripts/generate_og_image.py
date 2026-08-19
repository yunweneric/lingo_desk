#!/usr/bin/env python3
"""Render web/og-image.png — the card every link unfurl shows.

The landing page is a Flutter app painting to a canvas, so no crawler can
read a word of it. Whatever this script produces *is* LingoDesk on
WhatsApp, Slack, X and LinkedIn — at roughly the size of a playing card.

So the card is built for that size: the app mark, the product name, one
headline, one supporting line, and the URL. Deliberately no screenshot —
a 1200x630 shrink of the dashboard is unreadable noise in a chat thread.

Type is Urbanist, the app's only family, pulled from Google's font repo
and cached under build/. Everything is drawn at 3x and downsampled, which
is what keeps the rounded corners and the type edges clean.

Requires Pillow:  python3 -m pip install --user Pillow
Run from the repo root:
    python3 scripts/generate_og_image.py
"""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - dependency hint
    sys.exit("Pillow is required: python3 -m pip install --user Pillow")

OUT = pathlib.Path("web/og-image.png")

# The size every unfurl expects. Anything else gets cropped by somebody.
WIDTH, HEIGHT = 1200, 630

# Supersampling factor. Pillow's shape drawing has no anti-aliasing of its
# own, so the whole card is drawn large and resized down once at the end.
SS = 3

# Dark theme tokens, straight from lib/core/theme/lingo_desk_palette.dart.
BACKGROUND = (0x0E, 0x1B, 0x18)
BRAND = (0x0F, 0x76, 0x6E)
ACCENT = (0x2F, 0xA3, 0x96)
BRAND_FILL = (0x14, 0x43, 0x3D)
ON_BRAND_FILL = (0xCF, 0xE6, 0xE0)
WHITE = (0xFF, 0xFF, 0xFF)

FONT_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/urbanist/Urbanist%5Bwght%5D.ttf"
FONT_CACHE = pathlib.Path("build/og_fonts/Urbanist.ttf")


# --------------------------------------------------------------------------
# type


def urbanist(size: int, weight: str = "Regular") -> ImageFont.FreeTypeFont:
    """One Urbanist instance. `weight` names a master on the wght axis."""
    font = ImageFont.truetype(str(FONT_CACHE), size * SS)
    font.set_variation_by_name(weight)
    return font


def ensure_font() -> None:
    """Fetch the Urbanist variable font once, into a gitignored cache.

    Downloaded rather than vendored because assets/ is bundled into the
    shipped app by pubspec.yaml, and this face is only ever needed by
    this script. curl rather than urllib: python.org builds on macOS ship
    without a usable CA bundle.
    """
    if FONT_CACHE.exists():
        return
    if shutil.which("curl") is None:
        sys.exit("curl not found — needed to fetch the Urbanist font")
    FONT_CACHE.parent.mkdir(parents=True, exist_ok=True)
    print(f"  fetching Urbanist -> {FONT_CACHE}")
    subprocess.run(
        ["curl", "-sSfL", FONT_URL, "-o", str(FONT_CACHE)], check=True
    )


def text_width(text: str, font: ImageFont.FreeTypeFont, tracking: float = 0) -> float:
    """Advance width in supersampled pixels, including letter spacing."""
    return font.getlength(text) + tracking * SS * max(len(text) - 1, 0)


def write(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    font: ImageFont.FreeTypeFont,
    fill,
    tracking: float = 0,
    anchor: str = "ls",
) -> None:
    """Draw `text`, optionally letter-spaced.

    Pillow is built without libraqm here, so it applies no kerning pairs
    anyway — drawing glyph by glyph to apply tracking costs nothing that
    the normal path was providing.
    """
    x, y = xy
    if anchor[0] == "m":
        x -= text_width(text, font, tracking) / 2
    elif anchor[0] == "r":
        x -= text_width(text, font, tracking)
    vertical = anchor[1]

    if not tracking:
        draw.text((x, y), text, font=font, fill=fill, anchor="l" + vertical)
        return

    for char in text:
        draw.text((x, y), char, font=font, fill=fill, anchor="l" + vertical)
        x += font.getlength(char) + tracking * SS


def wrap(text: str, font: ImageFont.FreeTypeFont, max_width: float) -> list[str]:
    lines: list[str] = []
    line = ""
    for word in text.split():
        candidate = f"{line} {word}".strip()
        if line and font.getlength(candidate) > max_width:
            lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    return lines


# --------------------------------------------------------------------------
# paint helpers


def px(value: float) -> float:
    """Layout units are written at 1x; the canvas is drawn at SS."""
    return value * SS


def bloom(canvas: Image.Image, cx: float, cy: float, radius: float, rgb, alpha: float) -> None:
    """A soft radial glow.

    Built small — concentric circles on a 256px mask — then scaled up, so
    the falloff comes out smooth instead of banded.
    """
    steps = 128
    mask = Image.new("L", (256, 256), 0)
    pen = ImageDraw.Draw(mask)
    for i in range(steps, 0, -1):
        t = i / steps
        # Squared falloff: bright core, long quiet tail.
        value = int(255 * alpha * (1 - t) ** 2)
        r = 128 * t
        pen.ellipse((128 - r, 128 - r, 128 + r, 128 + r), fill=value)

    size = int(radius * 2)
    mask = mask.resize((size, size), Image.LANCZOS)
    layer = Image.new("RGBA", (size, size), rgb + (0,))
    layer.putalpha(mask)
    canvas.alpha_composite(layer, (int(cx - radius), int(cy - radius)))


def mark(size: float) -> Image.Image:
    """The brand mark from assets/brand/lingodesk_mark.svg, drawn to `size`.

    Same 64-unit grid as scripts/generate_brand_icons.py: a teal rounded
    square holding two overlapping locale tiles, the front one carrying
    the two dots that stand for a translated pair.
    """
    side = int(px(size))
    unit = side / 64
    tile = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    pen = ImageDraw.Draw(tile)

    def box(x, y, w, h, r, fill):
        pen.rounded_rectangle(
            (x * unit, y * unit, (x + w) * unit, (y + h) * unit),
            radius=r * unit,
            fill=fill,
        )

    def dot(cx, cy, r, fill):
        pen.ellipse(
            ((cx - r) * unit, (cy - r) * unit, (cx + r) * unit, (cy + r) * unit),
            fill=fill,
        )

    box(0, 0, 64, 64, 16, BRAND + (255,))
    box(16, 20, 24, 24, 7, WHITE + (115,))
    box(26, 22, 24, 24, 7, WHITE + (255,))
    dot(34, 34, 3.4, BRAND + (255,))
    dot(44, 34, 3.4, BRAND + (255,))
    return tile


def alpha(rgb, a: float):
    return rgb + (int(255 * a),)


# --------------------------------------------------------------------------
# the card


def build() -> Image.Image:
    canvas = Image.new("RGBA", (px(WIDTH), px(HEIGHT)), BACKGROUND + (255,))

    # One bloom behind the lockup and a second bleeding off the bottom, so
    # the flat brand surface still has depth without carrying a gradient.
    bloom(canvas, px(600), px(40), px(700), ACCENT, 0.30)
    bloom(canvas, px(600), px(700), px(620), BRAND, 0.34)

    draw = ImageDraw.Draw(canvas)
    draw.rectangle(
        (0, 0, px(WIDTH) - 1, px(HEIGHT) - 1),
        outline=alpha(WHITE, 0.10),
        width=SS,
    )
    draw.rectangle((0, 0, px(WIDTH), px(5)), fill=ACCENT + (255,))

    mid = px(WIDTH / 2)

    # --- lockup: the app icon and the product name, centred ----------
    icon_size, icon_top = 84, 62
    name_font = urbanist(42, "ExtraBold")
    name_w = text_width("LingoDesk", name_font, -1.2)
    gap = px(22)
    lockup_w = px(icon_size) + gap + name_w
    icon_x = mid - lockup_w / 2

    canvas.alpha_composite(mark(icon_size), (int(icon_x), int(px(icon_top))))
    write(
        draw,
        (icon_x + px(icon_size) + gap, px(icon_top + icon_size / 2)),
        "LingoDesk",
        name_font,
        WHITE + (255,),
        tracking=-1.2,
        anchor="lm",
    )

    # Eyebrow: set small and wide, so it labels the mark without
    # competing with the headline underneath it.
    write(
        draw,
        (mid, px(188)),
        "LOCALIZATION MANAGER FOR DEVELOPERS",
        urbanist(16, "Bold"),
        ACCENT + (255,),
        tracking=3.0,
        anchor="ms",
    )

    # --- headline ----------------------------------------------------
    headline = urbanist(58, "ExtraBold")
    write(draw, (mid, px(288)), "Translate every locale", headline, WHITE + (255,), -1.8, "ms")

    # Second line runs two colours, so it is centred by hand.
    parts = (("from ", WHITE + (255,)), ("one clean desk.", ACCENT + (255,)))
    total = sum(text_width(t, headline, -1.8) for t, _ in parts)
    x = mid - total / 2
    for text, colour in parts:
        write(draw, (x, px(288 + 66)), text, headline, colour, -1.8)
        x += text_width(text, headline, -1.8)

    # --- supporting line ---------------------------------------------
    body = urbanist(22, "Regular")
    sub = (
        "Every translation key a row, every language a column, "
        "every missing string impossible to miss."
    )
    for i, line in enumerate(wrap(sub, body, px(720))):
        write(draw, (mid, px(422 + i * 34)), line, body, alpha(WHITE, 0.74), anchor="ms")

    # --- footer: what it costs you, and where to find it --------------
    chip_font = urbanist(17, "SemiBold")
    chip_h, chip_pad, chip_gap = px(42), px(19), px(11)
    chip_top = px(500)
    labels = ("Open source · MIT", "Local-first", "Built with Flutter")
    widths = [text_width(l, chip_font, 0.1) + chip_pad * 2 for l in labels]
    x = mid - (sum(widths) + chip_gap * (len(labels) - 1)) / 2
    for label, w in zip(labels, widths):
        draw.rounded_rectangle(
            (x, chip_top, x + w, chip_top + chip_h),
            radius=chip_h / 2,
            fill=BRAND_FILL + (255,),
            outline=alpha(ACCENT, 0.42),
            width=SS,
        )
        write(
            draw,
            (x + w / 2, chip_top + chip_h / 2),
            label,
            chip_font,
            ON_BRAND_FILL + (255,),
            tracking=0.1,
            anchor="mm",
        )
        x += w + chip_gap

    write(
        draw,
        (mid, px(574)),
        "lingodesk.yunweneric.com",
        urbanist(19, "SemiBold"),
        alpha(WHITE, 0.50),
        tracking=0.2,
        anchor="ms",
    )

    return canvas.convert("RGB").resize((WIDTH, HEIGHT), Image.LANCZOS)


def main() -> None:
    ensure_font()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    build().save(OUT, optimize=True)
    print(f"  {OUT}  {WIDTH}x{HEIGHT}")


if __name__ == "__main__":
    main()
