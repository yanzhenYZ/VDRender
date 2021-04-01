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


#define FFMAX(a,b) ((a) > (b) ? (a) : (b))
#define FFMAX3(a,b,c) FFMAX(FFMAX(a,b),c)
#define FFMIN(a,b) ((a) > (b) ? (b) : (a))
#define FFMIN3(a,b,c) FFMIN(FFMIN(a,b),c)

static void WX_GLES2_printProgramInfo(GLuint program)
{
    if (!program)
        return;

    GLint info_len = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &info_len);
    if (!info_len) {
        ALOGE("[GLES2][Program] empty info\n");
        return;
    }

    char    buf_stack[32];
    char   *buf_heap = NULL;
    char   *buf      = buf_stack;
    GLsizei buf_len  = sizeof(buf_stack) - 1;
    if (info_len > sizeof(buf_stack)) {
        buf_heap = (char*) malloc(info_len + 1);
        if (buf_heap) {
            buf     = buf_heap;
            buf_len = info_len;
        }
    }

    glGetProgramInfoLog(program, buf_len, NULL, buf);
    ALOGE("[GLES2][Program] error %s\n", buf);

    if (buf_heap)
        free(buf_heap);
}

void WX_GLES2_Renderer_reset(WX_GLES2_Renderer *renderer)
{
    if (!renderer)
        return;

    if (renderer->vertex_shader)
        glDeleteShader(renderer->vertex_shader);
    if (renderer->fragment_shader)
        glDeleteShader(renderer->fragment_shader);
    if (renderer->program)
        glDeleteProgram(renderer->program);

    renderer->vertex_shader   = 0;
    renderer->fragment_shader = 0;
    renderer->program         = 0;

    for (int i = 0; i < WX_GLES2_MAX_PLANE; ++i) {
        if (renderer->plane_textures[i]) {
            glDeleteTextures(1, &renderer->plane_textures[i]);
            renderer->plane_textures[i] = 0;
        }
    }
#if defined(MEDIACODEC_GL_ENABLE)
    if(renderer->oes_texture)
    {
        glDeleteTextures(1, &renderer->oes_texture);
        renderer->oes_texture = 0;
    }
#endif
}

void WX_GLES2_Renderer_free(WX_GLES2_Renderer *renderer)
{
    if (!renderer)
        return;

    if (renderer->func_destroy)
        renderer->func_destroy(renderer);

#if 0
    if (renderer->vertex_shader)    ALOGW("[GLES2] renderer: vertex_shader not deleted.\n");
    if (renderer->fragment_shader)  ALOGW("[GLES2] renderer: fragment_shader not deleted.\n");
    if (renderer->program)          ALOGW("[GLES2] renderer: program not deleted.\n");

    for (int i = 0; i < WX_GLES2_MAX_PLANE; ++i) {
        if (renderer->plane_textures[i])
            ALOGW("[GLES2] renderer: plane texture[%d] not deleted.\n", i);
    }
#endif

#if defined(MEDIACODEC_GL_ENABLE)
    if(renderer->texMatrix)
    {
        free(renderer->texMatrix);
        renderer->texMatrix = NULL;
    }
#endif
    free(renderer);
}

void WX_GLES2_Renderer_freeP(WX_GLES2_Renderer **renderer)
{
    if (!renderer || !*renderer)
        return;

    WX_GLES2_Renderer_reset(*renderer);
    WX_GLES2_Renderer_free(*renderer);
    *renderer = NULL;
    glFinish();
}

