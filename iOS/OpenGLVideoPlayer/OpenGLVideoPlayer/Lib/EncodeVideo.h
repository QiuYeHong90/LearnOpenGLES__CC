//
//  EncodeVideo.h
//  OpenGLVideoPlayer
//
//  Created by Mac on 2023/5/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EncodeVideo : NSObject
-(NSString *)destYUVFile;
-(int)encode:(NSString *)codeName dst:(NSString *)dst;
@end

NS_ASSUME_NONNULL_END
