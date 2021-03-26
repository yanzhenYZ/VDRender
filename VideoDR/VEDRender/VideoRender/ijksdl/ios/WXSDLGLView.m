/*
 * IJKSDLGLView.m
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

#import "WXSDLGLView.h"
#include "ijksdl_gles2.h"
#include "WXCommonTool.h"
#include "ijksdl_log.h"
#include <mach/mach_time.h>
#include <time.h>
#include <sys/time.h>


typedef NS_ENUM(NSInteger, WXSDLGLViewApplicationState) {
    WXSDLGLViewApplicationUnknownState = 0,
    WXSDLGLViewApplicationForegroundState = 1,
    WXSDLGLViewApplicationBackgroundState = 2
};
int WX_GLOBAL_WXSDLGLViewApplicationState = 0;


static int g_is_mach_base_info_inited = 0;
static kern_return_t g_mach_base_info_ret = 0;
static mach_timebase_info_data_t g_mach_base_info;


Uint64 WX_GetTickHR(void)
{
    Uint64 clock;

    if (!g_is_mach_base_info_inited) {
        g_mach_base_info_ret = mach_timebase_info(&g_mach_base_info);
        g_is_mach_base_info_inited = 1;
    }
    if (g_mach_base_info_ret == 0) {
        uint64_t now = mach_absolute_time();
        clock = now * g_mach_base_info.numer / g_mach_base_info.denom / 1000000;
    } else {
        struct timeval now;
        gettimeofday(&now, NULL);
        clock = now.tv_sec  * 1000 + now.tv_usec / 1000;
    }
    
    return (clock);
}


@interface WXSDLGLView()
@property(atomic,strong) NSRecursiveLock *glActiveLock;
@property(atomic) BOOL glActivePaused;
@property(nonatomic,strong) WxGlCropFrame *cropFrame;
@end

@implementation WXSDLGLView {
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;

    int             _frameCount;
    
    int64_t         _lastFrameTime;

    WX_GLES2_Renderer *_renderer;
    int                 _rendererGravity;

    BOOL            _isRenderBufferInvalidated;

    int             _tryLockErrorCount;
    BOOL            _didSetupGL;
    BOOL            _didStopGL;
    BOOL            _didLockedDueToMovedToWindow;
    BOOL            _shouldLockWhileBeingMovedToWindow;

    WXSDLGLViewApplicationState _applicationState;
    int             _drop_display_overlay;
    bool            _isBeforeIos13;
}

@synthesize isThirdGLView              = _isThirdGLView;
@synthesize scaleFactor                = _scaleFactor;
@synthesize fps                        = _fps;

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}
-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _isBeforeIos13 = [[[UIDevice currentDevice] systemVersion] compare:@"13.0" options:NSNumericSearch] == NSOrderedAscending;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame withCropFrame:(WxGlCropFrame*) cropFrame
{
    self = [self initWithFrame:frame];
    if (self) {
//        _cropFrame = cropFrame;
        _tryLockErrorCount = 0;
        _shouldLockWhileBeingMovedToWindow = YES;
        self.glActiveLock = [[NSRecursiveLock alloc] init];
        _drop_display_overlay = 0;
        [self registerApplicationObservers];

        _didSetupGL = NO;
        if ([self isApplicationActive] == YES)
            [self setupGLOnce];
    }

    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (!_shouldLockWhileBeingMovedToWindow) {
        [super willMoveToWindow:newWindow];
        return;
    }
    if (newWindow && !_didLockedDueToMovedToWindow) {
        [self lockGLActive];
        _didLockedDueToMovedToWindow = YES;
    }
    [super willMoveToWindow:newWindow];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window && _didLockedDueToMovedToWindow) {
        [self unlockGLActive];
        _didLockedDueToMovedToWindow = NO;
    }
}

- (BOOL)setupEAGLContext:(EAGLContext *)context
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
#warning TODO: caiyonghao 添加下面代码解决iOS12播放有声音黑屏问题
    if(_isBeforeIos13){
        [CATransaction flush];
    }
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x\n", status);
        return NO;
    }

    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x\n", glError);
        return NO;
    }

    return YES;
}

- (CAEAGLLayer *)eaglLayer
{
    return (CAEAGLLayer*) self.layer;
}

- (BOOL)setupGL
{
    if (_didSetupGL)
        return YES;

    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];

    _scaleFactor = [[UIScreen mainScreen] scale];
    if (_scaleFactor < 0.1f)
        _scaleFactor = 1.0f;

    [eaglLayer setContentsScale:_scaleFactor];

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (_context == nil) {
        NSLog(@"failed to setup EAGLContext\n");
        return NO;
    }

    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];

    _didSetupGL = NO;
    if ([self setupEAGLContext:_context]) {
        NSLog(@"OK setup GL\n");
        _didSetupGL = YES;
    }

    [EAGLContext setCurrentContext:prevContext];
    return _didSetupGL;
}

- (BOOL)setupGLOnce
{
    if (_didSetupGL)
        return YES;

    if (![self tryLockGLActive])
        return NO;

    BOOL didSetupGL = [self setupGL];
    [self unlockGLActive];
    return didSetupGL;
}

- (BOOL)isApplicationActive
{
    switch (WX_GLOBAL_WXSDLGLViewApplicationState) {
        case WXSDLGLViewApplicationForegroundState:
            _applicationState = WXSDLGLViewApplicationForegroundState;
            break;
        case WXSDLGLViewApplicationBackgroundState:
            _applicationState = WXSDLGLViewApplicationBackgroundState;
            break;
        default:
            break;
    }
    switch (_applicationState) {
        case WXSDLGLViewApplicationForegroundState:
            return YES;
        case WXSDLGLViewApplicationBackgroundState:
            return NO;
        default: {
            UIApplicationState appState = [UIApplication sharedApplication].applicationState;
            switch (appState) {
                case UIApplicationStateActive:
                    return YES;
                case UIApplicationStateInactive:
                case UIApplicationStateBackground:
                default:
                    return NO;
            }
        }
    }
}

- (void)dealloc
{
    [self lockGLActive];

    _didStopGL = YES;

    EAGLContext *prevContext = [EAGLContext currentContext];
    [EAGLContext setCurrentContext:_context];
    
    WX_GLES2_Renderer_reset(_renderer);
    WX_GLES2_Renderer_freeP(&_renderer);

    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }

    glFinish();

    [EAGLContext setCurrentContext:prevContext];

    _context = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self unlockGLActive];
}

- (void)setScaleFactor:(CGFloat)scaleFactor
{
    _scaleFactor = scaleFactor;
    [self invalidateRenderBuffer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.window.screen != nil) {
        _scaleFactor = self.window.screen.scale;
    }
    [self invalidateRenderBuffer];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];

    switch (contentMode) {
        case UIViewContentModeScaleToFill:
            _rendererGravity = WX_GLES2_GRAVITY_RESIZE;
            break;
        case UIViewContentModeScaleAspectFit:
            _rendererGravity = WX_GLES2_GRAVITY_RESIZE_ASPECT;
            break;
        case UIViewContentModeScaleAspectFill:
            _rendererGravity = WX_GLES2_GRAVITY_RESIZE_ASPECT_FILL;
            break;
        default:
            _rendererGravity = WX_GLES2_GRAVITY_RESIZE_ASPECT;
            break;
    }
    [self invalidateRenderBuffer];
}

- (BOOL)setupRenderer: (WX_SDL_VoutOverlay *) overlay
{
    if (overlay == nil)
        return _renderer != nil;

    if (!WX_GLES2_Renderer_isValid(_renderer) ||
        !WX_GLES2_Renderer_isFormat(_renderer, overlay->format)) {

        WX_GLES2_Renderer_reset(_renderer);
        WX_GLES2_Renderer_freeP(&_renderer);

        _renderer = WX_GLES2_Renderer_create(overlay);
        if(self.cropFrame){
            WX_GLES2_Renderer_set_crop(_renderer,_cropFrame.crop_x, _cropFrame.crop_y, _cropFrame.crop_w, _cropFrame.crop_h);
        }
        if (!WX_GLES2_Renderer_isValid(_renderer))
            return NO;

        if (!WX_GLES2_Renderer_use(_renderer))
            return NO;

        WX_GLES2_Renderer_setGravity(_renderer, _rendererGravity, _backingWidth, _backingHeight);
    }
    return YES;
}

- (void)invalidateRenderBuffer
{
    NSLog(@"invalidateRenderBuffer\n");
    [self lockGLActive];

    _isRenderBufferInvalidated = YES;

    if ([[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (_isRenderBufferInvalidated)
                [self display:nil];
        });
    } else {
        [self display:nil];
    }

    [self unlockGLActive];
}

//- (void)asyncDisplay: (WX_SDL_VoutOverlay *) overlay{
//    
//    dispatch_async([WXSDLGLView renderQueue], ^{
//        [self display:overlay];
//    });
//}

- (void)display: (WX_SDL_VoutOverlay *) overlay
{
    if (_didSetupGL == NO)
        return;

    if ([self isApplicationActive] == NO)
        return;
    
    if(_drop_display_overlay > 0){
        _drop_display_overlay --;
        return;
    }

    if (![self tryLockGLActive]) {
        if (0 == (_tryLockErrorCount % 100)) {
            NSLog(@"IJKSDLGLView:display: unable to tryLock GL active: %d\n", _tryLockErrorCount);
        }
        _tryLockErrorCount++;
        return;
    }

    _tryLockErrorCount = 0;
    if (_context && !_didStopGL) {
        EAGLContext *prevContext = [EAGLContext currentContext];
        [EAGLContext setCurrentContext:_context];
        [self displayInternal:overlay];
        [EAGLContext setCurrentContext:prevContext];
    }

    [self unlockGLActive];
}

// NOTE: overlay could be NULl
- (void)displayInternal: (WX_SDL_VoutOverlay *) overlay
{
    if (![self setupRenderer:overlay]) {
        if (!overlay && !_renderer) {
            NSLog(@"IJKSDLGLView: setupDisplay not ready\n");
        } else {
            NSLog(@"IJKSDLGLView: setupDisplay failed\n");
        }
        return;
    }

    [[self eaglLayer] setContentsScale:_scaleFactor];

    if (_isRenderBufferInvalidated) {
        NSLog(@"IJKSDLGLView: renderbufferStorage fromDrawable\n");
        _isRenderBufferInvalidated = NO;

        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        WX_GLES2_Renderer_setGravity(_renderer, _rendererGravity, _backingWidth, _backingHeight);
//#warning TODO: caiyonghao 添加下面代码解决iOS12播放有声音黑屏问题
//        [CATransaction flush];
    }

    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
//    glViewport(0, 0, _backingWidth, _backingHeight);

    if (!WX_GLES2_Renderer_renderOverlay(_renderer, overlay))
        ALOGE("[EGL] WX_GLES2_render failed\n");

    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];

    int64_t current = (int64_t)WX_GetTickHR();
    int64_t delta   = (current > _lastFrameTime) ? current - _lastFrameTime : 0;
    if (delta <= 0) {
        _lastFrameTime = current;
    } else if (delta >= 1000) {
        _fps = ((CGFloat)_frameCount) * 1000 / delta;
        _frameCount = 0;
        _lastFrameTime = current;
    } else {
        _frameCount++;
    }
}

#pragma mark AppDelegate

- (void) lockGLActive
{
    [self.glActiveLock lock];
}

- (void) unlockGLActive
{
    [self.glActiveLock unlock];
}

- (BOOL) tryLockGLActive
{
    if (![self.glActiveLock tryLock])
        return NO;

    /*-
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
        [UIApplication sharedApplication].applicationState != UIApplicationStateInactive) {
        [self.appLock unlock];
        return NO;
    }
     */

    if (self.glActivePaused) {
        [self.glActiveLock unlock];
        return NO;
    }
    
    return YES;
}

