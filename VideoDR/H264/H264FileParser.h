//
//  H264FileParser.h
//  VideoDR
//
//  Created by yanzhen on 2023/3/7.
//

#import <Foundation/Foundation.h>

@protocol H264FileParserDelegate;
@interface H264FileParser : NSObject
@property (nonatomic, weak) id<H264FileParserDelegate> delegate;
- (instancetype)initWithFile:(NSString *)file;

- (void)startWithTimeInterval:(NSTimeInterval)interval;
- (void)stop;
@end


@protocol H264FileParserDelegate <NSObject>

- (void)parser:(H264FileParser *)parser sps:(NSData *)sps pps:(NSData *)pps;
- (void)parser:(H264FileParser *)parser h264Data:(NSData *)data;
@end

