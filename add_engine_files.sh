#!/bin/bash

# 使用 plutil 和 PlistBuddy 来编辑 Xcode 项目
# 但这很复杂，让我们用更简单的方法

# 方法：使用 xcodebuild 的 -list 来验证，然后手动编辑 pbxproj

PROJECT_FILE="PlumWallPaper.xcodeproj/project.pbxproj"

# 生成 UUID（Xcode 使用 24 字符的十六进制 UUID）
generate_uuid() {
    echo $(uuidgen | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
}

# 为每个文件生成 UUID
VIDEO_DECODER_REF=$(generate_uuid)
SHADER_PASS_REF=$(generate_uuid)
SHADER_GRAPH_REF=$(generate_uuid)
SHADERS_METAL_REF=$(generate_uuid)
DESKTOP_WINDOW_REF=$(generate_uuid)
SCREEN_RENDERER_REF=$(generate_uuid)
RENDER_PIPELINE_REF=$(generate_uuid)

VIDEO_DECODER_BUILD=$(generate_uuid)
SHADER_PASS_BUILD=$(generate_uuid)
SHADER_GRAPH_BUILD=$(generate_uuid)
SHADERS_METAL_BUILD=$(generate_uuid)
DESKTOP_WINDOW_BUILD=$(generate_uuid)
SCREEN_RENDERER_BUILD=$(generate_uuid)
RENDER_PIPELINE_BUILD=$(generate_uuid)

ENGINE_GROUP=$(generate_uuid)

echo "Generated UUIDs:"
echo "VideoDecoder: $VIDEO_DECODER_REF / $VIDEO_DECODER_BUILD"
echo "ShaderPass: $SHADER_PASS_REF / $SHADER_PASS_BUILD"
echo "ShaderGraph: $SHADER_GRAPH_REF / $SHADER_GRAPH_BUILD"
echo "Shaders.metal: $SHADERS_METAL_REF / $SHADERS_METAL_BUILD"
echo "DesktopWindow: $DESKTOP_WINDOW_REF / $DESKTOP_WINDOW_BUILD"
echo "ScreenRenderer: $SCREEN_RENDERER_REF / $SCREEN_RENDERER_BUILD"
echo "RenderPipeline: $RENDER_PIPELINE_REF / $RENDER_PIPELINE_BUILD"
echo "Engine Group: $ENGINE_GROUP"

