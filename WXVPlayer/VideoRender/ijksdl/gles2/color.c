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

// YUV-->RGB
#define PS_YUY2_Y           1.16438 // Both the coefficients of Y to R,G,B in 601 and 709 standards are the same

#define PS_YUY2_U_G_601     0.39176
#define PS_YUY2_U_B_601     2.01723
#define PS_YUY2_V_R_601     1.59602
#define PS_YUY2_V_G_601     0.81297

#define PS_YUY2_U_G_709     0.21325
#define PS_YUY2_U_B_709     2.11240
#define PS_YUY2_V_R_709     1.79275
#define PS_YUY2_V_G_709     0.53291

// YUV-->RGB
#define PS_YUY2_Y_FULL          1

#define PS_YUY2_U_G_601_FULL    0.34549
#define PS_YUY2_U_B_601_FULL    1.77898
#define PS_YUY2_V_R_601_FULL    1.40752
#define PS_YUY2_V_G_601_FULL    0.71695

#define PS_YUY2_U_G_709_FULL    0.18806
#define PS_YUY2_U_B_709_FULL    1.86291
#define PS_YUY2_V_R_709_FULL    1.581
#define PS_YUY2_V_G_709_FULL    0.46997

// BT.709, which is the standard for HDTV.
static const GLfloat g_bt709[] = {
    1.164,  1.164,  1.164,
    0.0,   -0.213,  2.112,
    1.793, -0.533,  0.0,
};

//static const GLfloat g_bt709[] = {
//        PS_YUY2_Y,  PS_YUY2_Y,  PS_YUY2_Y,
//        0.0,   -PS_YUY2_U_G_709,  PS_YUY2_U_B_709,
//        PS_YUY2_V_R_709, -PS_YUY2_V_G_709,  0.0,
//};

const GLfloat *WX_GLES2_getColorMatrix_bt709()
{
    return g_bt709;
}

static const GLfloat g_bt601[] = {
    1.164,  1.164, 1.164,
    0.0,   -0.392, 2.017,
    1.596, -0.813, 0.0,
};
const GLfloat *WX_GLES2_getColorMatrix_bt601()
{
    return g_bt601;
}
