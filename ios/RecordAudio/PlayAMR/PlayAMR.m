//
// Created by apple on 13-2-21.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <AVFoundation/AVFoundation.h>
#import "PlayAMR.h"
#import "amrFileCodec.h"
//#import "RecorderManager.h"

#define amrPlayCompleted (const uint8_t*)"amrPlayCompleted"
#define amrStopped (const uint8_t*)"amrStopped"
#define debugStr (const uint8_t*)"debug~"


@implementation PlayAMR

@synthesize player = _player;
@synthesize resourcePath = _resourcePath;

//DEF_SINGLETON(PlayAMR)

- (void)playAMR:(NSString *)path volume:(float)volume {
    if (nil == path || path.length <= 0) {
        return;
    }

    // 首先要停止当前音频的播放
    [self stopCurrentPlayAMRFile];

    // 对比当前要播放和的已经在播放的是否相同
    if ([self.resourcePath isEqualToString:path]) {
        // 停止播放
        self.resourcePath = nil;
        return;
    } else {
        // 切换播放
        self.resourcePath = path;
    }
      NSError *err;

    NSData *amrData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:&err];
    if (nil == amrData) {
        NSLog(@"can not find the path：%@,error:%@",path,err);
        return; // 这里基本会不执行，除非出现非常的意外
    }

    // 创建播放器以及进行文件格式转换 这里也可以直接用DATA不需要临时文件的，优化的时候再说吧
  
    NSString *filePath2 = [NSHomeDirectory() stringByAppendingPathComponent: @"Documents/recording.wav"];
    NSData * wavData = DecodeAMRToWAVE(amrData);
    [wavData writeToFile:filePath2 atomically:YES];
    NSURL *url = [NSURL fileURLWithPath:filePath2];
    _player=[[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
//             initWithData:[NSData dataWithContentsOfURL:url] error:&err];
    _player.delegate=self;
    // NSLog(@"the path of player realized is %@",filePath1);
//    if (_player==nil) {
        NSLog(@"声音放送--%@",[err description]);
//    }
    _player.volume=volume;

    // 下面两句可以控制从听筒播放声音
    UInt32 doChangeDefaultRoute =1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker,sizeof(doChangeDefaultRoute),&doChangeDefaultRoute);

    // 开始播放
//    [_player prepareToPlay];
    [_player play];
}

- (void)stopCurrentPlayAMRFile {
    if (_player.isPlaying) {
        [_player stop];
        [_player release];
        _player = nil;
        if (block_PlayFinish) {
            block_PlayFinish(nil);
        }
        FREDispatchStatusEventAsync(self.freContext, amrStopped, amrStopped);

    }
}

- (void)finishPlay:(void (^)(id))block {
    if (block_PlayFinish) {
        [block_PlayFinish release];
        block_PlayFinish = nil;
    }
    block_PlayFinish = [block copy];
    FREDispatchStatusEventAsync(self.freContext, amrPlayCompleted, amrPlayCompleted);
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    NSLog(@"play fault？ %d",flag);
    if (flag) { // 成功播放结束
                self.player = nil;
        self.resourcePath = nil;
        if (block_PlayFinish) {
            block_PlayFinish(nil);
        }
        FREDispatchStatusEventAsync(self.freContext, amrPlayCompleted, amrPlayCompleted);
    }
}

-(BOOL)isPlaying {
    return self.player.isPlaying;
}


-(void) dealloc {
    [block_PlayFinish release];
    self.player = nil;
    self.resourcePath = nil;
    [super dealloc];
}
@end