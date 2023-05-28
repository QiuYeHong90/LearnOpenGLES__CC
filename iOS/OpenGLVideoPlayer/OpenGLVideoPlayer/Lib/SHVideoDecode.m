//
//  SHVideoDecode.m
//  FFmpegApiDemo
//
//  Created by Mac on 2023/5/28.
//

#import <libavcodec/codec.h>
#import <libavutil/avutil.h>
#import <libavformat/avformat.h>
#import "SHVideoDecode.h"


@interface SHVideoDecode ()
{
    AVFormatContext * _inputCxt;
}


@end

@implementation SHVideoDecode

-(NSString *)destFile {
//    NSSearchPathDirectory
//    NSSearchPathDomainMask
//    NSHomeDirectory()
    NSString * dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"[NSFileManager.defaultManager fileExistsAtPath:dir] == %ld \n %@",[NSFileManager.defaultManager fileExistsAtPath:dir],NSHomeDirectory());
    dir = [dir stringByAppendingPathComponent:@"test.aac"];
    
    return dir;
    
}
-(NSString *)destYUVFile {
//    NSSearchPathDirectory
//    NSSearchPathDomainMask
//    NSHomeDirectory()
    NSString * dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"[NSFileManager.defaultManager fileExistsAtPath:dir] == %ld \n %@",[NSFileManager.defaultManager fileExistsAtPath:dir],NSHomeDirectory());
    dir = [dir stringByAppendingPathComponent:@"tests.mov"];
    
    return dir;
    
}