WX_GLES2_Renderer *WX_GLES2_Renderer_create_base(const char *fragment_shader_source)
{
    assert(fragment_shader_source);

    WX_GLES2_Renderer *renderer = (WX_GLES2_Renderer *)calloc(1, sizeof(WX_GLES2_Renderer));
    if (!renderer)
        goto fail;

    renderer->vertex_shader = WX_GLES2_loadShader(GL_VERTEX_SHADER, WX_GLES2_getVertexShader_default());
    if (!renderer->vertex_shader)
        goto fail;

    renderer->fragment_shader = WX_GLES2_loadShader(GL_FRAGMENT_SHADER, fragment_shader_source);
    if (!renderer->fragment_shader)
        goto fail;

    renderer->program = glCreateProgram();                          WX_GLES2_checkError("glCreateProgram");
    if (!renderer->program)
        goto fail;

    glAttachShader(renderer->program, renderer->vertex_shader);     WX_GLES2_checkError("glAttachShader(vertex)");
    glAttachShader(renderer->program, renderer->fragment_shader);   WX_GLES2_checkError("glAttachShader(fragment)");
    glLinkProgram(renderer->program);                               WX_GLES2_checkError("glLinkProgram");
    GLint link_status = GL_FALSE;
    glGetProgramiv(renderer->program, GL_LINK_STATUS, &link_status);
    if (!link_status)
        goto fail;


    renderer->av4_position = glGetAttribLocation(renderer->program, "av4_Position");                WX_GLES2_checkError_TRACE("glGetAttribLocation(av4_Position)");
    renderer->av2_texcoord = glGetAttribLocation(renderer->program, "av2_Texcoord");                WX_GLES2_checkError_TRACE("glGetAttribLocation(av2_Texcoord)");
    renderer->um4_mvp      = glGetUniformLocation(renderer->program, "um4_ModelViewProjection");    WX_GLES2_checkError_TRACE("glGetUniformLocation(um4_ModelViewProjection)");

#if defined(MEDIACODEC_GL_ENABLE)
    renderer->um4_texM     = glGetUniformLocation(renderer->program, "um4_TexMat");    WX_GLES2_checkError_TRACE("glGetUniformLocation(um4_TexMat)");
    renderer->texMatrix = NULL;
    renderer->texMatrixUploaded = false;
#endif
    return renderer;

fail:

    if (renderer && renderer->program)
        WX_GLES2_printProgramInfo(renderer->program);

    WX_GLES2_Renderer_free(renderer);
    return NULL;
}


WX_GLES2_Renderer *WX_GLES2_Renderer_create(WX_SDL_VoutOverlay *overlay)
{
    if (!overlay)
        return NULL;

    WX_GLES2_printString("Version", GL_VERSION);
    WX_GLES2_printString("Vendor", GL_VENDOR);
    WX_GLES2_printString("Renderer", GL_RENDERER);
    WX_GLES2_printString("Extensions", GL_EXTENSIONS);

    WX_GLES2_Renderer *renderer = NULL;
    switch (overlay->format) {
        case SDL_FCC_RV16:      renderer = WX_GLES2_Renderer_create_rgb565(); break;
        case SDL_FCC_RV24:      renderer = WX_GLES2_Renderer_create_rgb888(); break;
        case SDL_FCC_RV32:      renderer = WX_GLES2_Renderer_create_rgbx8888(); break;
#ifdef __APPLE__
        case SDL_FCC_NV12:      renderer = WX_GLES2_Renderer_create_yuv420sp(); break;
        case SDL_FCC__VTB:
        {
//            renderer = WX_GLES2_Renderer_create_yuv420sp_vtb(overlay);
//            if(renderer == NULL)
//            {
//                renderer = WX_GLES2_Renderer_create_yuv420sp();
//            }
        }
            break;
#endif
        case SDL_FCC_YV12:      renderer = WX_GLES2_Renderer_create_yuv420p(); break;
        case SDL_FCC_I420:      renderer = WX_GLES2_Renderer_create_yuv420p(); break;
        case SDL_FCC_I444P10LE: renderer = WX_GLES2_Renderer_create_yuv444p10le(); break;
#if defined(MEDIACODEC_GL_ENABLE)
        case SDL_FCC__AMC:      renderer = WX_GLES2_Renderer_create_OES_rgbx8888(); break;
#endif
        default:
            ALOGE("[GLES2] unknown format %4s(%d)\n", (char *)&overlay->format, overlay->format);
            return NULL;
    }

    if(renderer)
    {
        renderer->format = overlay->format;
    }
    return renderer;
}

