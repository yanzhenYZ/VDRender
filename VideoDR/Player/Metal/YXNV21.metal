//
//  YXNV21.metal
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#include <metal_stdlib>
using namespace metal;

struct YZYUVToRGBVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};

typedef struct//必须四个每行
{
    float3x3 colorConversionMatrix;
} YZYUVConversionUniform;

vertex YZYUVToRGBVertexIO YZYUVToRGBVertex(const device packed_float2 *position [[buffer(0)]],
                                       const device packed_float2 *texturecoord [[buffer(1)]],
                                       const device packed_float2 *texturecoord2 [[buffer(2)]],
                                       uint vertexID [[vertex_id]])
{
    YZYUVToRGBVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    outputVertices.textureCoordinate2 = texturecoord2[vertexID];

    return outputVertices;
}

fragment half4 YZYUVConversionFullRangeFragment(YZYUVToRGBVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant YZYUVConversionUniform& uniform [[ buffer(0) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r;
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).rg - half2(0.5, 0.5);

    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}

fragment half4 YZYUVConversionVideoRangeFragment(YZYUVToRGBVertexIO fragmentInput [[stage_in]],
                                              texture2d<half> inputTexture [[texture(0)]],
                                              texture2d<half> inputTexture2 [[texture(1)]],
                                              constant YZYUVConversionUniform& uniform [[ buffer(0) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r - (16.0/255.0);
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).rg - half2(0.5, 0.5);
    
    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}
