# Detail Favorite ViewModel Smoke

## Scope

This smoke verifies the first favorite-related ViewModel extraction in `WallpaperDetailView`.

Covered behavior:

- Detail dock favorite icon reads from `WallpaperDetailViewModel.isFavoriteDisplayed`.
- Opening a detail sheet syncs favorite display state from SwiftData when a persisted record exists.
- Clicking the detail heart updates the UI immediately.
- Online favorite creation and removal still go through `FavoriteService`.
- Navigating previous/next in detail refreshes the favorite display state for the new wallpaper.

Not covered by this smoke:

- Applying wallpapers to desktop.
- Download progress and file integrity.
- Studio preset persistence.
- Deep cache eviction behavior.

## Machine Verification

Run from the repository root:

```bash
xcodegen generate
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build
```

Expected result:

- XcodeGen finishes successfully.
- `xcodebuild` ends with `** BUILD SUCCEEDED **`.

## Manual Launch

Use only the DerivedData app bundle:

```bash
pkill -x PlumWallPaper || true
open Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
sleep 2
pgrep -fl PlumWallPaper
```

Expected process path:

```text
/Users/Alex/AI/project/PlumWallPaper/Build/DerivedData/Build/Products/Debug/PlumWallPaper.app/Contents/MacOS/PlumWallPaper
```

Do not validate this UI from:

```text
.build/arm64-apple-macosx/debug/PlumWallPaper
swift run
```

## Manual Favorite Smoke

1. Open the app from the DerivedData bundle.
2. From Home, open any online static wallpaper detail.
3. Confirm the detail preview image appears.
4. In the bottom detail dock, click the heart button once.
5. Confirm the heart changes immediately from outline to filled.
6. Confirm the toast says `已加入收藏`.
7. Close and reopen the same wallpaper detail.
8. Confirm the heart is still filled.
9. Click the heart again.
10. Confirm the heart changes immediately from filled to outline.
11. Confirm the toast says `已取消收藏`.
12. Close and reopen the same wallpaper detail.
13. Confirm the heart is still outline.

## Manual Navigation Smoke

If the detail sheet has previous/next controls:

1. Open a detail item.
2. Toggle favorite on.
3. Navigate to the next item.
4. Confirm the heart reflects the next item's own favorite state, not the previous item's state.
5. Navigate back.
6. Confirm the original item still shows filled.

## Regression Checks

Check these high-frequency paths after the favorite smoke:

- Home hero still shows a poster quickly and does not remain black.
- Online static detail previews still show the highest available image instead of a blank canvas.
- Online video detail previews still show poster fallback before video readiness.
- Opening Studio from the detail dock still displays the right-side panel.
- Download button remains enabled for downloadable online items.

## Notes

Avoid full Computer Use window inspection for this smoke. Large accessibility trees or screenshots can trigger API `413 Payload Too Large` in the Codex client. Build verification plus these manual checks is the intended validation path for this stage.
