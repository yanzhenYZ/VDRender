/*
 * IJKSDLGLView.h
 *
 * Copyright (c) 2013 Bilibili
 * Copyright (c) 2013 Zhang Rui <bbcallen@gmail.com>
 *
 * based on https://github.com/kolyvan/kxmovie
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

#import <UIKit/UIKit.h>
#import "WXSDLGLViewProtocol.h"
#include "ijksdl_vout.h"


@interface WxGlCropFrame:NSObject
@property (nonatomic, assign)  int  crop_x;
@property (nonatomic, assign)  int  crop_y;
@property (nonatomic, assign)  int  crop_w;
@property (nonatomic, assign)  int  crop_h;
+(WxGlCropFrame*)create:(int)x y:(int)y w:(int)w h:(int)h;
@end

@interface WXSDLGLView : UIView <WXSDLGLViewProtocol>

- (instancetype) initWithFrame:(CGRect)frame withCropFrame:(WxGlCropFrame*) cropFrame;
- (void)display: (WX_SDL_VoutOverlay *) overlay;
- (UIImage*) snapshot;
- (void)setShouldLockWhileBeingMovedToWindow:(BOOL)shouldLockWhiteBeingMovedToWindow __attribute__((deprecated("unused")));

@end
