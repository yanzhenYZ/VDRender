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
#include <math.h>

void WX_GLES2_checkError(const char* op) {
    for (GLint error = glGetError(); error; error = glGetError()) {
        ALOGE("[GLES2] after %s() glError (0x%x)\n", op, error);
    }
}

void WX_GLES2_printString(const char *name, GLenum s) {
    const char *v = (const char *) glGetString(s);
    ALOGI("[GLES2] %s = %s\n", name, v);
}

void WX_GLES2_loadOrtho(WX_GLES_Matrix *matrix, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far)
{
    GLfloat r_l = right - left;
    GLfloat t_b = top - bottom;
    GLfloat f_n = far - near;
    GLfloat tx = - (right + left) / (right - left);
    GLfloat ty = - (top + bottom) / (top - bottom);
    GLfloat tz = - (far + near) / (far - near);

    matrix->m[0] = 2.0f / r_l;
    matrix->m[1] = 0.0f;
    matrix->m[2] = 0.0f;
    matrix->m[3] = 0.0f;

    matrix->m[4] = 0.0f;
    matrix->m[5] = 2.0f / t_b;
    matrix->m[6] = 0.0f;
    matrix->m[7] = 0.0f;

    matrix->m[8] = 0.0f;
    matrix->m[9] = 0.0f;
    matrix->m[10] = -2.0f / f_n;
    matrix->m[11] = 0.0f;

    matrix->m[12] = tx;
    matrix->m[13] = ty;
    matrix->m[14] = tz;
    matrix->m[15] = 1.0f;
}

void WX_GLES2_rotate(WX_GLES_Matrix *matrix, float x, float y, float z, float degree)
{
    degree = degree * M_PI / 180.0;

    float cos = cosf(degree);
    float cosp = 1.0f - cos;
    float sin = sinf(degree);
    
    matrix->m[0] = cos + cosp * x * x;
    matrix->m[4] = cosp * x * y + z * sin;
    matrix->m[8] = cosp * x * z - y * sin;
    matrix->m[12] = 0.0f;
    matrix->m[1] = cosp * x * y - z * sin;
    matrix->m[5] = cos + cosp * y * y;
    matrix->m[9] = cosp * y * z + x * sin;
    matrix->m[13] = 0.0f;
    matrix->m[2] = cosp * x * z + y * sin;
    matrix->m[6] = cosp * y * z - x * sin;
    matrix->m[10] = cos + cosp * z * z;
    matrix->m[14] = 0.0f;
    matrix->m[3] = 0.0f;
    matrix->m[7] = 0.0f;
    matrix->m[11] = 0.0f;
    matrix->m[15] = 1.0f;
}

