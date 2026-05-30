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
| 3 | Preview resource pipeline | Passed | Launch/local library/static Explore smoke passed; online hero/card content not fully judgeable in this run | Full-res work is now deduped and tied to explicit preview intent/priority. |
| 4 | Home hero-first experience | Passed | Home hero visible quickly, apply primary, Local tab smoke passed | Shelves no longer block hero readiness. |
| 5 | Detail/Studio state split | Passed | Detail card open, Studio enter/exit, preset save, clean preview enter/exit passed; previous/next controls remained visible | Existing dark glass/artisan gallery behavior preserved. |
| 6 | Explore source capability filters | Passed | Static tab render smoke passed; source switch behavior verified by capability model/build, with direct live clicking blocked by loginwindow overlay | Inapplicable filters are normalized through `selectSource(_:)` and `applyFilters()`. |
| 7 | Library management and polish | Passed | Local tab screenshot smoke passed; download/scrollbar polish verified by build and code path | Local library now starts from all sources and exposes search/counts. |

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

### Checkpoint 3

- Added `PreviewIntent` priorities for hero immediate, visible card, hover intent, and detail full-resolution requests.
- Routed full-resolution preview downloads through `PreviewResourcePipeline` so hover/visible/hero paths only touch existing cache or light video preview; detail/tap intent remains the explicit full-resolution path.
- Kept `FullResolutionPreviewCache` as the LRU/budgeted cache and added cancellable task metadata for low-priority preview work.
- Updated `VideoPreloader` with dynamic memory-based limits, priority-aware dedupe, LRU cleanup, cancellation, and debug-only logging.
- Replaced view-level ad hoc full-resolution hover prefetches in Home, cards, Explore, Library, and Detail with intent-aware pipeline calls.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app launched from `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened the Local tab; toolbar, source filters, import/manage actions, and empty state rendered without crash.
  - Opened the Static tab; source/filter UI and loading state rendered without crash.
  - Online hero/card/detail media could not be fully judged in this smoke because external content did not finish loading during the check.
  - Quit the DerivedData app after smoke.

### Checkpoint 4

- Changed `HomeFeedViewModel` to publish hero content first, then load latest static wallpapers and popular motions in a background shelves task.
- Changed hero source selection to return the first non-empty candidate set within a bounded 5-second hero-first window instead of waiting for every external hero source.
- Updated `HomeView` so `latestStills` no longer controls the top-level loading gate; shelves render skeleton rows while they load.
- Reduced hero metadata noise to resolution plus motion identity, keeping the primary CTA focused on `设为壁纸`; download and favorite remain secondary actions backed by shared library state.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app launched from `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Home rendered a Pexels hero within the smoke window; hero showed `设为壁纸`, `下载原片`, favorite state, resolution, and motion chip.
  - Shelves below hero showed loading placeholders instead of blocking hero.
  - Opened the Local tab; Library toolbar and empty state rendered without crash.
  - Quit the DerivedData app after smoke.

### Checkpoint 5

- Added `StudioSessionState` to own Studio mode state, filter values, weather/particle settings, render effects, shader pass serialization, preset application, reset, and saved preset loading.
- Moved `BuiltInPreset` out of the detail view shell so Studio preset data is shared by the state object and panel.
- Changed `DetailPreviewCanvas` to accept a single `WallpaperRenderEffects` value instead of many individual filter/weather/particle parameters.
- Reduced `WallpaperDetailView` back toward a shell that wires canvas, title HUD, mode controls, action dock, and `DetailStudioPanel`; Studio actions now delegate to `StudioSessionState`.
- Preserved current visual structure and interaction model; no dark glass/artisan gallery redesign was introduced.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app launched from `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened a Home card detail sheet via Accessibility; detail rendered title HUD, side navigation affordances, mode controls, and action dock.
  - Entered Studio mode; `DetailStudioPanel` rendered on the right and applied the `电影` preset, updating intensity and weather/particle effects.
  - Saved Studio parameters through the panel save control without crash.
  - Entered and exited pure preview; chrome hid and restored correctly.
  - Previous/next controls remained visible in Detail after returning from pure preview; no regression was observed in the detail shell.

### Checkpoint 6

- Added a source capability model for Wallhaven, Bing Daily, Pexels, Unsplash, and Pixabay.
- Replaced the previous split "advanced/more filters" hierarchy with one capability-driven filter surface.
- Added active filter chips, per-chip clearing, and a source-aware reset action.
- Source changes now normalize unsupported state: Bing clears search/ratio/color/purity, API-backed sources clear Wallhaven-only exact resolution/ratio/color/purity, and invalid categories/sorting values fall back to source defaults.
- Added a capability strip that names supported features and API key requirements for the selected source.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed.
- Manual smoke:
  - Confirmed app process path: `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened the Static tab through the existing `.plumSwitchMainTab` notification and captured the DerivedData app window.
  - Wallhaven rendered the search bar, source chips, capability summary, unified category/purity/sort/resolution/ratio/color filter surface, and no API key banner.
  - Direct source-chip clicking could not be completed in this run because `loginwindow` was the topmost on-screen owner and intercepted live mouse hit-testing; source switching behavior was therefore checked against the ViewModel normalization code and the successful Debug build rather than overstated as a full click smoke.

### Checkpoint 7

- Changed the Library source model to include `全部来源` and made it the default, so downloaded/imported/online-favorite resources are no longer hidden behind the favorites-only default.
- Added the main Library search field backed by the existing `searchText`, matching name, resolution, local/remote source, and author.
- Added count feedback to type filters, source filters, tag filters, and the Library search row.
- Updated Library empty-state copy so an empty library and an empty filtered result explain different recovery paths.
- Weakened `ArtisanVerticalScrollView` from a full fake track/thumb affordance into a narrow non-interactive scroll indicator.
- Polished download feedback: waiting tasks show queue position, waiting downloads can be cancelled from the overlay, failed/cancelled rows can be dismissed, and user-visible download errors are more specific.
- Moved high-frequency Library and DownloadManager diagnostics behind DEBUG-only logging; progress updates no longer emit a log line for every progress tick.
- Replaced the remaining English Explore loading copy touched in this pass with Chinese text.
- Build verification:
  - `xcodegen generate`: passed.
  - `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`: passed after fixing one local opaque-return compile issue in the empty state.
- Manual smoke:
  - Confirmed app process path: `Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper`.
  - Opened the Local tab through the existing `.plumSwitchMainTab` notification and captured the DerivedData app window.
  - Local tab rendered type counts, the search box, `全部来源 / 收藏 / 下载 / 导入` source counts, management actions, import action, and the updated empty state.
  - The current machine screen remained covered by `loginwindow`, so direct click/drag smoke for search typing, scrollbar motion, and live download queue controls could not be completed without user unlock; these paths were verified by build and code inspection instead of overstating live interaction coverage.