GLboolean WX_GLES2_Renderer_isValid(WX_GLES2_Renderer *renderer)
{
    return renderer && renderer->program ? GL_TRUE : GL_FALSE;
}

GLboolean WX_GLES2_Renderer_isFormat(WX_GLES2_Renderer *renderer, int format)
{
    if (!WX_GLES2_Renderer_isValid(renderer))
        return GL_FALSE;

    return renderer->format == format ? GL_TRUE : GL_FALSE;
}

/*
 * Per-Context routine
 */
GLboolean WX_GLES2_Renderer_setupGLES()
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);       WX_GLES2_checkError_TRACE("glClearColor");
    glEnable(GL_CULL_FACE);                     WX_GLES2_checkError_TRACE("glEnable(GL_CULL_FACE)");
    glCullFace(GL_BACK);                        WX_GLES2_checkError_TRACE("glCullFace");
    glDisable(GL_DEPTH_TEST);

    return GL_TRUE;
}

static void WX_GLES2_Renderer_Vertices_reset(WX_GLES2_Renderer *renderer)
{
    renderer->vertices[0] = -1.0f;
    renderer->vertices[1] = -1.0f;
    renderer->vertices[2] =  1.0f;
    renderer->vertices[3] = -1.0f;
    renderer->vertices[4] = -1.0f;
    renderer->vertices[5] =  1.0f;
    renderer->vertices[6] =  1.0f;
    renderer->vertices[7] =  1.0f;
}

static void WX_GLES2_Renderer_Vertices_apply(WX_GLES2_Renderer *renderer)
{
    switch (renderer->gravity) {
        case WX_GLES2_GRAVITY_RESIZE_ASPECT:
            break;
        case WX_GLES2_GRAVITY_RESIZE_ASPECT_FILL:
            break;
        case WX_GLES2_GRAVITY_RESIZE:
            WX_GLES2_Renderer_Vertices_reset(renderer);
            return;
        default:
            ALOGE("[GLES2] unknown gravity %d\n", renderer->gravity);
            WX_GLES2_Renderer_Vertices_reset(renderer);
            return;
    }

    if (renderer->layer_width <= 0 ||
        renderer->layer_height <= 0 ||
        renderer->frame_width <= 0 ||
        renderer->frame_height <= 0)
    {
        ALOGE("[GLES2] invalid width/height for gravity aspect\n");
        WX_GLES2_Renderer_Vertices_reset(renderer);
        return;
    }
}

static void WX_GLES2_Renderer_Vertices_reloadVertex(WX_GLES2_Renderer *renderer)
{
    glVertexAttribPointer(renderer->av4_position, 2, GL_FLOAT, GL_FALSE, 0, renderer->vertices);    WX_GLES2_checkError_TRACE("glVertexAttribPointer(av2_texcoord)");
    glEnableVertexAttribArray(renderer->av4_position);                                      WX_GLES2_checkError_TRACE("glEnableVertexAttribArray(av2_texcoord)");
}

#define WX_GLES2_GRAVITY_MIN                   (0)
#define WX_GLES2_GRAVITY_RESIZE                (0) // Stretch to fill layer bounds.
#define WX_GLES2_GRAVITY_RESIZE_ASPECT         (1) // Preserve aspect ratio; fit within layer bounds.
#define WX_GLES2_GRAVITY_RESIZE_ASPECT_FILL    (2) // Preserve aspect ratio; fill layer bounds.
#define WX_GLES2_GRAVITY_MAX                   (2)