void WX_GLES2_matrixMultiple(WX_GLES_Matrix *matrixLeft, WX_GLES_Matrix *matrixRight)
{
    WX_GLES_Matrix tmpMatrix;
    for(int i = 0; i < 16; ++i)
    {
        tmpMatrix.m[i] = 0.0;
    }
    
    //
    tmpMatrix.m[0] =
    matrixLeft->m[0] * matrixRight->m[0] +
    matrixLeft->m[4] * matrixRight->m[1] +
    matrixLeft->m[8] * matrixRight->m[2] +
    matrixLeft->m[12] * matrixRight->m[3];
    
    tmpMatrix.m[1] =
    matrixLeft->m[1] * matrixRight->m[0] +
    matrixLeft->m[5] * matrixRight->m[1] +
    matrixLeft->m[9] * matrixRight->m[2] +
    matrixLeft->m[13] * matrixRight->m[3];
    
    tmpMatrix.m[2] =
    matrixLeft->m[2] * matrixRight->m[0] +
    matrixLeft->m[6] * matrixRight->m[1] +
    matrixLeft->m[10] * matrixRight->m[2] +
    matrixLeft->m[14] * matrixRight->m[3];
    
    tmpMatrix.m[3] =
    matrixLeft->m[3] * matrixRight->m[0] +
    matrixLeft->m[7] * matrixRight->m[1] +
    matrixLeft->m[11] * matrixRight->m[2] +
    matrixLeft->m[15] * matrixRight->m[3];
    
    //
    tmpMatrix.m[4] =
    matrixLeft->m[0] * matrixRight->m[4] +
    matrixLeft->m[4] * matrixRight->m[5] +
    matrixLeft->m[8] * matrixRight->m[6] +
    matrixLeft->m[12] * matrixRight->m[7];
    
    tmpMatrix.m[5] =
    matrixLeft->m[1] * matrixRight->m[4] +
    matrixLeft->m[5] * matrixRight->m[5] +
    matrixLeft->m[9] * matrixRight->m[6] +
    matrixLeft->m[13] * matrixRight->m[7];
    
    tmpMatrix.m[6] =
    matrixLeft->m[2] * matrixRight->m[4] +
    matrixLeft->m[6] * matrixRight->m[5] +
    matrixLeft->m[10] * matrixRight->m[6] +
    matrixLeft->m[14] * matrixRight->m[7];
    
    tmpMatrix.m[7] =
    matrixLeft->m[3] * matrixRight->m[4] +
    matrixLeft->m[7] * matrixRight->m[5] +
    matrixLeft->m[11] * matrixRight->m[6] +
    matrixLeft->m[15] * matrixRight->m[7];
    
    //
    tmpMatrix.m[8] =
    matrixLeft->m[0] * matrixRight->m[8] +
    matrixLeft->m[4] * matrixRight->m[9] +
    matrixLeft->m[8] * matrixRight->m[10] +
    matrixLeft->m[12] * matrixRight->m[11];
    
    tmpMatrix.m[9] =
    matrixLeft->m[1] * matrixRight->m[8] +
    matrixLeft->m[5] * matrixRight->m[9] +
    matrixLeft->m[9] * matrixRight->m[10] +
    matrixLeft->m[13] * matrixRight->m[11];
    
    tmpMatrix.m[10] =
    matrixLeft->m[2] * matrixRight->m[8] +
    matrixLeft->m[6] * matrixRight->m[9] +
    matrixLeft->m[10] * matrixRight->m[10] +
    matrixLeft->m[14] * matrixRight->m[11];
    
    tmpMatrix.m[11] =
    matrixLeft->m[3] * matrixRight->m[8] +
    matrixLeft->m[7] * matrixRight->m[9] +
    matrixLeft->m[11] * matrixRight->m[10] +
    matrixLeft->m[15] * matrixRight->m[11];
    
    //
    tmpMatrix.m[12] =
    matrixLeft->m[0] * matrixRight->m[12] +
    matrixLeft->m[4] * matrixRight->m[13] +
    matrixLeft->m[8] * matrixRight->m[14] +
    matrixLeft->m[12] * matrixRight->m[15];
    
    tmpMatrix.m[13] =
    matrixLeft->m[1] * matrixRight->m[12] +
    matrixLeft->m[5] * matrixRight->m[13] +
    matrixLeft->m[9] * matrixRight->m[14] +
    matrixLeft->m[13] * matrixRight->m[15];
    
    tmpMatrix.m[14] =
    matrixLeft->m[2] * matrixRight->m[12] +
    matrixLeft->m[6] * matrixRight->m[13] +
    matrixLeft->m[10] * matrixRight->m[14] +
    matrixLeft->m[14] * matrixRight->m[15];
    
    tmpMatrix.m[15] =
    matrixLeft->m[3] * matrixRight->m[12] +
    matrixLeft->m[7] * matrixRight->m[13] +
    matrixLeft->m[11] * matrixRight->m[14] +
    matrixLeft->m[15] * matrixRight->m[15];
    
    for(int i = 0; i < 16; ++i)
    {
        matrixLeft->m[i] = tmpMatrix.m[i];
    }
}
