# Plum Seven-Point Optimization Smoke Log

Date: 2026-05-30
Repo: `/Users/Alex/AI/project/PlumWallPaper`

## Baseline

- Branch: `main`
- Source diff at checkpoint 0: none under `Sources/`, `Package.swift`, `project.yml`, `run.sh`, or `PlumWallPaper.xcodeproj/project.pbxproj`.
- Existing unrelated dirty work: non-code/archive cleanup in `.gitignore`, archived docs/design/cache files, and `docs/archive/2026-05-30-noncode-cleanup/`.
- UI validation source of truth: `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app`.
- Do not validate the main UI with `.build/arm64-apple-macosx/debug/PlumWallPaper` or `swift run`.

## Required Build Verification

Run after every checkpoint:

```bash
xcodegen generate
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build
```

For UI checkpoints, also verify the running process path before judging UI:

```bash
pgrep -fl PlumWallPaper
open Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
```

## Checkpoint Smoke Matrix

| Checkpoint | Scope | Build | Manual Smoke | Notes |
|---|---|---|---|---|
| 0 | Baseline and evidence | Passed | Not required | No production code change. |
| 1 | Unified wallpaper action/library state | Passed | Launch/local library smoke passed | Favorite/download/apply now route through `WallpaperLibraryStateService`. |
| 2 | Download queue and item feedback | Passed | Launch/local library smoke passed | Concurrent overflow now waits in queue instead of throwing immediately. |
| 3 | Preview resource pipeline | Pending | Hero first frame, card hover, detail full-res intent | Full-res work should be deduped and tied to explicit priority/intent. |
| 4 | Home hero-first experience | Pending | Launch Home, hero visible quickly, apply primary | Shelves must not block hero readiness. |
| 5 | Detail/Studio state split | Pending | Previous/next, clean preview, Studio enter/exit, preset save | Keep existing dark glass/artisan gallery behavior. |
| 6 | Explore source capability filters | Pending | Switch every source and reset filters | Inapplicable filters must not persist invisibly after source changes. |
| 7 | Library management and polish | Pending | Search, all sources, counts, scrollbar, download queue, text | Avoid false draggable scrollbar affordance. |

## Checkpoint Results

### Checkpoint 0

- Read project constraints: `AGENTS.md`, `CLAUDE.md`, `README.md`.
- Inspected requested core files and confirmed the primary risk areas:
  - Action state duplication across Home, cards, Detail, and Library.
  - Preview prefetching spread through views and a thin `PreviewResourcePipeline`.
  - Detail/Studio state still concentrated in `WallpaperDetailView`.
  - Explore filters are source-specific but represented as view conditionals.
  - Library has model search state without a main `MyLibraryView` search field.
- Production source changes: none.
- Environment note: the first build failed because Xcode was missing Metal Toolchain. Ran `xcodebuild -downloadComponent MetalToolchain`, which downloaded Metal Toolchain 17F42.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
  - `pgrep -fl PlumWallPaper`: no running app process.

### Checkpoint 1

- Added `WallpaperLibraryStateService` as the compatibility layer for persisted state, favorite state, downloaded state, download execution, local resolution before apply, and apply side effects.
- Updated Home hero/card downloads, Detail actions, wallpaper cards, and Library favorite/download filtering to consume the unified service instead of each surface directly querying `DownloadManager`, `FavoriteService`, or `WallpaperTopologyCoordinator`.
- Kept the existing SwiftData model and existing `DownloadManager` implementation unchanged; queue semantics remain for checkpoint 2.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app launched from `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened the Local tab; Library toolbar and empty state rendered without crash.
  - Quit the DerivedData app after smoke.

### Checkpoint 2

- Updated `DownloadManager` so requests beyond `maxConcurrentDownloads` enter a waiting queue instead of immediately throwing `tooManyDownloads`.
- Added `remoteId` to `DownloadTask` and exposed active task lookup by remote id for per-item feedback.
- Added duplicate in-flight detection through `WallpaperLibraryStateService`: repeated downloads for the same remote item now return the active queued/running task instead of enqueueing another copy.
- Updated Home hero and wallpaper cards to reflect waiting/downloading state from the shared per-item task state.
- Added a cancelled state for waiting tasks and kept the existing completed/failed removal behavior.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app launched from `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened the Local tab; Library toolbar and empty state rendered without crash.
  - Quit the DerivedData app after smoke.