- (void)toggleGLPaused:(BOOL)paused
{
    [self lockGLActive];
    if (!self.glActivePaused && paused) {
        if (_context != nil) {
            EAGLContext *prevContext = [EAGLContext currentContext];
            [EAGLContext setCurrentContext:_context];
            glFinish();
            [EAGLContext setCurrentContext:prevContext];
        }
    }
    self.glActivePaused = paused;
    [self unlockGLActive];
}

- (void)registerApplicationObservers
{

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];

#warning TODO: caiyonghao  修改源码，解决闪退问题
//https://bugly.qq.com/v2/crash-reporting/crashes/4f4fe70692/21468?pid=2
    switch (WX_GLOBAL_WXSDLGLViewApplicationState) {
        case 1:
            _applicationState =  WXSDLGLViewApplicationForegroundState;
            break;
        case 2:
             _applicationState =  WXSDLGLViewApplicationBackgroundState;
            break;
        default:
            _applicationState=WXSDLGLViewApplicationUnknownState;
//            switch ([UIApplication sharedApplication].applicationState) {
//                case UIApplicationStateActive:
//                    _applicationState =  WXSDLGLViewApplicationForegroundState;
//                    break;
//                case UIApplicationStateInactive:
//                case UIApplicationStateBackground:
//                default:
//                    _applicationState =  WXSDLGLViewApplicationBackgroundState;
//                    break;
//            }
            break;
    }

