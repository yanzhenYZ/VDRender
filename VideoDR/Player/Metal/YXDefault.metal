//
//  YXDefault.metal
//  VideoDR
//
//  Created by yanzhen on 2021/3/25.
//

#include <metal_stdlib>
using namespace metal;

struct YZVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex YZVertexIO YZInputVertex(const device packed_float2 *position [[buffer(0)]], const device packed_float2 *texturecoord [[buffer(1)]], uint vertexID [[vertex_id]])
{
    YZVertexIO outputVertices;
    
    outputVertices.position = float4(position[vertexID], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vertexID];
    
    return outputVertices;
}

fragment half4 YZFragment(YZVertexIO fragmentInput [[stage_in]], texture2d<half> inputTexture [[texture(0)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    return color;
}
