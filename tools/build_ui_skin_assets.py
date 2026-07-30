from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ASSET_SPECS = {
    "panel_main": ("panel_main.png", (768, 920)),
    # Compact surfaces deliberately use shallower runtime canvases. Their
    # generated masters have broad ornamental borders intended for large art;
    # keeping that height would leave no readable content area in 32-180px UI.
    "panel_hud": ("panel_hud.png", (768, 176)),
    "panel_inset": ("panel_inset.png", (1024, 160)),
    "button_primary": ("button_primary_normal.png", (512, 72)),
    "button_secondary": ("button_secondary_normal.png", (512, 72)),
    "field": ("field_normal.png", (768, 72)),
}


def _is_connected_background(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return True
    # Image generation may bake a white checkerboard and its antialiased edge
    # into the output. Only flood through bright, nearly neutral pixels that
    # remain connected to the canvas boundary so metal highlights stay intact.
    return min(red, green, blue) >= 155 and max(red, green, blue) - min(red, green, blue) <= 24


def _remove_baked_checkerboard(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    background = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if background[index] or not _is_connected_background(pixels[x, y]):
            return
        background[index] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = rgba.getchannel("A")
    alpha_pixels = alpha.load()
    for y in range(height):
        row_offset = y * width
        for x in range(width):
            if background[row_offset + x]:
                alpha_pixels[x, y] = 0

    rgba.putalpha(alpha)
    _soften_light_edge_fringe(rgba)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("Background removal erased the complete image")

    padding = 4
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(width, bbox[2] + padding)
    bottom = min(height, bbox[3] + padding)
    return rgba.crop((left, top, right, bottom))


def _soften_light_edge_fringe(image: Image.Image) -> None:
    pixels = image.load()
    width, height = image.size
    for _pass_index in range(8):
        source_alpha = image.getchannel("A").tobytes()
        updates: list[tuple[int, int, int]] = []
        for y in range(1, height - 1):
            for x in range(1, width - 1):
                red, green, blue, alpha = pixels[x, y]
                if alpha == 0 or min(red, green, blue) < 168:
                    continue
                touches_transparency = False
                for offset_y in (-1, 0, 1):
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        if source_alpha[(y + offset_y) * width + x + offset_x] == 0:
                            touches_transparency = True
                            break
                    if touches_transparency:
                        break
                if not touches_transparency:
                    continue
                edge_alpha = int(alpha * max(0.0, min(1.0, (238.0 - min(red, green, blue)) / 70.0)))
                updates.append((x, y, edge_alpha))
        for x, y, edge_alpha in updates:
            red, green, blue, _alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, edge_alpha)


def _resize_to_canvas(image: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    # These textures are nine-patched at runtime. Filling the source canvas
    # keeps the slice coordinates stable and lets only the center band stretch.
    return image.resize(target_size, Image.Resampling.LANCZOS)


def _tint_visible_pixels(image: Image.Image, color: tuple[int, int, int], strength: float) -> Image.Image:
    tint = Image.new("RGBA", image.size, (*color, 255))
    mixed = Image.blend(image.convert("RGBA"), tint, strength)
    mixed.putalpha(image.getchannel("A"))
    return mixed


def _add_outer_glow(
    image: Image.Image,
    color: tuple[int, int, int],
    radius: float,
    opacity: int,
) -> Image.Image:
    alpha = image.getchannel("A")
    glow_alpha = alpha.filter(ImageFilter.GaussianBlur(radius))
    glow_alpha = glow_alpha.point(lambda value: value * opacity // 255)
    glow = Image.new("RGBA", image.size, (*color, 0))
    glow.putalpha(glow_alpha)
    return Image.alpha_composite(glow, image)


def _make_hover(image: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    brighter = ImageEnhance.Brightness(image).enhance(1.08)
    contrasted = ImageEnhance.Contrast(brighter).enhance(1.04)
    tinted = _tint_visible_pixels(contrasted, accent, 0.055)
    return _add_outer_glow(tinted, accent, 5.0, 92)


def _make_pressed(image: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    darkened = ImageEnhance.Brightness(image).enhance(0.78)
    muted = ImageEnhance.Contrast(darkened).enhance(0.96)
    return _tint_visible_pixels(muted, accent, 0.035)


def _make_disabled(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A").point(lambda value: int(value * 0.72))
    gray = ImageOps.grayscale(image).convert("RGBA")
    gray = ImageEnhance.Brightness(gray).enhance(0.58)
    gray.putalpha(alpha)
    return gray


def _make_field_focus(image: Image.Image) -> Image.Image:
    tinted = _tint_visible_pixels(ImageEnhance.Brightness(image).enhance(1.05), (72, 148, 210), 0.07)
    return _add_outer_glow(tinted, (76, 160, 226), 4.0, 82)


def _make_vertical_tab(image: Image.Image) -> Image.Image:
    rotated = image.rotate(90, expand=True)
    return rotated.resize((72, 192), Image.Resampling.LANCZOS)


def _save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def build_assets(source_dir: Path, output_dir: Path, sources: dict[str, str]) -> None:
    built: dict[str, Image.Image] = {}
    for asset_id, (output_name, target_size) in ASSET_SPECS.items():
        source_path = source_dir / sources[asset_id]
        if not source_path.is_file():
            raise FileNotFoundError(source_path)
        cleaned = _remove_baked_checkerboard(Image.open(source_path))
        built[asset_id] = _resize_to_canvas(cleaned, target_size)
        _save(built[asset_id], output_dir / output_name)

    primary_states = {
        "normal": built["button_primary"],
        "hover": _make_hover(built["button_primary"], (238, 174, 70)),
        "pressed": _make_pressed(built["button_primary"], (142, 78, 34)),
        "disabled": _make_disabled(built["button_primary"]),
    }
    for state_name, state_image in primary_states.items():
        if state_name != "normal":
            _save(state_image, output_dir / f"button_primary_{state_name}.png")
        _save(_make_vertical_tab(state_image), output_dir / f"button_tab_{state_name}.png")

    secondary = built["button_secondary"]
    _save(_make_hover(secondary, (70, 144, 208)), output_dir / "button_secondary_hover.png")
    _save(_make_pressed(secondary, (32, 68, 104)), output_dir / "button_secondary_pressed.png")
    _save(_make_disabled(secondary), output_dir / "button_secondary_disabled.png")

    _save(_make_field_focus(built["field"]), output_dir / "field_focus.png")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build scalable War Card UI skin textures.")
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--panel-main", required=True)
    parser.add_argument("--panel-hud", required=True)
    parser.add_argument("--panel-inset", required=True)
    parser.add_argument("--button-primary", required=True)
    parser.add_argument("--button-secondary", required=True)
    parser.add_argument("--field", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    sources = {
        "panel_main": args.panel_main,
        "panel_hud": args.panel_hud,
        "panel_inset": args.panel_inset,
        "button_primary": args.button_primary,
        "button_secondary": args.button_secondary,
        "field": args.field,
    }
    build_assets(args.source_dir, args.output_dir, sources)


if __name__ == "__main__":
    main()
