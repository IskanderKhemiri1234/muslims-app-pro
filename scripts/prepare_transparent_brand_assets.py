#!/usr/bin/env python3
"""Prepare clean transparent Mumin Pro logo and home shortcut artwork.

The uploaded source files are intentionally preserved. This script removes only
background regions connected to image edges, using the known background color
for each source image, then writes real RGBA PNG assets for Flutter and Android.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = {
    "assets/branding/mumin_pro_logo.png": {
        "output": "assets/branding/processed/mumin_pro_logo.png",
        "backgrounds": [((255, 0, 255), 105)],
        # The uploaded export also contains a black outer frame around the
        # colored app mark. Remove only black pixels connected to the newly
        # exposed outer edge; enclosed dark artwork remains untouched.
        "post_backgrounds": [((0, 0, 0), 52)],
        "crop_square": True,
    },
    "assets/images/home/reference_ui/icon_qibla.png": {
        "output": "assets/images/home/reference_ui/processed/icon_qibla.png",
        "backgrounds": [((255, 255, 255), 65)],
    },
    "assets/images/home/reference_ui/icon_quran.png": {
        "output": "assets/images/home/reference_ui/processed/icon_quran.png",
        "backgrounds": [((255, 255, 255), 65)],
        "seeds": "all",
    },
    "assets/images/home/reference_ui/icon_kaaba.png": {
        "output": "assets/images/home/reference_ui/processed/icon_kaaba.png",
        "backgrounds": [((0, 0, 0), 48)],
        "seeds": "all",
    },
    "assets/images/home/reference_ui/icon_azkar.png": {
        "output": "assets/images/home/reference_ui/processed/icon_azkar.png",
        "backgrounds": [((255, 255, 255), 65)],
        "seeds": "all",
    },
    "assets/images/home/reference_ui/icon_tasbih.png": {
        "output": "assets/images/home/reference_ui/processed/icon_tasbih.png",
        "backgrounds": [
            ((255, 255, 255), 65),
            ((0, 0, 0), 35),
        ],
        "seeds": "all",
    },
}

def border_seeds(width: int, height: int):
    return [
        (0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1),
        (width // 2, 0), (width // 2, height - 1),
        (0, height // 2), (width - 1, height // 2),
    ]

def color_distance(pixel, color):
    return max(abs(pixel[i] - color[i]) for i in range(3))

def remove_edge_background(image: Image.Image, backgrounds):
    image = image.convert("RGBA")
    seeds = border_seeds(*image.size)

    for background, threshold in backgrounds:
        for seed in seeds:
            pixel = image.getpixel(seed)
            if pixel[3] == 0 or color_distance(pixel, background) > threshold:
                continue
            ImageDraw.floodfill(
                image,
                seed,
                (0, 0, 0, 0),
                thresh=threshold,
            )

    return image

def remove_qibla_bottom_white_residue(image: Image.Image):
    """Remove near-white background components touching the lower image edges.

    The cleanup follows connected near-white pixels through the lower 18% of
    the source and along both side edges. It removes the lower white fringe
    even when the fringe does not reach the exact bottom row, while leaving
    disconnected white highlights inside the compass artwork untouched.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    first_row = max(0, int(height * 0.82))
    band_height = height - first_row
    visited = bytearray(width * band_height)
    queue = []

    def is_target(x: int, y: int) -> bool:
        red, green, blue, alpha = pixels[x, y]
        return (
            alpha > 0
            and min(red, green, blue) >= 220
            and max(red, green, blue) - min(red, green, blue) <= 28
        )

    def add_seed(x: int, y: int) -> None:
        index = (y - first_row) * width + x
        if not visited[index] and is_target(x, y):
            visited[index] = 1
            queue.append((x, y))

    # Seed the complete bottom edge and the lower portions of both side edges.
    for x in range(width):
        add_seed(x, height - 1)
    for y in range(first_row, height):
        add_seed(0, y)
        add_seed(width - 1, y)

    cursor = 0
    removed = 0
    while cursor < len(queue):
        x, y = queue[cursor]
        cursor += 1
        red, green, blue, _ = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        removed += 1

        for next_y in range(max(first_row, y - 1), min(height - 1, y + 1) + 1):
            for next_x in range(max(0, x - 1), min(width - 1, x + 1) + 1):
                index = (next_y - first_row) * width + next_x
                if visited[index]:
                    continue
                visited[index] = 1
                if is_target(next_x, next_y):
                    queue.append((next_x, next_y))

    remaining_edge_pixels = sum(
        1 for x in range(width) if is_target(x, height - 1)
    ) + sum(
        1 for y in range(first_row, height)
        if is_target(0, y) or is_target(width - 1, y)
    )
    if remaining_edge_pixels:
        raise RuntimeError(
            f"Qibla icon still has {remaining_edge_pixels} near-white lower-edge pixels."
        )

    if removed == 0:
        print("QIBLA lower-edge cleanup: no connected near-white residue found")
    else:
        print(
            "QIBLA lower-edge cleanup verified: "
            f"removed {removed} connected near-white pixels in rows "
            f"{first_row}-{height - 1}"
        )
    return image

def crop_logo(image: Image.Image):
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError("Logo background removal erased the complete image.")

    mark = image.crop(bbox)
    width, height = mark.size
    side = max(width, height)
    padding = max(12, round(side * 0.055))
    canvas_side = side + padding * 2
    canvas = Image.new("RGBA", (canvas_side, canvas_side), (0, 0, 0, 0))
    canvas.alpha_composite(
        mark,
        ((canvas_side - width) // 2, (canvas_side - height) // 2),
    )
    return canvas.resize((1024, 1024), Image.Resampling.LANCZOS)

def verify(path: Path):
    with Image.open(path) as image:
        if image.format != "PNG":
            raise RuntimeError(f"{path} is not encoded as PNG.")
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        minimum, _ = alpha.getextrema()
        transparent = sum(1 for value in alpha.getdata() if value == 0)
        total = rgba.width * rgba.height
        if minimum != 0 or transparent < max(100, total // 200):
            raise RuntimeError(
                f"{path} has no meaningful transparent background "
                f"(transparent pixels: {transparent}/{total})."
            )
        print(
            f"VERIFIED {path}: {rgba.width}x{rgba.height}, "
            f"RGBA alpha, {transparent}/{total} fully transparent pixels"
        )

def main():
    for source_relative, config in OUTPUTS.items():
        source = ROOT / source_relative
        output = ROOT / config["output"]
        if not source.is_file():
            raise FileNotFoundError(f"Required source artwork is missing: {source}")

        with Image.open(source) as original:
            prepared = remove_edge_background(
                original,
                config["backgrounds"],
            )

        for background, threshold in config.get("post_backgrounds", []):
            prepared = remove_edge_background(
                prepared,
                [(background, threshold)],
            )

        if source_relative == "assets/images/home/reference_ui/icon_qibla.png":
            prepared = remove_qibla_bottom_white_residue(prepared)

        if config.get("crop_square"):
            prepared = crop_logo(prepared)

        output.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(output, format="PNG", optimize=True)
        verify(output)

    print("All Mumin Pro brand and shortcut images are ready.")

if __name__ == "__main__":
    main()
