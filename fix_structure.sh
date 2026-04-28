#!/bin/bash
mv PlumWallPaper/Sources/Resources/Fonts PlumWallPaper/Sources/Resources/Web/Fonts
mv Sources/Resources/Fonts Sources/Resources/Web/Fonts 2>/dev/null || true
sed -i '' 's/path = Fonts;/path = Web\/Fonts;/g' PlumWallPaper/PlumWallPaper.xcodeproj/project.pbxproj
