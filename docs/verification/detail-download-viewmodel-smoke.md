# Detail Download ViewModel Smoke

## Scope

This smoke verifies the detail download-state extraction into `WallpaperDetailViewModel`.

Covered behavior:

- Detail dock reads download busy state from `WallpaperDetailViewModel.isDownloading`.
- Clicking download for a remote wallpaper disables the dock download button while the download is active.
- A successful download updates the active detail wallpaper to the downloaded local record.
- The detail view still calls its `onDownload` callback after a successful download.
- Local or already downloaded wallpapers show the existing `此壁纸已在本地` toast.

Not covered by this smoke:

- Apply-to-desktop rendering.
- Download retry UX.
- Cache eviction.
- Media detail downloads in `MediaDetailView`.

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

## Manual Download Smoke

1. Open the app from the DerivedData bundle.
2. Open an online static wallpaper detail that has not already been downloaded.
3. Confirm the detail preview appears.
4. Click the download button in the bottom detail dock.
5. Confirm the download button becomes disabled while the download is active.
6. Confirm the download progress overlay appears if the file is large enough.
7. Wait for completion.
8. Confirm the toast says `下载完成`.
9. Close and reopen the same wallpaper detail or find it in the local/downloaded library surface.
10. Click download again.
11. Confirm the toast says `此壁纸已在本地`.

## Regression Checks

After the download smoke:

- Detail favorite still toggles immediately.
- Detail apply button still starts from the currently visible wallpaper.
- Home hero still shows poster fallback quickly.
- Static detail previews do not regress to a blank canvas.
- Studio panel still opens from the detail dock.

## Notes

Avoid full Computer Use window inspection for this smoke. Large accessibility trees or screenshots can trigger API `413 Payload Too Large` in the Codex client. Build verification plus these manual checks is the intended validation path for this stage.
