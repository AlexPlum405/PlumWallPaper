# Detail Apply ViewModel Smoke

## Scope

This smoke verifies the detail apply-to-wallpaper extraction into `WallpaperDetailViewModel`.

Covered behavior:

- Detail dock reads apply busy state from `WallpaperDetailViewModel.isApplying`.
- Clicking `设为壁纸` disables the apply button while work is active.
- Local static wallpapers still render effects before being applied through `WallpaperSetter`.
- Local video wallpapers still apply through `RenderPipeline.setWallpaper`.
- Remote wallpapers are downloaded before apply when needed.
- Remote video apply prefers the high-quality `downloadQuality` URL when it is a remote URL.
- When a remote wallpaper is downloaded during apply, the detail view updates its active wallpaper and calls `onDownload`.

Not covered by this smoke:

- OS-level wallpaper permission prompts.
- Long-running renderer stability after multiple hours.
- Download retry UX.

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

## Manual Apply Smoke

1. Open the app from the DerivedData bundle.
2. Open an online static wallpaper detail.
3. Confirm the preview appears.
4. Click `设为壁纸`.
5. Confirm the apply button shows its busy state while work is active.
6. Confirm the toast says `设置成功` for a basic static apply.
7. Open Studio, enable any dynamic weather or particle effect, then click `设为壁纸` again.
8. Confirm the toast says `已应用基础调校，动态天气/粒子已保存`.
9. Open an online video wallpaper detail.
10. Click `设为壁纸`.
11. Confirm the video downloads if needed and then applies through the dynamic renderer.

## Regression Checks

After the apply smoke:

- Detail favorite still toggles immediately.
- Detail download still shows `下载完成` and `此壁纸已在本地` in the expected cases.
- Static detail previews do not regress to a blank canvas.
- Video detail previews still use poster fallback before playback readiness.
- Studio panel still opens from the detail dock.

## Notes

Avoid full Computer Use window inspection for this smoke. Large accessibility trees or screenshots can trigger API `413 Payload Too Large` in the Codex client. Build verification plus these manual checks is the intended validation path for this stage.
