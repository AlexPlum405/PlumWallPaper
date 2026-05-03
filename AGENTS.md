# Project Instructions

## Huashu-Design Execution Contract

When the user invokes `huashu-design` or references `/Users/Alex/.codex/skills/huashu-design/SKILL.md`, do not treat it as a writing style or a suggestion mode.

You must enter senior product/design expert mode and follow the skill workflow as an execution process:

- Do not say "I will use huashu-design..." as the main response. Embody the role directly.
- First inspect the current project UI, screenshots, code, and design language when available.
- Restate the design problem as a concrete design brief before proposing solutions.
- Provide at least three meaningfully different design directions when the target design is not already fixed.
- Produce a visual artifact by default: HTML prototype, interaction demo, variation canvas, or high-fidelity mockup.
- Prefer concrete layouts, states, motion, dimensions, and tradeoffs over abstract advice.
- Validate visual output with browser screenshots or interaction checks when a prototype is created.
- Only after the user chooses a direction should production SwiftUI implementation begin.

For this project specifically, PlumWallPaper design work must respect the existing dark glass/artisan gallery style unless the user explicitly asks for a new visual direction.

## Build And Run Guardrails

PlumWallPaper has repeatedly shown stale UI when the app is launched from an old SwiftPM `.build` binary. The project-level debug source of truth is the Xcode project and the local DerivedData path.

- Before judging a UI regression, confirm the running process path with `pgrep -fl PlumWallPaper`.
- Rebuild with `xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build`.
- Restart with `open Build/DerivedData/Build/Products/Debug/PlumWallPaper.app`.
- Do not use `.build/arm64-apple-macosx/debug/PlumWallPaper` or `swift run` to validate the main macOS UI unless the task explicitly targets the SwiftPM binary.
- If the Home hero loses the favorite/download actions, first suspect a stale build or mixed launch path. After rebuild/restart, verify the window contains the hero `heart.fill` favorite button and `arrow.down.to.line.compact` download button.
- Keep `run.sh` aligned with the Xcode DerivedData build path so future agents do not accidentally restart the old binary.
