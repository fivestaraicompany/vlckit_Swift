// VLCKit Metal Shaders for video rendering
#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex shader
struct VertexInput {
      float2 position      [[attribute(0)]];
      float2 textureCoords [[attribute(1)]];
};

struct VertexOutput {
      float4 position [[position]];
      float2 textureCoords;
};

vertex VertexOutput videoVertexShader(
    VertexInput input [[stage_in]])
{
    VertexOutput output;
    output.position = float4(input.position, 0.0, 1.0);
    output.textureCoords = input.textureCoords;
    return output;
}

// MARK: - Fragment shader
fragment float4 videoFragmentShader(
    VertexOutput input [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    sampler textureSampler [[sampler(0)]])
{
    return texture.sample(textureSampler, input.textureCoords);
}

// MARK: - YUV conversion compute shaders

// YUV to RGB conversion constants
constant float3x3 yuvToRGBMatrix = float3x3(
    float3( 1.0,  1.0,  1.0),
    float3( 0.0, -0.344136,  1.772),
    float3( 1.402, -0.714136,  0.0)
);

// YUV420 / I420 to RGB compute shader
[[kernel]]
void yuv420ToRGB(
    texture2d<float> yTexture [[texture(0)]],
    texture2d<float> uTexture [[texture(1)]],
    texture2d<float> vTexture [[texture(2)]],
    texture2d<float> outputTexture [[texture(3)]],
    uint2 gid [[thread_position_in_grid]])
{
    const uint width = outputTexture.get_width();
    const uint height = outputTexture.get_height();
    
    if (gid.x >= width || gid.y >= height) return;
    
    float y = yTexture.sample(sampler(), float2(gid.x, gid.y)).r;
    float u = uTexture.sample(sampler(), float2(gid.x / 2, gid.y / 2)).r - 0.5;
    float v = vTexture.sample(sampler(), float2(gid.x / 2, gid.y / 2)).r - 0.5;
    
    float3 rgb = yuvToRGBMatrix * float3(y, u, v);
    rgb = clamp(rgb, 0.0, 1.0);
    
    outputTexture.write(float4(rgb, 1.0), gid.x, gid.y);
}

// NV12 / NV21 to RGB compute shader (single chroma texture)
[[kernel]]
void nv12ToRGB(
    texture2d<float> yTexture [[texture(0)]],
    texture2d<float> uvTexture [[texture(1)]],
    texture2d<float> outputTexture [[texture(2)]],
    uint2 gid [[thread_position_in_grid]])
{
    const uint width = outputTexture.get_width();
    const uint height = outputTexture.get_height();
    
    if (gid.x >= width || gid.y >= height) return;
    
    float y = yTexture.sample(sampler(), float2(gid.x, gid.y)).r;
    float4 uv = uvTexture.sample(sampler(), float2(gid.x / 2, gid.y / 2));
    
    float u = uv.r - 0.5;
    float v = uv.g - 0.5;
    
    float3 rgb = yuvToRGBMatrix * float3(y, u, v);
    rgb = clamp(rgb, 0.0, 1.0);
    
    outputTexture.write(float4(rgb, 1.0), gid.x, gid.y);
}

// YUVA420 to RGBA compute shader
[[kernel]]
void yuva420ToRGBA(
    texture2d<float> yTexture [[texture(0)]],
    texture2d<float> uTexture [[texture(1)]],
    texture2d<float> vTexture [[texture(2)]],
    texture2d<float> aTexture [[texture(3)]],
    texture2d<float> outputTexture [[texture(4)]],
    uint2 gid [[thread_position_in_grid]])
{
    const uint width = outputTexture.get_width();
    const uint height = outputTexture.get_height();
    
    if (gid.x >= width || gid.y >= height) return;
    
    float y = yTexture.sample(sampler(), float2(gid.x, gid.y)).r;
    float u = uTexture.sample(sampler(), float2(gid.x / 2, gid.y / 2)).r - 0.5;
    float v = vTexture.sample(sampler(), float2(gid.x / 2, gid.y / 2)).r - 0.5;
    float a = aTexture.sample(sampler(), float2(gid.x, gid.y)).r;
    
    float3 rgb = yuvToRGBMatrix * float3(y, u, v);
    rgb = clamp(rgb, 0.0, 1.0);
    
    outputTexture.write(float4(rgb, a), gid.x, gid.y);
}
