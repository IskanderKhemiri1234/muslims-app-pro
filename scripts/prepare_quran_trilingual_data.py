#!/usr/bin/env python3
"""Build the complete, verified, offline Arabic/English/French Quran dataset.

Arabic is taken only from the QuranEnc/KFGQPC Hafs v20 CSV. English and French
translation strings and footnotes are preserved verbatim from QuranEnc. The
result is generated during CI and embedded as Flutter assets in the APK.
"""

from __future__ import annotations

import concurrent.futures
import csv
import hashlib
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "https://quranenc.com/api/v1/translation/sura"
ROOT = Path("assets/quran_trilingual/data")
CSV_PATH = ROOT / "Quran_text.csv"
OUTPUT_DIR = ROOT / "surahs"
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

ENGLISH_KEY = "english_saheeh"
ENGLISH_VERSION = "1.1.2"
ENGLISH_PUBLISHER = "Saheeh International / Noor International Center"
ENGLISH_INFO = (
    "Translation of the meanings of the Noble Quran; Language: English; "
    "Translation ID: english_saheeh; Publisher: Saheeh International / "
    "Noor International Center; Source: QuranEnc.com; Version: 1.1.2."
)
FRENCH_KEY = "french_rashid"
FRENCH_VERSION = "1.0.3"
FRENCH_PUBLISHER = "Rachid Maach / Rowwad Translation Center"
FRENCH_INFO = (
    "Traduction du sens des versets du Noble Coran; Language: French; "
    "Translation ID: french_rashid; Translator: Rachid Maach; Publisher: "
    "Rowwad Translation Center; Source: QuranEnc.com; Version: 1.0.3."
)
ARABIC_SOURCE = (
    "QuranEnc.com / King Fahd Complex / Uthmanic Hafs v20"
)
EXPECTED_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111,
    43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64,
    77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83,
    182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
    18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28,
    20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25,
    22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19,
    5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
]
EXPECTED_TOTAL = 6236


def verify_pinned_translation_versions() -> None:
    expected = {
        ENGLISH_KEY: ENGLISH_VERSION,
        FRENCH_KEY: FRENCH_VERSION,
    }
    for language in ("en", "fr"):
        url = (
            f"https://quranenc.com/api/v1/translations/list/{language}/"
            f"?localization={language}"
        )
        request = urllib.request.Request(
            url,
            headers={
                "Accept": "application/json",
                "User-Agent": "Mumin-Pro-Offline-Quran-Builder/1.0",
            },
        )
        with urllib.request.urlopen(request, timeout=45) as response:
            payload = json.loads(response.read().decode("utf-8"))
        entries = payload.get("translations") if isinstance(payload, dict) else None
        if not isinstance(entries, list):
            raise RuntimeError(
                f"QuranEnc {language} translation catalogue is malformed."
            )
        for key, pinned_version in expected.items():
            if (key.startswith("english_") and language != "en") or (
                key.startswith("french_") and language != "fr"
            ):
                continue
            matches = [
                item for item in entries
                if isinstance(item, dict) and item.get("key") == key
            ]
            if len(matches) != 1:
                raise RuntimeError(
                    f"Pinned QuranEnc translation {key} is unavailable."
                )
            current_version = str(matches[0].get("version", ""))
            if current_version != pinned_version:
                raise RuntimeError(
                    f"QuranEnc {key} version changed from {pinned_version} "
                    f"to {current_version}; review source/version before packaging."
                )


def load_canonical_arabic() -> dict[tuple[int, int], str]:
    if not CSV_PATH.is_file():
        raise SystemExit(f"Missing official Hafs v20 text file: {CSV_PATH}")
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"id", "sura", "aya", "uthmani"}
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise SystemExit("Official Quran CSV has an unexpected header.")
        result: dict[tuple[int, int], str] = {}
        for row in reader:
            try:
                key = (int(row["sura"]), int(row["aya"]))
            except (TypeError, ValueError) as error:
                raise SystemExit("Invalid surah/ayah number in official CSV.") from error
            text = row["uthmani"]
            if key in result or not text:
                raise SystemExit(f"Duplicate or empty official Arabic verse: {key}")
            result[key] = text

    if len(result) != EXPECTED_TOTAL:
        raise SystemExit(
            f"Official Arabic CSV has {len(result)} rows; expected {EXPECTED_TOTAL}."
        )
    for surah, count in enumerate(EXPECTED_COUNTS, start=1):
        for ayah in range(1, count + 1):
            if (surah, ayah) not in result:
                raise SystemExit(f"Official Arabic CSV is missing {surah}:{ayah}.")
    return result


def fetch_surah(key: str, surah: int) -> list[dict[str, object]]:
    url = f"{BASE_URL}/{key}/{surah}"
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "Mumin-Pro-Offline-Quran-Builder/1.0",
        },
    )
    last_error: Exception | None = None
    for attempt in range(1, 5):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                if response.status != 200:
                    raise RuntimeError(f"HTTP {response.status} for {key}/{surah}")
                payload = json.loads(response.read().decode("utf-8"))
            rows = payload.get("result") if isinstance(payload, dict) else None
            if not isinstance(rows, list):
                raise ValueError(f"Malformed QuranEnc response for {key}/{surah}")
            return rows
        except (urllib.error.URLError, TimeoutError, OSError, ValueError, RuntimeError) as error:
            last_error = error
            if attempt < 4:
                time.sleep(attempt * 1.5)
    raise RuntimeError(f"Could not fetch {key}/{surah}: {last_error}")


