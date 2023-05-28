//
//  SHVideoDecode.h
//  FFmpegApiDemo
//
//  Created by Mac on 2023/5/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//www.douyin.com/aweme/v1/play/?video_id=v0200fg10000chomo7fog65ilugl0590&line=0&file_id=47b1e25cc5584e5d866644e38c61d2af&sign=601c24b392eceee35debb72059ef20b5&is_play_url=1&source=PackSourceEnum_FEED&aid=6383
@interface SHVideoDecode : NSObject
// 提取音频流到本地
-(int)open:(NSString *)url;
// 抽取视频
-(int)takeVideo:(NSString *)url;
// 转封装
-(int)remux:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
