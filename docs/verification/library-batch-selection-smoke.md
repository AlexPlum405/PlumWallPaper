# Library Batch Selection Smoke

## Scope

This smoke verifies the pending My Library batch-selection enhancement.

Covered behavior:

- Edit mode keeps existing tap-to-select behavior.
- The toolbar shows a visible `全选` action in edit mode.
- `全选` selects every wallpaper currently visible under the active filters.
- When all visible wallpapers are selected, the action changes to `清空`.
- `清空` clears the selected visible wallpapers.
- Mouse or trackpad drag selection selects or deselects cards crossed by the drag path.
- Existing batch delete and batch remove favorite actions still operate on `selectedIDs`.

Not covered by this smoke:

- Import sheet behavior.
- Tag manager behavior.
- Detail preview behavior from the library.

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

## Manual Selection Smoke

1. Open the `本地` tab.
2. Choose a filter that shows at least two wallpapers.
3. Click `管理`.
4. Confirm cards shrink slightly and selection indicators appear.
5. Click `全选`.
6. Confirm all currently visible cards become selected.
7. Confirm the button text changes to `清空`.
8. Click `清空`.
9. Confirm the visible cards are no longer selected.
10. Press one card and drag across adjacent cards with the mouse or trackpad.
11. Confirm crossed cards select together.
12. Press a selected card and drag across selected cards with the mouse or trackpad.
13. Confirm crossed cards deselect together.
14. Click `完成`.
15. Confirm edit mode exits and selection clears.

## Regression Checks

After the selection smoke:

- Opening a library item outside edit mode still opens detail.
- Hovering local video items still starts preload.
- Batch remove favorite still removes favorite state for selected items.
- Batch delete still asks for confirmation before deleting selected items.

## Notes

Avoid full Computer Use window inspection for this smoke. Large accessibility trees or screenshots can trigger API `413 Payload Too Large` in the Codex client. Build verification plus these manual checks is the intended validation path for this stage.