def build_surah(
    surah: int,
    canonical: dict[tuple[int, int], str],
) -> tuple[int, dict[str, object]]:
    english_rows = fetch_surah(ENGLISH_KEY, surah)
    french_rows = fetch_surah(FRENCH_KEY, surah)
    expected = EXPECTED_COUNTS[surah - 1]
    if len(english_rows) != expected or len(french_rows) != expected:
        raise ValueError(
            f"Translation count mismatch for surah {surah}: "
            f"English={len(english_rows)}, French={len(french_rows)}, expected={expected}"
        )

    verses: list[dict[str, object]] = []
    for index, (english, french) in enumerate(zip(english_rows, french_rows), start=1):
        canonical_text = canonical[(surah, index)]
        for language, row in (("English", english), ("French", french)):
            if not isinstance(row, dict):
                raise ValueError(f"{language} row is malformed at {surah}:{index}")
            if str(row.get("sura")) != str(surah) or str(row.get("aya")) != str(index):
                raise ValueError(f"{language} verse numbering mismatch at {surah}:{index}")
            if row.get("arabic_text") != canonical_text:
                raise ValueError(
                    f"{language} Arabic source mismatch at {surah}:{index}; "
                    "refusing to package unverified text."
                )
            translation = row.get("translation")
            footnotes = row.get("footnotes", "")
            if not isinstance(translation, str) or not translation.strip():
                raise ValueError(f"Missing {language} translation at {surah}:{index}")
            if not isinstance(footnotes, str):
                raise ValueError(f"Invalid {language} footnotes at {surah}:{index}")

        verses.append({
            "surah": surah,
            "ayah": index,
            "arabic": canonical_text,
            "english": english["translation"],
            "french": french["translation"],
            "englishFootnotes": english.get("footnotes", ""),
            "frenchFootnotes": french.get("footnotes", ""),
        })

    return surah, {
        "number": surah,
        "englishVersion": ENGLISH_VERSION,
        "frenchVersion": FRENCH_VERSION,
        "arabicSource": ARABIC_SOURCE,
        "englishPublisher": ENGLISH_PUBLISHER,
        "frenchPublisher": FRENCH_PUBLISHER,
        "englishTranslationInfo": ENGLISH_INFO,
        "frenchTranslationInfo": FRENCH_INFO,
        "verses": verses,
    }


def main() -> None:
    if len(EXPECTED_COUNTS) != 114 or sum(EXPECTED_COUNTS) != EXPECTED_TOTAL:
        raise SystemExit("Internal Quran surah-count contract is invalid.")
    verify_pinned_translation_versions()
    canonical = load_canonical_arabic()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    built: dict[int, dict[str, object]] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
        futures = {
            executor.submit(build_surah, surah, canonical): surah
            for surah in range(1, 115)
        }
        for future in concurrent.futures.as_completed(futures):
            surah, payload = future.result()
            built[surah] = payload
            print(f"Verified surah {surah}/114 ({EXPECTED_COUNTS[surah - 1]} ayahs)")

    if len(built) != 114 or sum(len(item["verses"]) for item in built.values()) != EXPECTED_TOTAL:
        raise SystemExit("The generated three-language Quran is incomplete.")

    manifest_files: dict[str, str] = {}
    for surah in range(1, 115):
        filename = f"surah_{surah:03d}.json"
        encoded = json.dumps(
            built[surah],
            ensure_ascii=False,
            separators=(",", ":"),
        ).encode("utf-8")
        temporary = OUTPUT_DIR / f"{filename}.tmp"
        temporary.write_bytes(encoded)
        temporary.replace(OUTPUT_DIR / filename)
        manifest_files[filename] = hashlib.sha256(encoded).hexdigest()

    manifest = {
        "schemaVersion": 1,
        "arabicSource": ARABIC_SOURCE,
        "englishTranslation": {
            "key": ENGLISH_KEY,
            "version": ENGLISH_VERSION,
            "publisher": ENGLISH_PUBLISHER,
            "source": "QuranEnc.com",
        },
        "frenchTranslation": {
            "key": FRENCH_KEY,
            "version": FRENCH_VERSION,
            "publisher": FRENCH_PUBLISHER,
            "source": "QuranEnc.com",
        },
        "surahCount": 114,
        "ayahCount": EXPECTED_TOTAL,
        "surahAyahCounts": EXPECTED_COUNTS,
        "filesSha256": manifest_files,
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "OFFLINE QURAN VERIFIED: 114 surahs, 6,236 ayahs, "
        "Arabic + English + French. All Arabic strings match the official Hafs v20 CSV."
    )


if __name__ == "__main__":
    main()
