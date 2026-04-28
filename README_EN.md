English | [中文](README.md)

# PlumWallPaper

> Dynamic wallpaper engine for macOS — Video / HEIC wallpapers · Multi-display · Real-time filters

---

## Features

| Feature | Status |
|---------|--------|
| Video wallpaper (MP4/MOV) | ✅ |
| HEIC dynamic wallpaper | ✅ |
| Per-display wallpaper control | ✅ |
| Smart display detection | ✅ |
| File import + duplicate detection | ✅ |
| Auto thumbnail generation | ✅ |
| 9-parameter real-time filters | ✅ |
| Auto-restore wallpaper on launch | ✅ |
| Wallpaper library management | ✅ |
| Slideshow scheduler | 🔜 |
| Smart power management | 🔜 |

## Filter Parameters

Exposure · Contrast · Saturation · Hue · Blur · Grain · Vignette · Grayscale · Invert

## Tech Stack

- SwiftUI + SwiftData
- AVFoundation (video rendering)
- Core Image (filter chain)
- AppKit (desktop window + NSWorkspace)

## Requirements

- macOS 14.0+
- Xcode 16.0+
- Apple Silicon / Intel

## Project Structure

```
PlumWallPaper/Sources/
├── App/
│   └── PlumWallPaperApp.swift           # Entry point
│
├── UI/                                  # ── Frontend ──
│   ├── Theme.swift                      # Theme constants
│   ├── AppViewModel.swift               # Global state
│   ├── Views/
│   │   ├── HomeView.swift               # Home
│   │   ├── LibraryView.swift            # Library
│   │   ├── ColorAdjustView.swift        # Color adjustment
│   │   ├── SettingsView.swift           # Settings
│   │   ├── ImportModalView.swift        # Import modal
│   │   ├── MonitorSelectorView.swift    # Monitor selector
│   │   └── WallpaperDetailView.swift    # Wallpaper detail
│   └── Components/
│       ├── AdjustComponents.swift       # Adjust widgets
│       └── EdgeBorder.swift             # Border modifier
│
├── Core/                                # ── Backend ──
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift        # Render engine
│   │   └── WallpaperRenderer.swift      # Video + HEIC renderers
│   ├── DisplayManager/
│   │   └── DisplayManager.swift         # Display manager
│   ├── FilterEngine.swift               # Filter engine
│   ├── FileImporter.swift               # File importer
│   ├── ThumbnailGenerator.swift         # Thumbnail generator
│   └── RestoreManager.swift             # Session restore
│
├── Storage/                             # ── Storage ──
│   ├── Models/
│   │   ├── Wallpaper.swift              # Wallpaper model
│   │   ├── Tag.swift                    # Tag
│   │   ├── FilterPreset.swift           # Filter preset
│   │   └── Settings.swift               # Settings
│   ├── WallpaperStore.swift             # CRUD + queries
│   └── PreferencesStore.swift           # Preferences
│
└── System/                              # ── System bridge ──
    └── DesktopBridge.swift              # NSWorkspace wrapper
```

## Build

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

Or open `PlumWallPaper/PlumWallPaper.xcodeproj` in Xcode and press Cmd+R.

## Prototypes

| Path | Description |
|------|-------------|
| `ui-prototype/plumwallpaper-v5.html` | Latest full-page HTML prototype |
| `ui-prototype/home-v*.html` | Home page iterations |
| `ui-prototype/color-adjustment-v*.html` | Color adjustment iterations |
| `ui-prototype/settings-v*.html` | Settings page iterations |
| `src/` | React/TSX interactive prototype |

## License

MIT
