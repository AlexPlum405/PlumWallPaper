#!/usr/bin/env python3
import urllib.request
import urllib.error
import re
import os
import sys

OUT_DIR = "/Users/Alex/AI/project/PlumWallPaper/Wallpapers"

# Mixkit video page URLs to try (different categories)
PAGES = [
    # Stars / Galaxy
    "https://mixkit.co/free-stock-video/the-milky-way-revealing-itself-in-the-night-sky-30524/",
    "https://mixkit.co/free-stock-video/cyberpunk-virtual-city-at-night-with-galaxy-in-the-background-19213/",
    "https://mixkit.co/free-stock-video/dark-starry-night-1107/",
    "https://mixkit.co/free-stock-video/starry-sky-with-shooting-stars-2479/",
    "https://mixkit.co/free-stock-video/full-moon-2087/",
    "https://mixkit.co/free-stock-video/dark-blue-sky-full-of-stars-4783/",
    "https://mixkit.co/free-stock-video/dark-and-starry-skyline-2475/",
    "https://mixkit.co/free-stock-video/flying-through-dark-matter-in-space-2477/",
    "https://mixkit.co/free-stock-video/fantasy-fire-particles-1102/",
    "https://mixkit.co/free-stock-video/fantasy-fire-magic-1101/",
    "https://mixkit.co/free-stock-video/aurora-borealis-timelapse-4811/",
    "https://mixkit.co/free-stock-video/night-sky-covered-with-stars-4781/",
    "https://mixkit.co/free-stock-video/sky-on-a-night-to-sunrise-transition-2089/",
    "https://mixkit.co/free-stock-video/times-square-during-a-rainy-night-4797/",
    "https://mixkit.co/free-stock-video/starry-sky-with-clouds-drifting-by-2473/",
    "https://mixkit.co/free-stock-video/neon-abstract-background-34465/",
    "https://mixkit.co/free-stock-video/digital-particles-in-a-dark-background-34468/",
    "https://mixkit.co/free-stock-video/digital-data-network-34470/",
    "https://mixkit.co/free-stock-video/hyper-modern-city-at-night-34367/",
    "https://mixkit.co/free-stock-video/ultra-detailed-galaxy-and-stars-34365/",
]

def fetch_cdn_url(page_url):
    try:
        req = urllib.request.Request(page_url, headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        with urllib.request.urlopen(req, timeout=10) as r:
            html = r.read().decode('utf-8', errors='ignore')
        matches = re.findall(r'https://assets\.mixkit\.co[^"]+\.mp4', html)
        if matches:
            return matches[0]
        return None
    except Exception as e:
        print(f"  Error fetching {page_url}: {e}", file=sys.stderr)
        return None

def download_video(url, filename):
    out_path = os.path.join(OUT_DIR, filename)
    if os.path.exists(out_path):
        print(f"  Already exists, skipping: {filename}")
        return True
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        with urllib.request.urlopen(req, timeout=60) as r:
            size = int(r.headers.get('Content-Length', 0))
            print(f"  Downloading {filename} ({size//1024//1024}MB)...")
            chunk_size = 1024 * 1024
            downloaded = 0
            with open(out_path, 'wb') as f:
                while True:
                    chunk = r.read(chunk_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    if size > 0:
                        pct = downloaded * 100 // size
                        print(f"\r  [{pct}%]", end='', flush=True)
        print()
        print(f"  Done: {filename}")
        return True
    except Exception as e:
        print(f"\n  Failed: {e}", file=sys.stderr)
        if os.path.exists(out_path):
            os.remove(out_path)
        return False

def slug_to_name(url):
    m = re.search(r'-(\d+)/$', url)
    return m.group(1) if m else url.split('/')[-2]

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Downloading to: {OUT_DIR}")
    print(f"Total pages to check: {len(PAGES)}")
    print()

    success = 0
    for i, page_url in enumerate(PAGES, 1):
        video_id = slug_to_name(page_url)
        print(f"[{i}/{len(PAGES)}] Checking: {video_id}")

        cdn_url = fetch_cdn_url(page_url)
        if not cdn_url:
            print(f"  No CDN URL found")
            continue

        filename = f"{video_id}.mp4"
        print(f"  Found: {cdn_url}")
        if download_video(cdn_url, filename):
            success += 1

        print()

    print(f"\nDownload complete! {success} videos saved to {OUT_DIR}")

if __name__ == "__main__":
    main()
