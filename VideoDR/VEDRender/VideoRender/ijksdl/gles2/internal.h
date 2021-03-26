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

#ifndef IJKSDL__IJKSDL_GLES2__INTERNAL__H
#define IJKSDL__IJKSDL_GLES2__INTERNAL__H

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "ijksdl_fourcc.h"
#include "ijksdl_log.h"
#include "ijksdl_vout.h"
#include "ijksdl_gles2.h"

#define WX_GLES_STRINGIZE(x)   #x
#define WX_GLES_STRINGIZE2(x)  WX_GLES_STRINGIZE(x)
#define WX_GLES_STRING(x)      WX_GLES_STRINGIZE2(x)

typedef struct WX_GLES2_ViewPort
{
    int x;
    int y;
    int width;
    int height;
} WX_GLES2_ViewPort;

typedef struct WX_GLES2_Renderer
{
    GLuint program;

    GLuint vertex_shader;
    GLuint fragment_shader;
    GLuint plane_textures[WX_GLES2_MAX_PLANE];

    GLuint av4_position;
    GLuint av2_texcoord;
    GLuint um4_mvp;
    GLuint um4_texM;

    GLuint us2_sampler[WX_GLES2_MAX_PLANE];
    GLuint um3_color_conversion;

    GLboolean (*func_use)(WX_GLES2_Renderer *renderer);
    GLsizei   (*func_getBufferWidth)(WX_GLES2_Renderer *renderer, WX_SDL_VoutOverlay *overlay);
    GLboolean (*func_uploadTexture)(WX_GLES2_Renderer *renderer, WX_SDL_VoutOverlay *overlay);
    GLvoid    (*func_destroy)(WX_GLES2_Renderer *renderer);

    GLsizei buffer_width;
    GLsizei visible_width;

    GLfloat texcoords[8];

    GLfloat vertices[8];
    int     vertices_changed;

    int     format;
    int     gravity;
    GLsizei layer_width;
    GLsizei layer_height;
    int     frame_width;
    int     frame_height;
    int     frame_sar_num;
    int     frame_sar_den;
    
    bool    crop_flag;
    int     crop_pos_x;
    int     crop_pos_y;
    int     crop_width;
    int     crop_height;

    GLsizei last_buffer_width;
    
    int     rotation;
    
    WX_GLES2_ViewPort   view_port;

#if defined(MEDIACODEC_GL_ENABLE)
    // oes
    GLuint oes_texture;
    GLfloat *texMatrix;
    GLboolean texMatrixUploaded;
#endif
} WX_GLES2_Renderer;

typedef struct WX_GLES_Matrix
{
    GLfloat m[16];
} WX_GLES_Matrix;
void WX_GLES2_loadOrtho(WX_GLES_Matrix *matrix, GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far);
void WX_GLES2_rotate(WX_GLES_Matrix *matrix, float x, float y, float z, float degree);
void WX_GLES2_matrixMultiple(WX_GLES_Matrix *matrixLeft, WX_GLES_Matrix *matrixRight);

const char *WX_GLES2_getVertexShader_default(void);
const char *WX_GLES2_getFragmentShader_yuv420p(void);
const char *WX_GLES2_getFragmentShader_yuv444p10le(void);
const char *WX_GLES2_getFragmentShader_yuv420sp(void);
const char *WX_GLES2_getFragmentShader_rgb(void);

const GLfloat *WX_GLES2_getColorMatrix_bt709(void);
const GLfloat *WX_GLES2_getColorMatrix_bt601(void);

WX_GLES2_Renderer *WX_GLES2_Renderer_create_base(const char *fragment_shader_source);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_yuv420p(void);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_yuv444p10le(void);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_yuv420sp(void);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_yuv420sp_vtb(WX_SDL_VoutOverlay *overlay);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_rgb565(void);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_rgb888(void);
WX_GLES2_Renderer *WX_GLES2_Renderer_create_rgbx8888(void);

int WX_GLES2_crop(WX_GLES_Matrix *matrix, WX_GLES2_Renderer * render);
int WX_GLES2_view(WX_GLES2_Renderer *renderer);

#if defined(MEDIACODEC_GL_ENABLE)
const char *WX_GLES2_getFragmentShader_rgb_OES();
WX_GLES2_Renderer *WX_GLES2_Renderer_create_OES_rgbx8888();
#endif

#endif
