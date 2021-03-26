//
//  YXY420.metal
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#include <metal_stdlib>
using namespace metal;

struct YZYUVDataToRGBVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
    float2 textureCoordinate3 [[user(texturecoord3)]];
};


vertex YZYUVDataToRGBVertexIO YZYUVDataToRGBVertex(const device packed_float2 *position [[buffer(0)]],
                                       const device packed_float2 *texturecoord [[buffer(1)]],
                                       const device packed_float2 *texturecoord2 [[buffer(2)]],
                                       const device packed_float2 *texturecoord3 [[buffer(3)]],
                                       uint vertexID [[vertex_id]])
{
    YZYUVDataToRGBVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    outputVertices.textureCoordinate2 = texturecoord2[vertexID];
    outputVertices.textureCoordinate3 = texturecoord3[vertexID];
    
    return outputVertices;
}

fragment half4 YZYUVDataConversionFullRangeFragment(YZYUVDataToRGBVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     texture2d<half> inputTexture3 [[texture(2)]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r - (16.0/255.0);
    yuv.y = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2).r - half(0.5);
    yuv.z = inputTexture3.sample(quadSampler, fragmentInput.textureCoordinate3).r - half(0.5);

    half3x3 YZYUVDATAMAT = half3x3(half3(1.164),half3(0.0,-0.213,2.112),half3(1.793,-0.533,0.0));
    half3 rgb = YZYUVDATAMAT * yuv;
    
    return half4(rgb, 1.0);
}
