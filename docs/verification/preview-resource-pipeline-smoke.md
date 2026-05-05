# Preview Resource Pipeline Smoke

## Scope

This smoke verifies the first URL-selection consolidation in `PreviewResourcePipeline`.

Covered behavior:

- Home video preheating uses `PreviewResourcePipeline.previewVideoURL(for:)`.
- Media explore video preheating uses `PreviewResourcePipeline.preloadPreviewVideos(for:limit:)`.
- Media cards, wallpaper cards, and remote wallpaper cards prefetch through model-aware pipeline methods.
- Views no longer duplicate the most common `fullVideoURL ?? previewVideoURL` and remote URL checks for hover prefetch.

Not covered by this smoke:

- Thumbnail memory/disk cache internals.
- Video player reuse internals.
- Cache eviction policy changes.
- Source provider protocol extraction.

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

## Manual Preview Smoke

1. Open Home.
2. Confirm the hero poster appears quickly and does not remain black.
3. Hover several cards in `最新画作`.
4. Open one static detail and confirm the full-resolution image appears.
5. Hover several cards in `热门动态`.
6. Open one dynamic detail and confirm poster fallback appears before playback.
7. Switch to Static Explore.
8. Open a Wallhaven static detail and confirm it does not show a blank canvas.
9. Switch to Media Explore.
10. Open a video detail and confirm playback still starts after loading.
11. Confirm Static Explore and Media Explore show vertical scrollbars when content is taller than the viewport.

## Regression Checks

After the preview smoke:

- Favorite still toggles immediately in detail.
- Download still works from the detail dock.
- Apply still works from the detail dock.
- Studio panel still opens from the detail dock.

## Notes

Avoid full Computer Use window inspection for this smoke. Large accessibility trees or screenshots can trigger API `413 Payload Too Large` in the Codex client. Build verification plus these manual checks is the intended validation path for this stage.
