#!/usr/bin/env python3
"""Prepare clean transparent Mumin Pro logo and home shortcut artwork.

The uploaded source files are intentionally preserved. This script removes
edge-connected background regions using each source's known background color.
The Qibla asset receives a narrowly scoped near-white cleanup only where
fragments connect to the bottom edge within the final 3.5% of the image. Isolated
white artwork and highlights are preserved. The generated RGBA output is
inspected and reported without changing the artwork during that inspection.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUTS = {
    "assets/branding/mumin_pro_logo.png": {
        "output": "assets/branding/processed/mumin_pro_logo.png",
        "backgrounds": [((255, 0, 255), 105)],
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
    """Remove only near-white fragments connected to the bottom image edge.

    The cleanup is limited to the final 3.5% of the image and starts only from
    near-white pixels on the bottom row. Only orthogonal (4-connected)
    pixels are removed; diagonal-only contact does not erase artwork.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    first_row = max(0, int(height * 0.965))
    visited = bytearray(width * (height - first_row))
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

    for x in range(width):
        add_seed(x, height - 1)

    cursor = 0
    removed = 0
    while cursor < len(queue):
        x, y = queue[cursor]
        cursor += 1
        red, green, blue, _ = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        removed += 1

        # Use 4-connected neighbors only. Diagonal contact is not enough
        # to classify a white pixel as residue: this protects nearby white
        # details and edges of the Qibla artwork from being erased.
        for next_x, next_y in (
            (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)
        ):
            if not (0 <= next_x < width and first_row <= next_y < height):
                continue
            index = (next_y - first_row) * width + next_x
            if visited[index]:
                continue
            visited[index] = 1
            if is_target(next_x, next_y):
                queue.append((next_x, next_y))

    retained_lower_white = sum(
        1
        for y in range(first_row, height)
        for x in range(width)
        if is_target(x, y)
    )
    print(
        "QIBLA lower-edge cleanup: "
        f"removed {removed} bottom-connected near-white pixels; "
        f"preserved {retained_lower_white} isolated near-white pixels "
        f"in rows {first_row}-{height - 1}"
    )
    return image

def inspect_qibla_output(path: Path):
    """Report source-edge and lower-fringe evidence without altering artwork."""
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
        width, height = image.size
        pixels = image.load()
        alpha = image.getchannel("A")
        alpha_bbox = alpha.getbbox()
        edge_opaque = 0
        for x in range(width):
            edge_opaque += int(pixels[x, 0][3] > 0)
            edge_opaque += int(pixels[x, height - 1][3] > 0)
        for y in range(1, height - 1):
            edge_opaque += int(pixels[0, y][3] > 0)
            edge_opaque += int(pixels[width - 1, y][3] > 0)

        first_lower_row = max(0, int(height * 0.965))
        lower_near_white = sum(
            1
            for y in range(first_lower_row, height)
            for x in range(width)
            if pixels[x, y][3] > 0
            and min(pixels[x, y][:3]) >= 220
            and max(pixels[x, y][:3]) - min(pixels[x, y][:3]) <= 28
        )
        print(
            "QIBLA_OUTPUT_INSPECTION: "
            f"size={width}x{height}, alpha_bbox={alpha_bbox}, "
            f"nontransparent_outer_edge_pixels={edge_opaque}, "
            f"visible_near_white_bottom_band_pixels={lower_near_white}, "
            f"corner_alpha={[pixels[0, 0][3], pixels[width - 1, 0][3], pixels[0, height - 1][3], pixels[width - 1, height - 1][3]]}"
        )

