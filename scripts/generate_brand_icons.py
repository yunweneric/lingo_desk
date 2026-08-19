#!/usr/bin/env python3
"""Render the LingoDesk brand mark into per-platform icon and splash masters.

Geometry mirrors assets/brand/lingodesk_mark.svg — the same source the design
system's components/core/Mark.jsx renders and that LingoDeskMark paints in
app — so every platform icon is the same drawing at a different crop.

Mark geometry lives on a 64x64 grid: a teal rounded square holding two
overlapping locale tiles, the front tile carrying two dots. The tile group
alone spans x 16..50, y 20..46, so its centre is (33, 33) and it measures
34 x 26 units. Everything below is derived from those five numbers.

Requires rsvg-convert (brew install librsvg). Run from the repo root:
    python3 scripts/generate_brand_icons.py
"""

import pathlib
import shutil
import subprocess
import sys

TEAL = "#0f766e"
WHITE = "#ffffff"

# Tile group on the 64-unit mark grid.
GROUP_CX = GROUP_CY = 33.0
GROUP_W = 34.0
GROUP_H = 26.0
GROUP_DIAG = (GROUP_W**2 + GROUP_H**2) ** 0.5  # 42.8 units

# Share of the teal body the tile group occupies, matching the mark's
# proportions once the body's own padding is accounted for.
TILE_FRACTION = 0.598

OUT = pathlib.Path("assets/brand/icons")
SVG_OUT = OUT / "svg"

# The reference artwork the whole design system is drawn from.
SOURCE_MARK = pathlib.Path("assets/brand/lingodesk_mark.svg")


def _n(value):
    return f"{value:.2f}".rstrip("0").rstrip(".")


def tiles(scale, cx, cy, reversed_=False, mono=False):
    """The two locale tiles plus dots, centred on (cx, cy) at `scale` px/unit."""
    ox, oy = cx - GROUP_CX * scale, cy - GROUP_CY * scale
    x = lambda v: _n(ox + v * scale)
    y = lambda v: _n(oy + v * scale)
    length = lambda v: _n(v * scale)

    back = f'x="{x(16)}" y="{y(20)}" width="{length(24)}" height="{length(24)}" rx="{length(7)}"'
    front = f'x="{x(26)}" y="{y(22)}" width="{length(24)}" height="{length(24)}" rx="{length(7)}"'
    dot_l = f'cx="{x(34)}" cy="{y(34)}" r="{length(3.4)}"'
    dot_r = f'cx="{x(44)}" cy="{y(34)}" r="{length(3.4)}"'

    if mono:
        # Android themed icons read the alpha channel only: paint the tiles
        # into a luminance mask and punch the dots back out as holes.
        return (
            f'  <mask id="mono">\n'
            f'    <rect {back} fill="{WHITE}" fill-opacity="0.45"/>\n'
            f'    <rect {front} fill="{WHITE}"/>\n'
            f'    <circle {dot_l} fill="#000000"/>\n'
            f'    <circle {dot_r} fill="#000000"/>\n'
            f"  </mask>\n"
            f'  <rect width="100%" height="100%" fill="#000000" mask="url(#mono)"/>'
        )

    back_fill = (
        f'fill="{TEAL}" fill-opacity="0.4"'
        if reversed_
        else f'fill="{WHITE}" fill-opacity="0.45"'
    )
    front_fill = f'fill="{TEAL}"' if reversed_ else f'fill="{WHITE}"'
    dot_fill = f'fill="{WHITE}"' if reversed_ else f'fill="{TEAL}"'
    return (
        f"  <rect {back} {back_fill}/>\n"
        f"  <rect {front} {front_fill}/>\n"
        f"  <circle {dot_l} {dot_fill}/>\n"
        f"  <circle {dot_r} {dot_fill}/>"
    )


def build_svg(
    canvas,
    body=None,
    radius_ratio=0.25,
    tile_scale=None,
    reversed_=False,
    mono=False,
    shadow=False,
):
    """One icon master. `body` is the teal square's side; None draws tiles alone."""
    centre = canvas / 2
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{_n(canvas)}" '
        f'height="{_n(canvas)}" viewBox="0 0 {_n(canvas)} {_n(canvas)}">'
    ]

    if body is not None:
        if tile_scale is None:
            tile_scale = TILE_FRACTION * body / GROUP_W
        inset = (canvas - body) / 2
        radius = body * radius_ratio
        fill = WHITE if reversed_ else TEAL
        if shadow:
            parts.append(
                f'  <filter id="lift" x="-20%" y="-20%" width="140%" height="140%">\n'
                f'    <feDropShadow dx="0" dy="{_n(body * 0.012)}" '
                f'stdDeviation="{_n(body * 0.014)}" flood-color="#000000" flood-opacity="0.3"/>\n'
                f"  </filter>"
            )
        filter_attr = ' filter="url(#lift)"' if shadow else ""
        parts.append(
            f'  <rect x="{_n(inset)}" y="{_n(inset)}" width="{_n(body)}" '
            f'height="{_n(body)}" rx="{_n(radius)}" fill="{fill}"{filter_attr}/>'
        )
    elif tile_scale is None:
        raise ValueError("tile_scale is required when no body is drawn")

    parts.append(tiles(tile_scale, centre, centre, reversed_=reversed_, mono=mono))
    parts.append("</svg>\n")
    return "\n".join(parts)


