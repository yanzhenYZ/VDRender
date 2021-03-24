//
//  YXFileHandle.h
//  VideoDR
//
//  Created by yanzhen on 2021/3/24.
//

#import <Foundation/Foundation.h>

@interface YXFileHandle : NSObject

- (void)writeData:(NSData *)data;
- (void)stop;

@end

