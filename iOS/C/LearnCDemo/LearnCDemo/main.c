//
//  main.c
//  LearnCDemo
//
//  Created by Mac on 2023/5/16.
//

#include <stdio.h>
#include <libavformat/avformat.h>
#include <libavformat/avio.h>
#include <libavutil/avutil.h>
int extcDir(void);
int takeAudio(int argc, const char * argv[]);
int main(int argc, const char * argv[]) {
    // insert code here...
    
    av_log_set_level(AV_LOG_DEBUG);
    int r = extcDir();
    r = takeAudio(argc,argv);
    return r;
}
// MARK: 从视频中提取音频流
int takeAudio(int argc, const char * argv[]) {
    int r = -1;
    av_log(NULL, AV_LOG_INFO, "r == %d \n",r);
    av_log(NULL, AV_LOG_INFO, "argc == %d \n",argc);
    if (argc < 3) {
        av_log(NULL, AV_LOG_ERROR, "argc == %d 参数个数太少了 \n",argc);
        return -1;
    }
    
    char * src;
    char * dist;
    src = argv[1];
    dist = argv[2];
    av_log(NULL, AV_LOG_INFO, "src: %s \n dist: %s \n",src,dist);
    
//    AVInputFormat *fmt;
    AVFormatContext * context = NULL;
    int ret = -1;
    ret = avformat_open_input(&context, src, NULL, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "err == %s  \n",av_err2str(ret));
        return ret;
    }
    int index = -1;
    index = av_find_best_stream(context, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (index < 0) {
        av_log(context, AV_LOG_ERROR, "err == %s  \n",av_err2str(index));
        goto __error;
    }
    
//    4 打开目的文件的上下文
    AVFormatContext * distContext = NULL;
    distContext = avformat_alloc_context();
    if (!distContext) {
        av_log(context, AV_LOG_ERROR, "err == 分配空间出错  \n");
        goto __error;
    }
    AVOutputFormat * outputFormat = NULL;
    outputFormat = av_guess_format(NULL, dist, NULL);
    if (!outputFormat) {
        av_log(context, AV_LOG_ERROR, "err == 分配空间出错  \n");
        goto __error;
    }
    
    distContext->oformat = outputFormat;
//    5. • 为目的文件，创建一个新的音频流
    AVStream * outStream = NULL;
    AVStream * inStream = NULL;
    outStream = avformat_new_stream(distContext, NULL);
//    6.•设置输出音频参数
    
    inStream = context->streams[index];
    
    r = avcodec_parameters_copy(outStream->codecpar, inStream->codecpar);
    outStream->codecpar->codec_tag = 0;
    if (r < 0) {
        goto __error;
    }
//    绑定
    r = -1;
    r = avio_open2(&distContext->pb, dist, AVIO_FLAG_WRITE, NULL, NULL);
    if (r < 0) {
        av_log(distContext, AV_LOG_ERROR, "err == %s  \n",av_err2str(r));
        goto __error;
    }
    
    
//    7.•写多媒体文件头到目的文件
    r = -1;
    r = avformat_write_header(distContext, NULL);
    if (r < 0) {
        av_log(distContext, AV_LOG_ERROR, "err == %s  \n",av_err2str(r));
        goto __error;
    }
    //    8．•从源多媒体文件中读到音频数据到目的文件中
    AVPacket pkt;
    while (av_read_frame(context, &pkt) >= 0) {
        if (pkt.stream_index == index) {
            pkt.pts = av_rescale_q_rnd(pkt.pts, inStream->time_base, outStream->time_base, (AV_ROUND_INF | AV_ROUND_PASS_MINMAX));
            pkt.dts = pkt.pts;
            pkt.duration = av_rescale_q(pkt.duration, inStream->time_base, outStream->time_base);
            pkt.stream_index = 0;
            pkt.pos = -1;
            av_interleaved_write_frame(distContext, &pkt);
            av_packet_unref(&pkt);
        }
        
    }
    
    

    
//    9••写多媒体文件尾到文件中
    av_write_trailer(distContext);

//    10．•将申请的资源释放掉
__error:
    if (distContext->pb) {
        avio_close(distContext->pb);
    }
    if (distContext) {
        avformat_close_input(&distContext);
    }
    
    if (context) {
        avformat_close_input(&context);
    }
    return r;
}


int extcDir(void) {
    av_log(NULL, AV_LOG_INFO, "test===\n");
    
    AVIODirContext * dir = NULL;
    int openResult = -1;
    openResult = avio_open_dir(&dir, "./", NULL);
    if (openResult < 0) {
        av_log(NULL, AV_LOG_ERROR, "===err");
        return  openResult;
    }
    AVIODirEntry * nextEntry;
    
    int entryR = -1;
    while (1) {
        entryR = avio_read_dir(dir, &nextEntry);
        if (entryR < 0) {
            goto __fail;
        }
        if (!nextEntry) {
            break;
        }
        av_log(NULL, AV_LOG_INFO, "===size= %lld name = %s\n",nextEntry->size,nextEntry->name);
    }
    int closeR = -1;
__fail:
    closeR = avio_close_dir(&dir);
    return closeR;
}
