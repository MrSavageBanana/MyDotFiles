# created with Claude. Account: Milobowler

import csv
import time
import sys
import os
import subprocess
from ytmusicapi import YTMusic

# ──────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────
INPUT_CSV = (
    "/home/shayan/Downloads/Code/Spot2YT/new/Liked.csv"  # Path to your source CSV
)
OUTPUT_CSV = "/home/shayan/Downloads/Code/Spot2YT/new/output_with_links.csv"  # Where to save results
DOWNLOAD_DIR = "/home/shayan/Music/csv"  # Where to save audio files

# Set to False to skip downloading (CSV only mode)
DOWNLOAD_AUDIO = True

DURATION_TOLERANCE_SECONDS = 15  # ±15 s match window (set to None to ignore duration)
NOT_FOUND_PLACEHOLDER = "NOT FOUND"

# Column names in your CSV (adjust if yours differ)
COL_TRACK = "Track Name"
COL_ARTIST = "Artist Name(s)"
COL_DURATION = "Duration (ms)"  # Expected format: M:SS  or  H:MM:SS  or raw seconds


# ──────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────
def parse_duration_to_seconds(duration_str: str) -> int | None:
    """Convert 'M:SS', 'H:MM:SS', or plain seconds string → int seconds."""
    if not duration_str:
        return None
    duration_str = str(duration_str).strip()
    try:
        val = int(float(duration_str))
        # If value looks like milliseconds (>9999), convert
        return val // 1000 if val > 9999 else val
    except ValueError:
        pass
    parts = duration_str.split(":")
    try:
        parts = [int(p) for p in parts]
        if len(parts) == 2:  # M:SS
            return parts[0] * 60 + parts[1]
        elif len(parts) == 3:  # H:MM:SS
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
    except ValueError:
        pass
    return None


def duration_close(
    result_seconds: int, target_seconds: int | None, tol: int | None
) -> bool:
    """Return True if durations are within tolerance (or tolerance is disabled)."""
    if tol is None or target_seconds is None or result_seconds is None:
        return True
    return abs(result_seconds - target_seconds) <= tol


def build_yt_link(video_id: str) -> str:
    return f"https://music.youtube.com/watch?v={video_id}"


def search_song(ytm: YTMusic, track: str, artist: str, duration_s: int | None) -> str:
    """
    Search YouTube Music for the best matching song.
    Returns a YouTube Music URL or NOT_FOUND_PLACEHOLDER.
    """
    query = f"{track} {artist}"
    try:
        results = ytm.search(query, filter="songs", limit=10)
    except Exception as e:
        print(f"  [!] Search error for '{query}': {e}")
        return NOT_FOUND_PLACEHOLDER

    for item in results:
        # Duration in the API result (seconds)
        result_dur = item.get("duration_seconds")

        # Artist name matching (at least one artist overlaps)
        result_artists = " ".join(
            a.get("name", "").lower() for a in item.get("artists", [])
        )
        artist_match = any(
            a.strip().lower() in result_artists for a in artist.split(",")
        )

        title_match = track.lower() in item.get("title", "").lower()

        if (
            title_match
            and artist_match
            and duration_close(result_dur, duration_s, DURATION_TOLERANCE_SECONDS)
        ):
            video_id = item.get("videoId")
            if video_id:
                return build_yt_link(video_id)

    # Fallback: return best title-only match if strict match failed
    for item in results:
        result_dur = item.get("duration_seconds")
        title_match = track.lower() in item.get("title", "").lower()
        if title_match and duration_close(
            result_dur, duration_s, DURATION_TOLERANCE_SECONDS
        ):
            video_id = item.get("videoId")
            if video_id:
                print(f"  [~] Loose match (artist not verified) for: {track}")
                return build_yt_link(video_id)

    return NOT_FOUND_PLACEHOLDER


# ──────────────────────────────────────────────
# DOWNLOAD
# ──────────────────────────────────────────────
def download_track(url: str, output_dir: str, track: str, artist: str) -> bool:
    """
    Download a single track via yt-dlp at the best available quality.
    Uses opus/ogg natively (lossless from YT Music source) when available,
    falls back to best audio and converts to flac so nothing is re-encoded
    unless absolutely necessary.
    Embeds thumbnail + metadata automatically.
    Returns True on success.
    """
    os.makedirs(output_dir, exist_ok=True)

    # Output template: Artist - Track.ext  (sanitized by yt-dlp)
    out_template = os.path.join(output_dir, "%(artist)s - %(title)s.%(ext)s")

    cmd = [
        "yt-dlp",
        "--format",
        "bestaudio/best",  # always grab the best audio stream
        "--extract-audio",  # strip video container if present
        "--audio-format",
        "best",  # keep native codec (opus/ogg/m4a) — no re-encode
        "--audio-quality",
        "0",  # highest quality if any conversion is needed
        "--embed-thumbnail",  # cover art
        "--embed-metadata",  # title, artist, album tags
        "--parse-metadata",
        f":{artist}:%(artist)s",  # inject artist from our data
        "--no-playlist",  # safety: one track only
        "--output",
        out_template,
        "--no-warnings",
        "--quiet",
        "--progress",
        url,
    ]

    result = subprocess.run(cmd)
    return result.returncode == 0


# ──────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────
def main():
    if not os.path.exists(INPUT_CSV):
        print(f"[ERROR] Input file not found: {INPUT_CSV}")
        sys.exit(1)

    print("[*] Initialising YTMusic (no auth required for search)...")
    ytm = YTMusic()

    with open(INPUT_CSV, newline="", encoding="utf-8-sig") as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = reader.fieldnames or []
        rows = list(reader)

    output_fields = list(fieldnames) + ["YouTube Music Link"]

    found = 0
    not_found = 0
    download_ok = 0
    download_fail = 0

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f_out:
        writer = csv.DictWriter(f_out, fieldnames=output_fields)
        writer.writeheader()

        for i, row in enumerate(rows, start=1):
            track = row.get(COL_TRACK, "").strip()
            artist = row.get(COL_ARTIST, "").strip()
            duration = row.get(COL_DURATION, "").strip()
            dur_s = parse_duration_to_seconds(duration)

            print(f"[{i}/{len(rows)}] Searching: {track} — {artist} ({duration})")

            link = search_song(ytm, track, artist, dur_s)

            if link == NOT_FOUND_PLACEHOLDER:
                not_found += 1
                print(f"  [-] Not found")
            else:
                found += 1
                print(f"  [+] {link}")

                if DOWNLOAD_AUDIO:
                    print(f"  [↓] Downloading…")
                    ok = download_track(link, DOWNLOAD_DIR, track, artist)
                    if ok:
                        download_ok += 1
                        print(f"  [✔] Saved to {DOWNLOAD_DIR}")
                    else:
                        download_fail += 1
                        print(f"  [!] yt-dlp failed for: {link}")

            row["YouTube Music Link"] = link
            writer.writerow(row)

            time.sleep(0.4)  # polite delay to avoid rate-limiting

    print("\n─────────────────────────────────")
    print(f"Done! Results saved to: {OUTPUT_CSV}")
    print(f"  ✔ Found     : {found}")
    print(f"  ✘ Not found : {not_found}")
    if DOWNLOAD_AUDIO:
        print(f"  ↓ Downloaded: {download_ok}")
        print(f"  ! DL failed : {download_fail}")
    print("─────────────────────────────────")


if __name__ == "__main__":
    main()
