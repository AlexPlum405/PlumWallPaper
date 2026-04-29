#!/usr/bin/env python3
import urllib.request
import os
import time

SAVE_DIR = "/Users/Alex/AI/project/PlumWallPaper/Wallpapers"

CATEGORIES = {
    "01_Nature": [
        ("Mountains sunrise", "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=3840&q=90"),
        ("Mountain stars", "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=3840&q=90"),
        ("Desert dunes", "https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=3840&q=90"),
        ("Ocean waves", "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=3840&q=90"),
        ("Northern lights", "https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=3840&q=90"),
        ("Tropical beach", "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=3840&q=90"),
        ("Forest fog", "https://images.unsplash.com/photo-1448375240586-882707db888b?w=3840&q=90"),
        ("Waterfall", "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=3840&q=90"),
        ("Snowy peaks", "https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=3840&q=90"),
        ("Lavender field", "https://images.unsplash.com/photo-1499002238440-d264edd596ec?w=3840&q=90"),
        ("Volcano", "https://images.unsplash.com/photo-1462332420958-a05d1e002413?w=3840&q=90"),
        ("Canyon", "https://images.unsplash.com/photo-1474044159687-1ee9f3a51722?w=3840&q=90"),
    ],
    "02_Tech": [
        ("City night", "https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=3840&q=90"),
        ("Neon city", "https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=3840&q=90"),
        ("Cyberpunk street", "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=3840&q=90"),
        ("Tech circuit", "https://images.unsplash.com/photo-1518770660439-4636190af475?w=3840&q=90"),
        ("Data center", "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=3840&q=90"),
        ("Server room", "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=3840&q=90"),
        ("Robot eye", "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=3840&q=90"),
        ("Solar panels", "https://images.unsplash.com/photo-1509391366360-2e959784a276?w=3840&q=90"),
    ],
    "03_Pets": [
        ("Cute dog", "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=3840&q=90"),
        ("Curious cat", "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=3840&q=90"),
        ("Bunny", "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=3840&q=90"),
        ("Puppy eyes", "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=3840&q=90"),
        ("Kitten", "https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=3840&q=90"),
        ("Parrot", "https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=3840&q=90"),
        ("Hamster", "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=3840&q=90"),
        ("Golden retriever", "https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=3840&q=90"),
    ],
    "04_Beauty": [
        ("Portrait glow", "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=3840&q=90"),
        ("Model studio", "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=3840&q=90"),
        ("Fashion beauty", "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=3840&q=90"),
        ("Woman portrait", "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=3840&q=90"),
        ("Natural beauty", "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=3840&q=90"),
        ("Elegant", "https://images.unsplash.com/photo-1502767089025-6572583495f4?w=3840&q=90"),
        ("Summer beauty", "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=3840&q=90"),
        ("Street fashion", "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=3840&q=90"),
    ],
    "05_Food": [
        ("Sushi platter", "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=3840&q=90"),
        ("Steak dinner", "https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=3840&q=90"),
        ("Pizza closeup", "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=3840&q=90"),
        ("Ramen", "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=3840&q=90"),
        ("Ice cream", "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=3840&q=90"),
        ("Burgers", "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=3840&q=90"),
        ("Chocolate cake", "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=3840&q=90"),
        ("Coffee art", "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=3840&q=90"),
    ],
}

def download_image(url, filepath):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
            with open(filepath, 'wb') as f:
                f.write(data)
            size = len(data) / 1024 / 1024
            return True, size
    except Exception as e:
        return False, str(e)

def sanitize(name):
    return name.replace(' ', '_').replace('/', '-')

def main():
    total_ok = 0
    total_fail = 0
    total_size = 0

    for cat_name, photos in CATEGORIES.items():
        cat_dir = os.path.join(SAVE_DIR, cat_name)
        os.makedirs(cat_dir, exist_ok=True)
        print(f"\n{'='*60}")
        print(f"📁 {cat_name}")
        print('='*60)

        for i, (name, url) in enumerate(photos):
            safe_name = sanitize(name)
            filepath = os.path.join(cat_dir, f"{safe_name}.jpg")
            if os.path.exists(filepath):
                size = os.path.getsize(filepath) / 1024 / 1024
                print(f"  ⏭️  [{i+1}/{len(photos)}] 已存在: {name} ({size:.1f}MB)")
                total_ok += 1
                total_size += size
                continue

            print(f"  ⬇️  [{i+1}/{len(photos)}] 下载中: {name} ...", end=' ', flush=True)
            ok, result = download_image(url, filepath)
            if ok:
                print(f"✅ {result:.1f}MB")
                total_ok += 1
                total_size += result
            else:
                print(f"❌ {result}")
                total_fail += 1
            time.sleep(0.5)

    print(f"\n{'='*60}")
    print(f"✅ 完成! 成功: {total_ok}, 失败: {total_fail}, 总计: {total_size:.1f}MB")

if __name__ == "__main__":
    main()
