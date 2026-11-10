#!/usr/bin/env python3
"""Prepare the official Hafs v20 font that matches QuranEnc Uthmanic text."""

from __future__ import annotations

import hashlib
import io
import urllib.request
import zipfile
from pathlib import Path

SOURCE_URL = "https://quranenc.com/downloads/assets/Hafs_20.zip"
OUTPUT = Path("assets/quran_trilingual/fonts/Hafs_20.ttf")
TEXT_OUTPUT = Path("assets/quran_trilingual/data/Quran_text.csv")


def main() -> None:
    request = urllib.request.Request(
        SOURCE_URL,
        headers={"User-Agent": "MuminPro-Quran-Asset-Builder/1.0"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        archive_bytes = response.read()

    if len(archive_bytes) < 100_000:
        raise SystemExit("The official QuranEnc Hafs archive is unexpectedly small.")

    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        files = {Path(name).name: name for name in archive.namelist()}
        font_name = files.get("Hafs_20.ttf")
        text_name = files.get("Quran_text.csv")
        if font_name is None or text_name is None:
            raise SystemExit(
                "The official archive must contain Hafs_20.ttf and Quran_text.csv."
            )

        font_bytes = archive.read(font_name)
        quran_csv = archive.read(text_name).decode("utf-8-sig")
        if len(font_bytes) < 100_000:
            raise SystemExit("The official Hafs font file failed its size check.")
        if len(quran_csv.splitlines()) < 6236:
            raise SystemExit("The matching Uthmanic Quran text is incomplete.")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    TEXT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(font_bytes)
    TEXT_OUTPUT.write_bytes(quran_csv.encode("utf-8"))
    digest = hashlib.sha256(font_bytes).hexdigest()
    print(f"Prepared official Hafs v20 font: {OUTPUT}")
    print(f"Font SHA-256: {digest}")
    print(f"Prepared matching Uthmanic Quran text: {TEXT_OUTPUT}")
    print("Verified matching QuranEnc Uthmanic text dataset: 6,236 rows or more.")


if __name__ == "__main__":
    main()