def remove_logo_black_outline(image: Image.Image):
    """Remove only the near-black outline touching the transparent logo edge.

    The source export has a thin black stroke around the rounded-square tile.
    Removing the magenta first exposes that stroke, so seed from every dark
    pixel directly adjacent to transparency and flood only through near-black
    pixels. Dark emerald/blue artwork and enclosed details are preserved.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    visited = bytearray(width * height)
    queue = []

    def is_outline(x: int, y: int) -> bool:
        red, green, blue, alpha = pixels[x, y]
        return alpha > 0 and max(red, green, blue) <= 72

    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] != 0:
                continue
            for nx, ny in (
                (x - 1, y - 1), (x, y - 1), (x + 1, y - 1),
                (x - 1, y),                 (x + 1, y),
                (x - 1, y + 1), (x, y + 1), (x + 1, y + 1),
            ):
                if not (0 <= nx < width and 0 <= ny < height):
                    continue
                index = ny * width + nx
                if not visited[index] and is_outline(nx, ny):
                    visited[index] = 1
                    queue.append((nx, ny))

    cursor = 0
    removed = 0
    while cursor < len(queue):
        x, y = queue[cursor]
        cursor += 1
        red, green, blue, _ = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        removed += 1

        for nx, ny in (
            (x - 1, y - 1), (x, y - 1), (x + 1, y - 1),
            (x - 1, y),                 (x + 1, y),
            (x - 1, y + 1), (x, y + 1), (x + 1, y + 1),
        ):
            if not (0 <= nx < width and 0 <= ny < height):
                continue
            index = ny * width + nx
            if visited[index]:
                continue
            visited[index] = 1
            if is_outline(nx, ny):
                queue.append((nx, ny))

    if removed == 0:
        raise RuntimeError(
            "The Mumin Pro source outline was not detected; refusing to "
            "publish an icon that may retain the black perimeter."
        )

    print(
        "MUMIN_LOGO_OUTLINE_CLEANUP: "
        f"removed {removed} transparent-edge-connected near-black pixels"
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
    # The logo artwork already contains its own rounded-square emerald/blue
    # tile. Keep it visually prominent in the adaptive foreground: 12% padding
    # avoids the edge clipping seen with the old 5.5% setting without shrinking
    # the mark into the center as the 40% experiment did.
    padding = max(12, round(side * 0.12))
    canvas_side = side + padding * 2
    canvas = Image.new("RGBA", (canvas_side, canvas_side), (0, 0, 0, 0))
    canvas.alpha_composite(
        mark,
        ((canvas_side - width) // 2, (canvas_side - height) // 2),
    )
    # Resize in premultiplied-alpha space. Resampling straight RGBA can
    # blend transparent black RGB values into the visible edge and recreate
    # the exact dark halo this pipeline is designed to remove.
    premultiplied = canvas.convert("RGBa")
    resized = premultiplied.resize(
        (1024, 1024),
        Image.Resampling.LANCZOS,
    )
    return resized.convert("RGBA")

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
        if path.name == "mumin_pro_logo.png":
            bbox = alpha.getbbox()
            if bbox is None:
                raise RuntimeError("The prepared Mumin Pro logo is empty.")
            content_width = bbox[2] - bbox[0]
            content_height = bbox[3] - bbox[1]
            width_fraction = content_width / rgba.width
            height_fraction = content_height / rgba.height
            safe_zone_limit = 0.83
            if max(width_fraction, height_fraction) > safe_zone_limit:
                raise RuntimeError(
                    "Mumin Pro logo exceeds the adaptive-icon safe zone: "
                    f"{width_fraction:.1%} x {height_fraction:.1%}; "
                    f"maximum is {safe_zone_limit:.0%}."
                )
            boundary_dark_pixels = 0
            pixels = rgba.load()
            for y in range(bbox[1], bbox[3]):
                for x in range(bbox[0], bbox[2]):
                    if pixels[x, y][3] == 0:
                        continue
                    red, green, blue, _ = pixels[x, y]
                    if max(red, green, blue) > 72:
                        continue
                    if any(
                        not (0 <= nx < rgba.width and 0 <= ny < rgba.height)
                        or pixels[nx, ny][3] == 0
                        for nx, ny in (
                            (x - 1, y), (x + 1, y),
                            (x, y - 1), (x, y + 1),
                        )
                    ):
                        boundary_dark_pixels += 1
            if boundary_dark_pixels:
                raise RuntimeError(
                    "Mumin Pro still has a near-black outline touching its "
                    f"transparent edge ({boundary_dark_pixels} pixels)."
                )
            print(
                "MUMIN_LOGO_EDGE_CHECK: no near-black perimeter remains"
            )
            print(
                "ADAPTIVE_ICON_SAFE_ZONE: "
                f"artwork={width_fraction:.1%}x{height_fraction:.1%}, "
                "within 83% visual-scale limit; final Samsung mask is checked on-device"
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
            if source_relative == "assets/images/home/reference_ui/icon_qibla.png":
                print(
                    "QIBLA_SOURCE_INSPECTION: "
                    f"format={original.format}, size={original.size}, mode={original.mode}"
                )
            prepared = remove_edge_background(
                original,
                config["backgrounds"],
            )

        if source_relative == "assets/branding/mumin_pro_logo.png":
            prepared = remove_logo_black_outline(prepared)

        if source_relative == "assets/images/home/reference_ui/icon_qibla.png":
            prepared = remove_qibla_bottom_white_residue(prepared)

        if config.get("crop_square"):
            prepared = crop_logo(prepared)
            # Lanczos resampling can create a fresh dark fringe at the final
            # transparent boundary even after the source outline was removed.
            # Run the edge-connected cleanup once more on the exact 1024px
            # deliverable, then let verify() reject any remaining dark halo.
            if source_relative == "assets/branding/mumin_pro_logo.png":
                prepared = remove_logo_black_outline(prepared)

        output.parent.mkdir(parents=True, exist_ok=True)
        prepared.save(output, format="PNG", optimize=True)
        verify(output)
        if source_relative == "assets/images/home/reference_ui/icon_qibla.png":
            inspect_qibla_output(output)

    print("All Mumin Pro brand and shortcut images are ready.")

if __name__ == "__main__":
    main()
