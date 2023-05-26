//
//  MovieDecode.h
//  OpenGLVideoPlayer
//
//  Created by Ray on 2023/5/26.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MovieDecode : NSObject



@property (nonatomic,copy) int (^interruptCallback)(MovieDecode *) ;
-(void)open: (NSString *) path;

@end

NS_ASSUME_NONNULL_END