//    switch ([UIApplication sharedApplication].applicationState) {
//        case UIApplicationStateActive:
//            _applicationState =  WXSDLGLViewApplicationForegroundState;
//            break;
//        case UIApplicationStateInactive:
//        case UIApplicationStateBackground:
//        default:
//            _applicationState =  WXSDLGLViewApplicationBackgroundState;
//            break;
//    }
}


- (UIImage*)snapshot
{
    [self lockGLActive];

    UIImage *image = [self snapshotInternal];

    [self unlockGLActive];

    return image;
}

- (UIImage*)snapshotInternal
{
    if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    // Render our snapshot into the image context
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];

    // Grab the image from the context
    UIImage *complexViewImage = UIGraphicsGetImageFromCurrentImageContext();
    // Finish using the context
    UIGraphicsEndImageContext();

    return complexViewImage;
}



- (void)applicationWillEnterForeground
{
    NSLog(@"IJKSDLGLView:applicationWillEnterForeground: %d", (int)[UIApplication sharedApplication].applicationState);
    [self setupGLOnce];
    _applicationState = WXSDLGLViewApplicationForegroundState;
    [self toggleGLPaused:NO];
     _drop_display_overlay = 0;
}

- (void)applicationDidBecomeActive
{
    NSLog(@"IJKSDLGLView:applicationDidBecomeActive: %d", (int)[UIApplication sharedApplication].applicationState);
    [self setupGLOnce];
    [self toggleGLPaused:NO];
    _drop_display_overlay = 0;
}

