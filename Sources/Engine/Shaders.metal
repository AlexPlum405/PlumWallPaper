// Sources/Engine/Shaders.metal
#include <metal_stdlib>
using namespace metal;

// 曝光调整
kernel void exposureFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float exposure = params[0];
    color.rgb *= pow(2.0, exposure);
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 对比度
kernel void contrastFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float contrast = params[0];
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 饱和度
kernel void saturationFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float saturation = params[0];
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(float3(gray), color.rgb, saturation);
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 色调旋转
kernel void hueFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float angle = params[0] * 3.14159265 / 180.0;
    float cosA = cos(angle);
    float sinA = sin(angle);
    float3x3 hueRotation = float3x3(
        float3(0.213 + cosA*0.787 - sinA*0.213, 0.213 - cosA*0.213 + sinA*0.143, 0.213 - cosA*0.213 - sinA*0.787),
        float3(0.715 - cosA*0.715 - sinA*0.715, 0.715 + cosA*0.285 + sinA*0.140, 0.715 - cosA*0.715 + sinA*0.715),
        float3(0.072 - cosA*0.072 + sinA*0.928, 0.072 - cosA*0.072 - sinA*0.283, 0.072 + cosA*0.928 + sinA*0.072)
    );
    color.rgb = hueRotation * color.rgb;
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 灰度
kernel void grayscaleFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0];
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(color.rgb, float3(gray), intensity);
    output.write(float4(color.rgb, color.a), gid);
}

// 反转
kernel void invertFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0];
    color.rgb = mix(color.rgb, 1.0 - color.rgb, intensity);
    output.write(float4(color.rgb, color.a), gid);
}

// 暗角
kernel void vignetteFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0];
    float2 uv = float2(gid) / float2(input.get_width(), input.get_height());
    float2 center = uv - 0.5;
    float dist = length(center);
    float vignette = 1.0 - smoothstep(0.3, 0.8, dist) * intensity;
    color.rgb *= vignette;
    output.write(float4(color.rgb, color.a), gid);
}

// 全屏渲染顶点着色器
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut fullscreenVertex(uint vid [[vertex_id]]) {
    VertexOut out;
    float2 positions[4] = { {-1,-1}, {1,-1}, {-1,1}, {1,1} };
    float2 texCoords[4] = { {0,1}, {1,1}, {0,0}, {1,0} };
    out.position = float4(positions[vid], 0, 1);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 textureFragment(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    return tex.sample(s, in.texCoord);
}
