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

        if config.get("crop_square"):
            prepared = crop_logo(prepared)

        output.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(output, format="PNG", optimize=True)
        verify(output)

    print("All Mumin Pro brand and shortcut images are ready.")

if __name__ == "__main__":
    main()