GLboolean WX_GLES2_Renderer_setGravity(WX_GLES2_Renderer *renderer, int gravity, GLsizei layer_width, GLsizei layer_height)
{
    if (renderer->gravity != gravity && gravity >= WX_GLES2_GRAVITY_MIN && gravity <= WX_GLES2_GRAVITY_MAX)
        renderer->vertices_changed = 1;
    else if (renderer->layer_width != layer_width)
        renderer->vertices_changed = 1;
    else if (renderer->layer_height != layer_height)
        renderer->vertices_changed = 1;
    else
        return GL_TRUE;

    renderer->gravity      = gravity;
    renderer->layer_width  = layer_width;
    renderer->layer_height = layer_height;
    return GL_TRUE;
}

static void WX_GLES2_Renderer_TexCoords_reset(WX_GLES2_Renderer *renderer)
{
    renderer->texcoords[0] = 0.0f;
    renderer->texcoords[1] = 1.0f;
    renderer->texcoords[2] = 1.0f;
    renderer->texcoords[3] = 1.0f;
    renderer->texcoords[4] = 0.0f;
    renderer->texcoords[5] = 0.0f;
    renderer->texcoords[6] = 1.0f;
    renderer->texcoords[7] = 0.0f;
}

static void WX_GLES2_Renderer_TexCoords_cropRight(WX_GLES2_Renderer *renderer, GLfloat cropRight)
{
    ALOGE("WX_GLES2_Renderer_TexCoords_cropRight\n");
    renderer->texcoords[0] = 0.0f;
    renderer->texcoords[1] = 1.0f;
    renderer->texcoords[2] = 1.0f - cropRight;
    renderer->texcoords[3] = 1.0f;
    renderer->texcoords[4] = 0.0f;
    renderer->texcoords[5] = 0.0f;
    renderer->texcoords[6] = 1.0f - cropRight;
    renderer->texcoords[7] = 0.0f;
}

static void WX_GLES2_Renderer_TexCoords_reloadVertex(WX_GLES2_Renderer *renderer)
{
    glVertexAttribPointer(renderer->av2_texcoord, 2, GL_FLOAT, GL_FALSE, 0, renderer->texcoords);   WX_GLES2_checkError_TRACE("glVertexAttribPointer(av2_texcoord)");
    glEnableVertexAttribArray(renderer->av2_texcoord);                                              WX_GLES2_checkError_TRACE("glEnableVertexAttribArray(av2_texcoord)");
}

/*
 * Per-Renderer routine
 */
GLboolean WX_GLES2_Renderer_use(WX_GLES2_Renderer *renderer)
{
    if (!renderer)
        return GL_FALSE;

    assert(renderer->func_use);
    if (!renderer->func_use(renderer))
        return GL_FALSE;

    WX_GLES_Matrix modelViewProj;
    WX_GLES2_loadOrtho(&modelViewProj, -1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f);

    glUniformMatrix4fv(renderer->um4_mvp, 1, GL_FALSE, modelViewProj.m);
    WX_GLES2_checkError_TRACE("glUniformMatrix4fv(um4_mvp)");
#if defined(MEDIACODEC_GL_ENABLE)
    float texmat[16] = {1.0, 0.0, 0.0, 0.0,
                        0.0, 1.0, 0.0, 0.0,
                        0.0, 0.0, 1.0, 0.0,
                        0.0, 0.0, 0.0, 1.0};
    if(renderer->texMatrix)
    {
        glUniformMatrix4fv(renderer->um4_texM, 1, GL_FALSE, renderer->texMatrix);
        WX_GLES2_checkError_TRACE("glUniformMatrix4fv(um4_mvp)");
        renderer->texMatrixUploaded = true;
    }
    else
    {
        glUniformMatrix4fv(renderer->um4_texM, 1, GL_FALSE, texmat);
        WX_GLES2_checkError_TRACE("glUniformMatrix4fv(um4_mvp)");
    }
#endif

    WX_GLES2_Renderer_TexCoords_reset(renderer);
    WX_GLES2_Renderer_TexCoords_reloadVertex(renderer);

    WX_GLES2_Renderer_Vertices_reset(renderer);
    WX_GLES2_Renderer_Vertices_reloadVertex(renderer);

    return GL_TRUE;
}

