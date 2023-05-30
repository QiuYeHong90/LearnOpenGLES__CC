//
//  EncodeVideo.m
//  OpenGLVideoPlayer
//
//  Created by Mac on 2023/5/29.
//

#import <libavutil/log.h>
#import <libavutil/opt.h>
#import <libavcodec/avcodec.h>
#import "EncodeVideo.h"
static int encode(AVCodecContext * ctx,AVFrame * frame, AVPacket * pkt, FILE * out);
@implementation EncodeVideo
-(NSString *)destYUVFile {
//    NSSearchPathDirectory
//    NSSearchPathDomainMask
//    NSHomeDirectory()
    NSString * dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"[NSFileManager.defaultManager fileExistsAtPath:dir] == %ld \n %@",[NSFileManager.defaultManager fileExistsAtPath:dir],NSHomeDirectory());
    dir = [dir stringByAppendingPathComponent:@"tests.h264"];
    
    return dir;
    
}

-(int)encode:(NSString *)codeName dst:(NSString *)dst {
    const AVCodec * codec = NULL;
    AVCodecContext * ctx = NULL;
    FILE * f = NULL;
    int ret = -1;
    AVFrame * frame = NULL;
    AVPacket * pkt = NULL;
//    1 输入参数 所生成的文件 编码器
    
    av_log_set_level(AV_LOG_DEBUG);
    // 2 查找编码器
    codec = avcodec_find_encoder_by_name("libx264");
    if (!codec) {
        av_log(NULL, AV_LOG_ERROR, "don't find codec \n");
        goto  _ERROR;
    }
//   3  打开编码器 创建编码器上下文 -》存编码器的参数
    ctx = avcodec_alloc_context3(codec);
    if (!ctx) {
        av_log(NULL, AV_LOG_ERROR, "no memory \n");
        goto  _ERROR;
    }
    
//    4 设置编码器参数
    ctx->width = 640;
    ctx->height = 480;
    ctx->bit_rate = 500000;
    ctx->time_base = (AVRational){1,25};
    ctx->framerate = (AVRational){25,1};
//    10 真为1组
    ctx->gop_size = 10;
    ctx->max_b_frames = 1;
    ctx->pix_fmt = AV_PIX_FMT_YUV420P;
    if (codec->id == AV_CODEC_ID_H264) {
        av_opt_set(ctx->priv_data, "preset", "slow", 0);
//        av_dict_set(ctx->priv_data, "preset", "slow", AV_DICT_DONT_STRDUP_KEY | AV_DICT_DONT_STRDUP_VAL);
    }
//    5 编码器与编码器上下文绑定到一起
    ret = avcodec_open2(ctx, codec, NULL);
    if (ret < 0) {
        av_log(ctx, AV_LOG_ERROR, "dont open codec %s \n",av_err2str(ret));
        goto _ERROR;
    }
//    6 创建输出文件
    f = fopen([dst cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    if (!f) {
        av_log(NULL, AV_LOG_ERROR, "dont open file \n");
        goto  _ERROR;
    }
//    7 创建AVFrame
    frame =  av_frame_alloc();
    if (!frame) {
        av_log(NULL, AV_LOG_ERROR, "no memory \n");
        goto  _ERROR;
    }
    frame->width = ctx->width;
    frame->height = ctx->height;
    frame->format = ctx->pix_fmt;
    ret = av_frame_get_buffer(frame, 0);
    if (ret < 0) {
        av_log(ctx, AV_LOG_ERROR, "dont allocate frame buffer %s \n",av_err2str(ret));
        goto _ERROR;
    }
//    8 创建AVPacket
    pkt = av_packet_alloc();
    if (!pkt) {
        av_log(NULL, AV_LOG_ERROR, "no memory \n");
        goto  _ERROR;
    }
//    9 生成视频内容 camera 获取视频 下面写个例子
    for (int i = 0; i < 25; i ++) {
//        判断frame data区域 是否可以用 如果不可用 就会重新分配一个可用的区域
        ret = av_frame_make_writable(frame);
        if (ret < 0) {
//            不可用,并且非配的区域也不可用
            break;
        }
//        制作数据 Y 分量
        for (int y = 0; y < ctx->height; y++) {
            for (int x = 0; x < ctx->width; x++) {
                frame->data[0][y*frame->linesize[0] + x] = x + y + i* 3;
            }
        }
        
        for (int y = 0; y < ctx->height/2; y++) {
            for (int x = 0; x < ctx->width/2; x++) {
                frame->data[1][y*frame->linesize[1] + x] = 128 + y + i* 2;
                frame->data[2][y*frame->linesize[2] + x] = 64 + x + i* 5;
            }
        }
        frame->pts = i;
        ret = encode(ctx, frame, pkt, f);
        if (ret == -1) {
            goto  _ERROR;
        }
    }
    
    
//    10 编码
    encode(ctx, NULL, pkt, f);
    
    
_ERROR:
    if (ctx) {
        avcodec_free_context(&ctx);
    }
    if (frame) {
        av_frame_free(&frame);
    }
    if (pkt) {
        av_packet_free(&pkt);
    }
    if (f) {
        fclose(f);
    }
    return -1;
    
    
}



@end
static int encode(AVCodecContext * ctx,AVFrame * frame, AVPacket * pkt, FILE * out) {
    int ret = -1;
    ret = avcodec_send_frame(ctx, frame);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "failed to send to codec");
        goto _END;
    }
    while (ret >= 0) {
        ret = avcodec_receive_packet(ctx, pkt);
        // AVERROR_EOF 编码缓冲区没有数据了 AVERROR(EAGAIN) 编码出错了
        if (ret == AVERROR_EOF || ret == AVERROR(EAGAIN)) {
            goto _END;
        } else if (ret < 0) {
            return -1;
        }
        fwrite(pkt->data, 1, pkt->size, out);
        av_packet_unref(pkt);
    }
_END:
    return 0;
}
