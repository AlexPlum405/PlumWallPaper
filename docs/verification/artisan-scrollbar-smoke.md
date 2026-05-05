# Artisan Scrollbar Smoke

## Scope

This smoke verifies the custom gallery scrollbar used by the high-density gallery pages.

Covered pages:

- `在线 > 静态`
- `在线 > 动态`
- `本地`

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
2. Go to `在线 > 静态` and load enough results to overflow vertically.
3. Confirm the system scrollbar is no longer shown as a heavy native strip.
4. Confirm a custom scrollbar is clearly visible near the right edge.
5. Move the pointer over the page and confirm the scrollbar widens and brightens.
6. Scroll the page and confirm the thumb tracks the scroll position and briefly stays highlighted.
7. Repeat the same checks in `在线 > 动态`.
8. Go to `本地` and test all three type filters: `全部`, `静态`, `动态`.
9. Confirm each overflowing list keeps the same custom scrollbar style.
10. Confirm short/empty lists do not show an unnecessary scrollbar.

## Design Checks

- The scrollbar should feel quiet and gallery-like, not like a default system control.
- The thumb should use a soft white-to-pink glass tint that matches the existing artisan palette.
- The track should start below the top navigation area and avoid visually cutting through the header.
- Wallpaper cards, selection checkboxes, and drag selection should remain usable.