/*
 * Per-Frame routine
 */
GLboolean WX_GLES2_Renderer_renderOverlay(WX_GLES2_Renderer *renderer, WX_SDL_VoutOverlay *overlay)
{
    if (!renderer || !renderer->func_uploadTexture)
        return GL_FALSE;

    glClear(GL_COLOR_BUFFER_BIT);               WX_GLES2_checkError_TRACE("glClear");

    GLsizei visible_width  = renderer->frame_width;
    GLsizei visible_height = renderer->frame_height;
    if (overlay) {
        visible_width  = overlay->w;
        visible_height = overlay->h;
        if (renderer->frame_width   != visible_width    ||
            renderer->frame_height  != visible_height   ||
            renderer->frame_sar_num != overlay->sar_num ||
            renderer->frame_sar_den != overlay->sar_den) {

            renderer->frame_width   = visible_width;
            renderer->frame_height  = visible_height;
            renderer->frame_sar_num = overlay->sar_num;
            renderer->frame_sar_den = overlay->sar_den;

            renderer->vertices_changed = 1;
        }

        renderer->last_buffer_width = renderer->func_getBufferWidth(renderer, overlay);

        if (!renderer->func_uploadTexture(renderer, overlay))
            return GL_FALSE;
    } else {
        // NULL overlay means force reload vertice
        renderer->vertices_changed = 1;
    }
    
    // rotate/crop
    if(overlay && ((renderer->rotation != overlay->rotation) || renderer->crop_flag))
    {
        renderer->rotation = overlay->rotation;

        WX_GLES_Matrix modelViewProj;
        memset((void *)modelViewProj.m, 0, sizeof(GLfloat) * 16);
        modelViewProj.m[0] = modelViewProj.m[5] = modelViewProj.m[10] = modelViewProj.m[15] = 1.0f;
        WX_GLES2_crop(&modelViewProj, renderer);
        
//        WX_GLES2_matrixMultiple(&viewMatrix, &modelViewProj);
        
        WX_GLES_Matrix rotateMatrix;
        memset((void *)rotateMatrix.m, 0, sizeof(GLfloat) * 16);
        rotateMatrix.m[0] = rotateMatrix.m[5] = rotateMatrix.m[10] = rotateMatrix.m[15] = 1.0f;
        WX_GLES2_rotate(&rotateMatrix, 0.0, 0.0, 1.0, renderer->rotation);
        
        WX_GLES2_matrixMultiple(&modelViewProj, &rotateMatrix);
        
        glUniformMatrix4fv(renderer->um4_mvp, 1, GL_FALSE, modelViewProj.m);
        WX_GLES2_checkError_TRACE("glUniformMatrix4fv(um4_mvp)");
        
        renderer->crop_flag = false;
    }
    
    WX_GLES2_view(renderer);

    GLsizei buffer_width = renderer->last_buffer_width;
    if (renderer->vertices_changed ||
        (buffer_width > 0 &&
         buffer_width > visible_width &&
         buffer_width != renderer->buffer_width &&
         visible_width != renderer->visible_width)){

        renderer->vertices_changed = 0;

//        WX_GLES2_Renderer_Vertices_apply(renderer);
        WX_GLES2_Renderer_Vertices_reset(renderer);
        WX_GLES2_Renderer_Vertices_reloadVertex(renderer);

        renderer->buffer_width  = buffer_width;
        renderer->visible_width = visible_width;

        GLsizei padding_pixels     = buffer_width - visible_width;
        GLfloat padding_normalized = ((GLfloat)padding_pixels) / buffer_width;

        WX_GLES2_Renderer_TexCoords_reset(renderer);
        WX_GLES2_Renderer_TexCoords_cropRight(renderer, padding_normalized);
        WX_GLES2_Renderer_TexCoords_reloadVertex(renderer);
    }

#if defined(MEDIACODEC_GL_ENABLE)
    if((overlay->format == SDL_FCC__AMC) && renderer->texMatrix && !renderer->texMatrixUploaded)
    {
        glUniformMatrix4fv(renderer->um4_texM, 1, GL_FALSE, renderer->texMatrix);
        WX_GLES2_checkError_TRACE("glUniformMatrix4fv(um4_texM)");
        renderer->texMatrixUploaded = true;
    }
#endif
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);      WX_GLES2_checkError_TRACE("glDrawArrays");

    return GL_TRUE;
}


