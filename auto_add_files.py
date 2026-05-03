#!/usr/bin/env python3
"""
自动将新文件添加到 Xcode 项目的脚本
修改 project.pbxproj 文件
"""
import uuid
import re

def generate_uuid():
    """生成 Xcode 风格的 24 字符 UUID"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(project_path, files_to_add):
    """
    添加文件到 Xcode 项目
    """
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 存储生成的 UUID 和文件引用
    file_refs = {}
    build_files = {}

    # 1. 生成 PBXFileReference 条目
    file_ref_section = []
    for file_path in files_to_add:
        file_uuid = generate_uuid()
        file_name = file_path.split('/')[-1]
        file_refs[file_path] = file_uuid

        file_ref_entry = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n'
        file_ref_section.append(file_ref_entry)

    # 2. 生成 PBXBuildFile 条目
    build_file_section = []
    for file_path, file_uuid in file_refs.items():
        build_uuid = generate_uuid()
        file_name = file_path.split('/')[-1]
        build_files[file_path] = build_uuid

        build_entry = f'\t\t{build_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {file_name} */; }};\n'
        build_file_section.append(build_entry)

    # 3. 插入 PBXFileReference
    pbx_file_ref_pattern = r'(/\* Begin PBXFileReference section \*/\n)'
    file_ref_insert = ''.join(file_ref_section)
    content = re.sub(pbx_file_ref_pattern, r'\1' + file_ref_insert, content)

    # 4. 插入 PBXBuildFile
    pbx_build_file_pattern = r'(/\* Begin PBXBuildFile section \*/\n)'
    build_file_insert = ''.join(build_file_section)
    content = re.sub(pbx_build_file_pattern, r'\1' + build_file_insert, content)

    # 5. 添加到 PBXGroup（按目录组织）
    groups = {}
    for file_path in files_to_add:
        parts = file_path.split('/')
        if len(parts) >= 2:
            group_name = parts[1]  # Sources/Network -> Network
            if group_name not in groups:
                groups[group_name] = []
            groups[group_name].append((file_path, file_refs[file_path]))

    # 为每个组添加文件引用
    for group_name, files in groups.items():
        # 查找对应的 PBXGroup
        group_pattern = rf'(/\* {group_name} \*/.*?children = \(\n)(.*?)(\);)'

        def add_to_group(match):
            prefix = match.group(1)
            existing = match.group(2)
            suffix = match.group(3)

            new_entries = []
            for file_path, file_uuid in files:
                file_name = file_path.split('/')[-1]
                new_entries.append(f'\t\t\t\t{file_uuid} /* {file_name} */,\n')

            return prefix + existing + ''.join(new_entries) + suffix

        content = re.sub(group_pattern, add_to_group, content, flags=re.DOTALL)

    # 6. 添加到 PBXSourcesBuildPhase
    sources_pattern = r'(/\* Sources \*/.*?files = \(\n)(.*?)(\);)'

    def add_to_sources(match):
        prefix = match.group(1)
        existing = match.group(2)
        suffix = match.group(3)

        new_entries = []
        for file_path, build_uuid in build_files.items():
            file_name = file_path.split('/')[-1]
            new_entries.append(f'\t\t\t\t{build_uuid} /* {file_name} in Sources */,\n')

        return prefix + existing + ''.join(new_entries) + suffix

    content = re.sub(sources_pattern, add_to_sources, content, flags=re.DOTALL)

    # 写回文件
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)

    return len(files_to_add)

# 需要添加的文件列表
files_to_add = [
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
    "Sources/OnlineModels/RemoteWallpaper.swift",
    "Sources/OnlineModels/MediaItem.swift",
    "Sources/OnlineModels/WorkshopModels.swift",
    "Sources/OnlineModels/WallpaperDisplayItem.swift",
    "Sources/Repositories/WallpaperRepository.swift",
    "Sources/Repositories/MediaRepository.swift",
    "Sources/ViewModels/HomeFeedViewModel.swift",
    "Sources/ViewModels/WallpaperExploreViewModel.swift",
    "Sources/ViewModels/MediaExploreViewModel.swift",
    "Sources/Services/DownloadManager.swift",
    "Sources/Views/Components/RemoteWallpaperCard.swift",
    "Sources/Views/Components/MediaCard.swift",
    "Sources/Views/Components/QualitySelector.swift",
    "Sources/Views/Components/DownloadProgressView.swift",
    "Sources/Views/Explore/MediaExploreView.swift",
    "Sources/Views/Explore/MediaExploreView+Components.swift",
    "Sources/Views/Explore/RemoteWallpaperDetailView.swift",
    "Sources/Views/Detail/MediaDetailView.swift",
]

if __name__ == "__main__":
    project_path = "/Users/Alex/AI/project/PlumWallPaper/PlumWallPaper.xcodeproj/project.pbxproj"

    print("🔧 正在修改 Xcode 项目文件...")
    print(f"📝 需要添加 {len(files_to_add)} 个文件")

    try:
        count = add_files_to_xcode_project(project_path, files_to_add)
        print(f"✅ 成功添加 {count} 个文件到 Xcode 项目")
        print("\n⚠️  注意：")
        print("1. 如果出现问题，可以恢复备份：")
        print("   cp PlumWallPaper.xcodeproj/project.pbxproj.backup PlumWallPaper.xcodeproj/project.pbxproj")
        print("2. 在 Xcode 中打开项目验证文件是否正确添加")
    except Exception as e:
        print(f"❌ 错误: {e}")
        print("正在恢复备份...")
        import shutil
        shutil.copy(project_path + ".backup", project_path)
        print("✅ 已恢复备份")
