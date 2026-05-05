# Library Downloaded Thumbnail Smoke

## Scope

This smoke verifies thumbnails after downloading an online favorite from the local Favorites library.

Covered behavior:

- Online favorite cards in `本地 > 收藏` keep a thumbnail before download.
- Clicking download from detail downloads the asset and converts the saved record to `.downloaded`.
- The downloaded record still has a usable thumbnail.
- Existing records with `file:///...` thumbnail strings still render in `WallpaperCard`.

## Machine Verification

Run from the repository root:

```bash
xcodegen generate
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build
```

Expected result:

- XcodeGen finishes successfully.
- `xcodebuild` ends with `** BUILD SUCCEEDED **`.

## Manual Smoke

1. Open the DerivedData app.
2. Go to `本地`.
3. Choose the `收藏` source filter.
4. Pick an online favorite whose thumbnail is visible.
5. Open its detail page.
6. Click the detail download button.
7. Wait for `下载完成`.
8. Return to `本地 > 收藏`.
9. Confirm the same wallpaper card still shows a thumbnail.
10. Switch to the downloaded/local filter if needed and confirm the downloaded card also shows a thumbnail.

## Regression Checks

- Downloaded static wallpapers still open detail.
- Downloaded video wallpapers still show a poster or generated frame.
- Existing file-path thumbnails and remote URL thumbnails both still render.
