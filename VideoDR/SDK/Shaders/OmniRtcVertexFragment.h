//
//  OmniRtcVertexFragment.h
//  MetalVideoShow
//
//  Created by yanzhen on 2021/4/22.
//

#import <Foundation/Foundation.h>

const char* OmniRtcVertexFragment =
"using namespace metal;\n"

"struct OmniRtcVertexIO {\n"
"    float4 position [[position]];\n"
"    float2 textureCoordinate;\n"
"};\n"

"vertex OmniRtcVertexIO OmniRtcInputVertex(const device packed_float2 *position [[buffer(0)]], const device packed_float2 *texturecoord [[buffer(1)]], uint vertexID [[vertex_id]]) {\n"
"   OmniRtcVertexIO outputVertices;\n"
"    outputVertices.position = float4(position[vertexID], 0, 1.0);\n"
"    outputVertices.textureCoordinate = texturecoord[vertexID];\n"
"    return outputVertices;\n"
"}\n"

"fragment half4 OmniRtcFragment(OmniRtcVertexIO fragmentInput [[stage_in]], texture2d<half> inputTexture [[texture(0)]]) {\n"
"    constexpr sampler quadSampler;\n"
"    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);\n"
"    return color;\n"
"}\n";
