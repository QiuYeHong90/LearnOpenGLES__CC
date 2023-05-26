//
//  MovieDecode.m
//  OpenGLVideoPlayer
//
//  Created by Ray on 2023/5/26.
//
//1.引用头文件
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/pixdesc.h>
#include <libavcodec/avcodec.h>
#import "MovieDecode.h"

@interface MovieDecode ()
{
    int videoStreamIndex;
    int audioStreamIndex;
    AVStream * audioStream;
    AVStream * videoStream;
}
@end


@implementation MovieDecode
// 2.注册协议、格式与编解码器
-(void)registerAll {
    avformat_network_init();
//    avcodec_version()
//    av_register_all();
}

//3.打开媒体文件源，并设置超时回调
-(void)open: (NSString *) path {
    AVFormatContext *formatCtx = avformat_alloc_context();
    if (self.interruptCallback) {
        AVIOInterruptCB int_cb = { interrupt_callback, (__bridge void *)(self)};
        
        formatCtx->interrupt_callback = int_cb;
        
    }
    avformat_open_input(&formatCtx, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL);
    avformat_find_stream_info(formatCtx, NULL);
    // MARK: 4.寻找各个流，并且打开对应的解码器
    // 寻找音视频流：
    for(int i = 0; i < formatCtx->nb_streams; i++) {
        AVStream* stream = formatCtx->streams[i];
        if(AVMEDIA_TYPE_VIDEO == stream->codecpar->codec_type) {
            // 视频流
            videoStreamIndex = i;
            videoStream = stream;
            
        } else if(AVMEDIA_TYPE_AUDIO == stream->codecpar->codec_type ){
            // 音频流
            audioStreamIndex = i;
            audioStream = stream;
        }
        
    }
    
    // 打开音频流解码器：
    AVCodecContext * audioCodecCtx = audioStream->codecpar;
    AVCodec *codec = avcodec_find_decoder(audioCodecCtx ->codec_id);
    if(!codec){
        // 找不到对应的音频解码器
        
    }
    int openCodecErrCode = 0;
    
    if ((openCodecErrCode = avcodec_open2(audioCodecCtx, codec, NULL)) < 0){
        // 打开音频解码器失败
        
    }
}

//4.寻找各个流，并且打开对应的解码器




// 超时回调函数
static int interrupt_callback(void *ctx)
{
    if (!ctx)
        return 0;
    __unsafe_unretained MovieDecode *p = (__bridge MovieDecode *)ctx;
    
    
    printf("====FFFFF");
    return 0;
//    const BOOL r = [p interruptDecoder];
//    if (r) NSLog( @"DEBUG: INTERRUPT_CALLBACK!");
//    return r;
}

@end