-(int)open:(NSString *)url {
    AVFormatContext * oFmtCtx = NULL;
    NSString * dst = [self destFile];
    NSLog(@"url == %@ == dst ==%@",url, dst);
    int idx = -1;
    if (_inputCxt) {
        return -1;
    }
//   如果是网络的
    avformat_network_init();
    const char * urlStr = [url cStringUsingEncoding:NSUTF8StringEncoding];
    int result = -1;
    
    result = avformat_open_input(&_inputCxt, urlStr, NULL, NULL);
    if (result < 0) {
        av_log(NULL, AV_LOG_ERROR, "ERR: %s\n",av_err2str(result));
        return result;
    }
//    AVCodec * inputAudioCoder;
//    从多媒体中找到音频流
    idx = av_find_best_stream(_inputCxt, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (idx < 0) {
        av_log(_inputCxt, AV_LOG_ERROR, "Does not include audio streams\n");
        goto _ERROR;
    }
//    4 打开目的文件上下文是
    
    oFmtCtx = avformat_alloc_context();
    if (oFmtCtx == NULL) {
        av_log(NULL, AV_LOG_ERROR, "NO memory \n");
        goto _ERROR;
    }
    
    AVOutputFormat * outPutFmt;
    
    
    outPutFmt = av_guess_format(NULL, [dst cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    oFmtCtx->oformat = outPutFmt;
    
//    5 为目的文件创建一个新的音频流
    AVStream * outAudioStream;
    outAudioStream = avformat_new_stream(oFmtCtx, NULL);
//    6 设置音频参数, 我们没有改变原来的参数 copy 一下
    AVStream * srcStream = NULL;
    srcStream = _inputCxt->streams[idx];
    avcodec_parameters_copy(outAudioStream->codecpar, srcStream->codecpar);
    outAudioStream->codecpar->codec_tag = 0 ;
// 绑定
    result = avio_open2(&oFmtCtx->pb, [dst cStringUsingEncoding:NSUTF8StringEncoding], AVIO_FLAG_WRITE, NULL, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//  7 写多媒体文件头到目的问价
    result = avformat_write_header(oFmtCtx, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//    8 从源媒体文件中读到音频数据到目的文件中 音视频是1帧一帧的
    AVPacket pkt ;
    while (av_read_frame(_inputCxt, &pkt) >= 0) {
        if (pkt.stream_index == idx) {
//          1 原来的  2 输入流的时间基
            pkt.pts = av_rescale_q_rnd(pkt.pts, srcStream->time_base, outAudioStream->time_base, AV_ROUND_PASS_MINMAX|AV_ROUND_NEAR_INF);
            pkt.dts = pkt.pts;
            pkt.duration = av_rescale_q(pkt.duration, srcStream->time_base, outAudioStream->time_base);
            pkt.stream_index = 0;
            pkt.pos = -1;
            av_interleaved_write_frame(oFmtCtx, &pkt);
            av_packet_unref(&pkt);
        }
    }
    
//    9 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);
    
//    10 释放资源
    
    
_ERROR:
    if(_inputCxt) {
        avformat_close_input(&_inputCxt);
        _inputCxt = NULL;
    }
    
    if (oFmtCtx) {
        if (oFmtCtx->pb) {
            avio_close(oFmtCtx->pb);
        }
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }
    return 0;
}

-(int)takeVideo:(NSString *)url {
    AVFormatContext * oFmtCtx = NULL;
    NSString * dst = [self destYUVFile];
    NSLog(@"url == %@ == dst ==%@",url, dst);
    int idx = -1;
    if (_inputCxt) {
        return -1;
    }
//   如果是网络的
    avformat_network_init();
    const char * urlStr = [url cStringUsingEncoding:NSUTF8StringEncoding];
    int result = -1;
    
    result = avformat_open_input(&_inputCxt, urlStr, NULL, NULL);
    if (result < 0) {
        av_log(NULL, AV_LOG_ERROR, "ERR: %s\n",av_err2str(result));
        return result;
    }
//    AVCodec * inputAudioCoder;
//    从多媒体中找到视频流
    idx = av_find_best_stream(_inputCxt, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (idx < 0) {
        av_log(_inputCxt, AV_LOG_ERROR, "Does not include audio streams\n");
        goto _ERROR;
    }
//    4 打开目的文件上下文是
    oFmtCtx = avformat_alloc_context();
    if (oFmtCtx == NULL) {
        av_log(NULL, AV_LOG_ERROR, "NO memory \n");
        goto _ERROR;
    }
    
    AVOutputFormat * outPutFmt;
    
    
    outPutFmt = av_guess_format(NULL, [dst cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    oFmtCtx->oformat = outPutFmt;
    
//    5 为目的文件创建一个新的音频流
    AVStream * outAudioStream;
    outAudioStream = avformat_new_stream(oFmtCtx, NULL);
//    6 设置视频频参数, 我们没有改变原来的参数 copy 一下
    AVStream * srcStream = NULL;
    srcStream = _inputCxt->streams[idx];
    avcodec_parameters_copy(outAudioStream->codecpar, srcStream->codecpar);
    outAudioStream->codecpar->codec_tag = 0 ;
// 绑定
    result = avio_open2(&oFmtCtx->pb, [dst cStringUsingEncoding:NSUTF8StringEncoding], AVIO_FLAG_WRITE, NULL, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//  7 写多媒体文件头到目的问价
    result = avformat_write_header(oFmtCtx, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//    8 从源媒体文件中读到音频数据到目的文件中 音视频是1帧一帧的
    AVPacket pkt ;
    while (av_read_frame(_inputCxt, &pkt) >= 0) {
        if (pkt.stream_index == idx) {
//          1 原来的  2 输入流的时间基
            pkt.pts = av_rescale_q_rnd(pkt.pts, srcStream->time_base, outAudioStream->time_base, AV_ROUND_PASS_MINMAX|AV_ROUND_NEAR_INF);
            pkt.dts = av_rescale_q_rnd(pkt.dts, srcStream->time_base, outAudioStream->time_base, AV_ROUND_PASS_MINMAX|AV_ROUND_NEAR_INF);
            pkt.duration = av_rescale_q(pkt.duration, srcStream->time_base, outAudioStream->time_base);
            pkt.stream_index = 0;
            pkt.pos = -1;
            av_interleaved_write_frame(oFmtCtx, &pkt);
            av_packet_unref(&pkt);
        }
    }
    
//    9 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);
    
//    10 释放资源
    
    
_ERROR:
    if(_inputCxt) {
        avformat_close_input(&_inputCxt);
        _inputCxt = NULL;
    }
    
    if (oFmtCtx) {
        if (oFmtCtx->pb) {
            avio_close(oFmtCtx->pb);
        }
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }
    return 0;
}
-(int)remux:(NSString *)url {
    AVFormatContext * oFmtCtx = NULL;
    NSString * dst = [self destYUVFile];
    NSLog(@"url == %@ == dst ==%@",url, dst);
    if (_inputCxt) {
        return -1;
    }
//   如果是网络的
    avformat_network_init();
    const char * urlStr = [url cStringUsingEncoding:NSUTF8StringEncoding];
    int result = -1;
    
    result = avformat_open_input(&_inputCxt, urlStr, NULL, NULL);
    if (result < 0) {
        av_log(NULL, AV_LOG_ERROR, "ERR: %s\n",av_err2str(result));
        return result;
    }
//    AVCodec * inputAudioCoder;
//    从多媒体中找到视频流
//    idx = av_find_best_stream(_inputCxt, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
//    if (idx < 0) {
//        av_log(_inputCxt, AV_LOG_ERROR, "Does not include audio streams\n");
//        goto _ERROR;
//    }
//    4 打开目的文件上下文是
    avformat_alloc_output_context2(&oFmtCtx, NULL, NULL, [dst cStringUsingEncoding:NSUTF8StringEncoding]);
    printf("oformat ==%s",oFmtCtx->oformat->name);
    if (oFmtCtx == NULL) {
        av_log(NULL, AV_LOG_ERROR, "NO memory \n");
        goto _ERROR;
    }
//    分配内存给数组
    int *stream_map = av_calloc( _inputCxt->nb_streams, sizeof(int));
    int mapIdex = 0;
    for (int i = 0; i < _inputCxt->nb_streams; i++) {
        AVStream * outAudioStream;
        AVStream * srcStream = _inputCxt->streams[i];
        AVCodecParameters * inCodecParam = srcStream->codecpar;
        if (inCodecParam->codec_type != AVMEDIA_TYPE_VIDEO && inCodecParam->codec_type != AVMEDIA_TYPE_AUDIO && inCodecParam->codec_type != AVMEDIA_TYPE_SUBTITLE) {
//            过滤
            stream_map[i] = -1;
            continue;
        }
        stream_map[i] = mapIdex++;
        //    5 为目的文件创建一个新的音频流
        outAudioStream = avformat_new_stream(oFmtCtx, NULL);
        if (outAudioStream == NULL) {
            av_log(NULL, AV_LOG_ERROR, "NO memory \n");
            goto _ERROR;
        }
        avcodec_parameters_copy(outAudioStream->codecpar, srcStream->codecpar);
        outAudioStream->codecpar->codec_tag = 0 ;
        
    }

// 绑定
    result = avio_open2(&oFmtCtx->pb, [dst cStringUsingEncoding:NSUTF8StringEncoding], AVIO_FLAG_WRITE, NULL, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//  7 写多媒体文件头到目的问价
    result = avformat_write_header(oFmtCtx, NULL);
    if (result < 0) {
        av_log(oFmtCtx, AV_LOG_ERROR, "ERR: %s \n",av_err2str(result));
        goto _ERROR;
    }
//    8 从源媒体文件中读到音频数据到目的文件中 音视频是1帧一帧的
    AVPacket pkt ;
    while (av_read_frame(_inputCxt, &pkt) >= 0) {
        AVStream * srcStream;
        AVStream * outAudioStream;
        srcStream = _inputCxt->streams[pkt.stream_index];
        if (stream_map[pkt.stream_index] < 0) {
            av_packet_unref(&pkt);
            continue;
        }
        
        outAudioStream = oFmtCtx->streams[pkt.stream_index];
        pkt.stream_index = stream_map[pkt.stream_index];
        av_packet_rescale_ts(&pkt, srcStream->time_base, outAudioStream->time_base);
        
        pkt.pos = -1;
        av_interleaved_write_frame(oFmtCtx, &pkt);
        av_packet_unref(&pkt);
    }
    
//    9 写多媒体文件尾到文件中
    av_write_trailer(oFmtCtx);
    
//    10 释放资源
    
    printf("===w");
_ERROR:
    if(_inputCxt) {
        avformat_close_input(&_inputCxt);
        _inputCxt = NULL;
    }
    
    if (oFmtCtx) {
        if (oFmtCtx->pb) {
            avio_close(oFmtCtx->pb);
        }
        avformat_free_context(oFmtCtx);
        oFmtCtx = NULL;
    }
    return 0;
}
@end