- (void)applicationWillResignActive
{
    NSLog(@"IJKSDLGLView:applicationWillResignActive: %d", (int)[UIApplication sharedApplication].applicationState);
    _drop_display_overlay = 2;
    [self toggleGLPaused:YES];
    glFinish();
}

- (void)applicationDidEnterBackground
{
    NSLog(@"IJKSDLGLView:applicationDidEnterBackground: %d", (int)[UIApplication sharedApplication].applicationState);
    _applicationState = WXSDLGLViewApplicationBackgroundState;
    [self toggleGLPaused:YES];
    glFinish();
}

- (void)applicationWillTerminate
{
    NSLog(@"IJKSDLGLView:applicationWillTerminate: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:YES];
}

- (void)setShouldLockWhileBeingMovedToWindow:(BOOL)shouldLockWhileBeingMovedToWindow
{
    _shouldLockWhileBeingMovedToWindow = shouldLockWhileBeingMovedToWindow;
}
@end


@implementation WxGlCropFrame

-(instancetype)initWithFrame:(int)x y:(int)y w:(int)w h:(int)h{
    if(self = [super init]){
        _crop_x = x;
        _crop_y = y;
        _crop_w = w;
        _crop_h = h;
    }
    return self;
}

+(WxGlCropFrame*)create:(int)x y:(int)y w:(int)w h:(int)h{
    if(w <= 0 || h <= 0)
        return nil;
    
    WxGlCropFrame * cropFrame = [[WxGlCropFrame alloc] initWithFrame:x y:y w:w h:h];
    return cropFrame;
}

@end
