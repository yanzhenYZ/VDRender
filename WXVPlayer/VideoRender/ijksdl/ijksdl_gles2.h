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

#ifndef IJKSDL__IJKSDL_GLES2_H
#define IJKSDL__IJKSDL_GLES2_H

#ifdef __APPLE__
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#else
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2platform.h>
#endif

typedef struct WX_SDL_VoutOverlay WX_SDL_VoutOverlay;

/*
 * Common
 */

#ifdef DEBUG
#define WX_GLES2_checkError_TRACE(op)
#define WX_GLES2_checkError_DEBUG(op)
#else
#define WX_GLES2_checkError_TRACE(op) WX_GLES2_checkError(op) 
#define WX_GLES2_checkError_DEBUG(op) WX_GLES2_checkError(op)
#endif

void WX_GLES2_printString(const char *name, GLenum s);
void WX_GLES2_checkError(const char *op);



GLuint WX_GLES2_loadShader(GLenum shader_type, const char *shader_source);


/*
 * Renderer
 */
#define WX_GLES2_MAX_PLANE 3
typedef struct WX_GLES2_Renderer WX_GLES2_Renderer;

//
int  WX_GLES2_Renderer_set_crop(WX_GLES2_Renderer *renderer,int x, int y,int w, int h);

WX_GLES2_Renderer *WX_GLES2_Renderer_create(WX_SDL_VoutOverlay *overlay);
void      WX_GLES2_Renderer_reset(WX_GLES2_Renderer *renderer);
void      WX_GLES2_Renderer_free(WX_GLES2_Renderer *renderer);
void      WX_GLES2_Renderer_freeP(WX_GLES2_Renderer **renderer);

GLboolean WX_GLES2_Renderer_setupGLES(void);
GLboolean WX_GLES2_Renderer_isValid(WX_GLES2_Renderer *renderer);
GLboolean WX_GLES2_Renderer_isFormat(WX_GLES2_Renderer *renderer, int format);
GLboolean WX_GLES2_Renderer_use(WX_GLES2_Renderer *renderer);
GLboolean WX_GLES2_Renderer_renderOverlay(WX_GLES2_Renderer *renderer, WX_SDL_VoutOverlay *overlay);

#define WX_GLES2_GRAVITY_RESIZE                (0) // Stretch to fill view bounds.
#define WX_GLES2_GRAVITY_RESIZE_ASPECT         (1) // Preserve aspect ratio; fit within view bounds.
#define WX_GLES2_GRAVITY_RESIZE_ASPECT_FILL    (2) // Preserve aspect ratio; fill view bounds.
GLboolean WX_GLES2_Renderer_setGravity(WX_GLES2_Renderer *renderer, int gravity, GLsizei view_width, GLsizei view_height);

#endif
