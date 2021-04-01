/*****************************************************************************
 * ijksdl_log.h
 *****************************************************************************
 *
 * Copyright (c) 2015 Bilibili
 * copyright (c) 2015 Zhang Rui <bbcallen@gmail.com>
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

#ifndef IJKSDL__IJKSDL_LOG_H
#define IJKSDL__IJKSDL_LOG_H

#include <stdio.h>

#ifdef __cplusplus

extern "C"{
#endif

#ifdef __ANDROID__

#include <android/log.h>
//#include "ijksdl_extra_log.h"

#define WX_LOG_UNKNOWN     ANDROID_LOG_UNKNOWN
#define WX_LOG_DEFAULT     ANDROID_LOG_DEFAULT

#define WX_LOG_VERBOSE     ANDROID_LOG_VERBOSE
#define WX_LOG_DEBUG       ANDROID_LOG_DEBUG
#define WX_LOG_INFO        ANDROID_LOG_INFO
#define WX_LOG_WARN        ANDROID_LOG_WARN
#define WX_LOG_ERROR       ANDROID_LOG_ERROR
#define WX_LOG_FATAL       ANDROID_LOG_FATAL
#define WX_LOG_SILENT      ANDROID_LOG_SILENT

#ifdef EXTRA_LOG_PRINT
#define VLOG(level, TAG, ...)    ffp_log_extra_vprint(level, TAG, __VA_ARGS__)
#define ALOG(level, TAG, ...)    ffp_log_extra_print(level, TAG, __VA_ARGS__)
#else
#define VLOG(level, TAG, ...)    ((void)__android_log_vprint(level, TAG, __VA_ARGS__))
#define ALOG(level, TAG, ...)    ((void)__android_log_print(level, TAG, __VA_ARGS__))
#define PSLOG(...)               ((void)__android_log_print(ANDROID_LOG_DEBUG, "PSPlayer", __VA_ARGS__))
#endif

#elif defined(__APPLE__) && !defined(MACH_PC)

#define IOS_LOG_LENGTH 2048

#define WX_LOG_UNKNOWN     0
#define WX_LOG_DEFAULT     1

#define WX_LOG_VERBOSE     2
#define WX_LOG_DEBUG       3
#define WX_LOG_INFO        4
#define WX_LOG_WARN        5
#define WX_LOG_ERROR       6
#define WX_LOG_FATAL       7
#define WX_LOG_SILENT      8



#define VLOG(level, TAG, fmt, args...)
#define ALOG(level, TAG, fmt, args...)
#define ALLOG(level, TAG, fmt, args...)
#define PSLOG(fmt, args...)


//#define VLOG(level, TAG, ...)    ((void)vprintf(__VA_ARGS__))
//#define ALOG(level, TAG, ...)    ((void)printf(__VA_ARGS__))
//#define ALLOG(level, TAG, ...)    ((void)printf(__VA_ARGS__))

#else

#define WX_LOG_UNKNOWN     0
#define WX_LOG_DEFAULT     1

#define WX_LOG_VERBOSE     2
#define WX_LOG_DEBUG       3
#define WX_LOG_INFO        4
#define WX_LOG_WARN        5
#define WX_LOG_ERROR       6
#define WX_LOG_FATAL       7
#define WX_LOG_SILENT      8

#define VLOG(level, TAG, ...)    ((void)vprintf(__VA_ARGS__))
#define ALOG(level, TAG, ...)    ((void)printf(__VA_ARGS__))

#endif

#define WX_LOG_TAG "WXMEDIA"

#define VLOGV(...)  VLOG(WX_LOG_VERBOSE,   WX_LOG_TAG, __VA_ARGS__)
#define VLOGD(...)  VLOG(WX_LOG_DEBUG,     WX_LOG_TAG, __VA_ARGS__)
#define VLOGI(...)  VLOG(WX_LOG_INFO,      WX_LOG_TAG, __VA_ARGS__)
#define VLOGW(...)  VLOG(WX_LOG_WARN,      WX_LOG_TAG, __VA_ARGS__)
#define VLOGE(...)  VLOG(WX_LOG_ERROR,     WX_LOG_TAG, __VA_ARGS__)

#define ALOGV(...)  ALOG(WX_LOG_VERBOSE,   WX_LOG_TAG, __VA_ARGS__)
#define ALOGD(...)  ALOG(WX_LOG_DEBUG,     WX_LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  ALOG(WX_LOG_INFO,      WX_LOG_TAG, __VA_ARGS__)
#define ALOGW(...)  ALOG(WX_LOG_WARN,      WX_LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  ALOG(WX_LOG_ERROR,     WX_LOG_TAG, __VA_ARGS__)
#define LOG_ALWAYS_FATAL(...)   do { ALOGE(__VA_ARGS__); exit(1); } while (0)

#ifdef __cplusplus
}
#endif

#endif