# Every master the flutter_launcher_icons / flutter_native_splash configs
# in pubspec.yaml point at, plus the hicolor set Linux packaging installs.
VARIANTS = {
    # iOS masks the corners itself, so ship the teal edge to edge.
    "ios_app_icon": dict(canvas=1024, body=1024, radius_ratio=0),
    # Pre-API-26 launchers draw the bitmap as-is, so it carries its own shape.
    "android_legacy_icon": dict(canvas=1024, body=1024, radius_ratio=0.25),
    # Adaptive layers: tiles alone, sized to survive any launcher mask. The
    # 66dp-of-108dp safe circle means the group's diagonal must clear 61%.
    "android_adaptive_foreground": dict(
        canvas=1024, tile_scale=1024 * 0.61 / GROUP_DIAG
    ),
    "android_adaptive_monochrome": dict(
        canvas=1024, tile_scale=1024 * 0.61 / GROUP_DIAG, mono=True
    ),
    # macOS follows Apple's 1024 grid: an 824 body on a 100px margin.
    "macos_app_icon": dict(canvas=1024, body=824, radius_ratio=0.225, shadow=True),
    # Windows rounds far less than Apple and sits tighter in the canvas.
    "windows_app_icon": dict(canvas=1024, body=928, radius_ratio=0.18),
    "linux_app_icon": dict(canvas=1024, body=960, radius_ratio=0.22),
    # Splash art. Android 12+ masks the icon to a 768px circle on a 1152
    # canvas and supplies the teal itself as icon_background_color.
    "splash_logo": dict(canvas=768, body=768, radius_ratio=0.25),
    "splash_logo_dark": dict(canvas=768, body=768, radius_ratio=0.25, reversed_=True),
    "splash_android12": dict(canvas=1152, tile_scale=768 * 0.95 / GROUP_DIAG),
    # Web: the browser tab and the PWA install prompt. `web_app_icon` keeps
    # its own rounded shape, the way a favicon is drawn everywhere; the
    # maskable variant goes edge to edge in teal with the tiles pulled into
    # the same 61% safe circle Android's adaptive layers use, because an
    # installed PWA gets masked exactly like a launcher icon.
    "web_app_icon": dict(canvas=1024, body=1024, radius_ratio=0.22),
    "web_maskable_icon": dict(
        canvas=1024, body=1024, radius_ratio=0, tile_scale=1024 * 0.61 / GROUP_DIAG
    ),
}

# Sizes freedesktop expects under share/icons/hicolor/<size>x<size>/apps.
HICOLOR_SIZES = (16, 24, 32, 48, 64, 128, 256, 512)
LINUX_ICONS = pathlib.Path("linux/icons/hicolor")

# What web/index.html and web/manifest.json reference. Rendered here rather
# than by flutter_launcher_icons, whose web target rewrites manifest.json
# and would drop the description and theme colours set there by hand.
WEB = pathlib.Path("web")
WEB_ICONS = WEB / "icons"


def render(svg_path, png_path, size):
    png_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(svg_path), "-o", str(png_path)],
        check=True,
    )


def main():
    if shutil.which("rsvg-convert") is None:
        sys.exit("rsvg-convert not found — install it with: brew install librsvg")

    SVG_OUT.mkdir(parents=True, exist_ok=True)
    for name, spec in VARIANTS.items():
        canvas = spec["canvas"]
        svg_path = SVG_OUT / f"{name}.svg"
        svg_path.write_text(build_svg(**spec))
        render(svg_path, OUT / f"{name}.png", canvas)
        print(f"  {name}.png  {canvas}x{canvas}")

    linux_svg = SVG_OUT / "linux_app_icon.svg"
    for size in HICOLOR_SIZES:
        render(linux_svg, LINUX_ICONS / f"{size}x{size}/apps/lingo_desk.png", size)
    print(f"  linux/icons/hicolor/*/apps/lingo_desk.png  ({len(HICOLOR_SIZES)} sizes)")

    web_svg = SVG_OUT / "web_app_icon.svg"
    maskable_svg = SVG_OUT / "web_maskable_icon.svg"
    render(web_svg, WEB / "favicon.png", 48)
    for size in (192, 512):
        render(web_svg, WEB_ICONS / f"Icon-{size}.png", size)
        render(maskable_svg, WEB_ICONS / f"Icon-maskable-{size}.png", size)
    # iOS masks the home-screen icon itself, so reuse the full-bleed master.
    render(SVG_OUT / "ios_app_icon.svg", WEB_ICONS / "apple-touch-icon.png", 180)
    # An SVG favicon stays sharp at any density; the PNGs above are fallback.
    shutil.copyfile(SOURCE_MARK, WEB / "favicon.svg")
    print("  web/favicon.{svg,png} + web/icons/*.png")


if __name__ == "__main__":
    main()