int WX_GLES2_Renderer_set_crop(WX_GLES2_Renderer *renderer,int x,int y,int w,int h)
{
    if(!renderer){
        return -1;
    }
    
    if(w == 0 || h == 0)
    {
        return -1;
    }
    
    renderer->crop_flag = true;
    renderer->crop_pos_x = x;
    renderer->crop_pos_y = y;
    renderer->crop_width = w;
    renderer->crop_height = h;
    return 0;
}


int WX_GLES2_crop(WX_GLES_Matrix *matrix, WX_GLES2_Renderer * render){
    if(!matrix || !render){
        return -1;
    }
    
    if(render->crop_flag == false){
        return -1;
    }
    if(render->crop_width <= 0 || render->crop_height * render->crop_height <= 0){
        return -1;
    }
    
    bool needRotate = (render->rotation == 90 || render->rotation == 270);
    
    float width = (needRotate) ? render->frame_height / 2.0 : render->frame_width / 2.0;
    float height = (needRotate) ? render->frame_width / 2.0 : render->frame_height / 2.0;
    float left = (render->crop_pos_x - width) / width;
    float right = (render->crop_pos_x + render->crop_width - width) / width;
    float top = -(render->crop_pos_y - height) / height;
    float bottom = -(render->crop_pos_y + render->crop_height - height) / height;

    WX_GLES2_loadOrtho(matrix, left, right, bottom, top, 0, 5.0);

    return 0;
}

int WX_GLES2_view(WX_GLES2_Renderer *renderer)
{
    if(renderer->gravity == WX_GLES2_GRAVITY_RESIZE)
    {
        glViewport(0, 0, renderer->layer_width, renderer->layer_height);
        return 0;
    }
    
    if(renderer->vertices_changed)
    {
        float width     = (renderer->rotation == 90 || renderer->rotation == 270) ? renderer->frame_height : renderer->frame_width;
        float height    = (renderer->rotation == 90 || renderer->rotation == 270) ? renderer->frame_width : renderer->frame_height;
        
        if(renderer->crop_width != 0 && renderer->crop_height != 0)
        {
            width = renderer->crop_width;
            height = renderer->crop_height;
        }
        
        if (renderer->frame_sar_num > 0 && renderer->frame_sar_den > 0) {
            width = width * renderer->frame_sar_num / renderer->frame_sar_den;
        }
        
        const float dW  = (float)renderer->layer_width / width;
        const float dH  = (float)renderer->layer_height / height;
        float dd        = 1.0f;
        float nW        = 1.0f;
        float nH        = 1.0f;
        
        switch (renderer->gravity) {
            case WX_GLES2_GRAVITY_RESIZE_ASPECT_FILL:  dd = FFMAX(dW, dH); break;
            case WX_GLES2_GRAVITY_RESIZE_ASPECT:       dd = FFMIN(dW, dH); break;
        }
        
        nW = (width  * dd / (float)renderer->layer_width);
        nH = (height * dd / (float)renderer->layer_height);
        
        renderer->view_port.x = (1.0 - nW) / 2.0 * renderer->layer_width;
        renderer->view_port.y = (1.0 - nH) / 2.0 * renderer->layer_height;
        renderer->view_port.width = renderer->layer_width * nW;
        renderer->view_port.height = renderer->layer_height * nH;
    }
    
    glViewport(renderer->view_port.x, renderer->view_port.y,
               renderer->view_port.width, renderer->view_port.height);
    
    return 0;
}
