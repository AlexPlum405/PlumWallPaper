#!/usr/bin/env python3
"""
自动将新文件添加到 Xcode 项目的脚本
"""
import os
import subprocess

# 需要添加到项目的新文件
new_files = [
    # Network
    "Sources/Network/NetworkError.swift",
    "Sources/Network/NetworkState.swift",
    "Sources/Network/NetworkMonitor.swift",
    "Sources/Network/NetworkService.swift",
    "Sources/Network/CacheService.swift",
    "Sources/Network/WallhavenAPI.swift",
    "Sources/Network/WallhavenService.swift",
    "Sources/Network/FourKWallpapersService.swift",
    "Sources/Network/FourKWallpapersParser.swift",
    "Sources/Network/MediaService.swift",
    "Sources/Network/WorkshopService.swift",
    "Sources/Network/WorkshopSourceManager.swift",
    "Sources/Network/WallpaperSourceManager.swift",

    # OnlineModels
    "Sources/OnlineModels/RemoteWallpaper.swift",
    "Sources/OnlineModels/MediaItem.swift",
    "Sources/OnlineModels/WorkshopModels.swift",
    "Sources/OnlineModels/WallpaperDisplayItem.swift",

    # Repositories
    "Sources/Repositories/WallpaperRepository.swift",
    "Sources/Repositories/MediaRepository.swift",

    # ViewModels
    "Sources/ViewModels/HomeFeedViewModel.swift",
    "Sources/ViewModels/WallpaperExploreViewModel.swift",
    "Sources/ViewModels/MediaExploreViewModel.swift",

    # Services
    "Sources/Services/DownloadManager.swift",

    # Views/Components
    "Sources/Views/Components/RemoteWallpaperCard.swift",
    "Sources/Views/Components/MediaCard.swift",
    "Sources/Views/Components/QualitySelector.swift",
    "Sources/Views/Components/DownloadProgressView.swift",

    # Views/Explore
    "Sources/Views/Explore/MediaExploreView.swift",
    "Sources/Views/Explore/MediaExploreView+Components.swift",
    "Sources/Views/Explore/RemoteWallpaperDetailView.swift",

    # Views/Detail
    "Sources/Views/Detail/MediaDetailView.swift",
]

project_dir = "/Users/Alex/AI/project/PlumWallPaper"
os.chdir(project_dir)

print("📝 需要添加到 Xcode 项目的文件：")
for f in new_files:
    exists = "✅" if os.path.exists(f) else "❌"
    print(f"  {exists} {f}")

print("\n" + "="*60)
print("⚠️  由于 Xcode 项目文件格式复杂，建议手动添加：")
print("="*60)
print("\n在 Xcode 中：")
print("1. 右键点击对应的文件夹（如 Network、OnlineModels 等）")
print("2. 选择 'Add Files to PlumWallPaper...'")
print("3. 选择对应的 .swift 文件")
print("4. 确保 'Copy items if needed' 未选中")
print("5. 确保 'PlumWallPaper' target 被选中")
print("\n或者：")
print("直接将上述文件拖拽到 Xcode 项目导航器中对应的文件夹")
