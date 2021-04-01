/*
 * Copyright (c) 2016 Bilibili
 * copyright (c) 2016 Zhang Rui <bbcallen@gmail.com>
 *
 * This file is part of ijkPlayer.
 *
 * ijkPlayer is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * ijkPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with ijkPlayer; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "internal.h"

#if defined(MEDIACODEC_GL_ENABLE)
static const char g_shader[] = WX_GLES_STRING(
    precision highp float;
    varying   highp vec2 vv2_Texcoord;
    attribute highp vec4 av4_Position;
    attribute highp vec2 av2_Texcoord;
    uniform         mat4 um4_ModelViewProjection;
    uniform         mat4 um4_TexMat;

    void main()
    {
        gl_Position  = um4_ModelViewProjection * av4_Position;
        vv2_Texcoord = (um4_TexMat * vec4(av2_Texcoord, 0.0, 0.0)).xy;
    }
);
#else
static const char g_shader[] = WX_GLES_STRING(
    precision highp float;
    varying   highp vec2 vv2_Texcoord;
    attribute highp vec4 av4_Position;
    attribute highp vec2 av2_Texcoord;
    uniform         mat4 um4_ModelViewProjection;

    void main()
    {
//        float  dd = 90* 3.14159265358979323846 / 180.0f;
//        mat4 rotationMatrix = mat4(cos(1.570796326794897), -sin(1.570796326794897), 0.0, 0.0,
//                               sin(1.570796326794897), cos(1.570796326794897),  0.0, 0.0,
//                               0.0,              0.0,            1.0, 0.0,
//                               0.0,              0.0,            0.0, 1.0);
//        highp vec4 temp = rotationMatrix * av4_Position;
//        gl_Position  = um4_ModelViewProjection * temp;
        gl_Position  = um4_ModelViewProjection * av4_Position;
        vv2_Texcoord = av2_Texcoord.xy;
    }
);
#endif

const char *WX_GLES2_getVertexShader_default()
{
    return g_shader;
}
