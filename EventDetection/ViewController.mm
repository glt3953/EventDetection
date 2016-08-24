//
//  ViewController.m
//  EventDetection
//
//  Created by guoliting on 16/8/22.
//  Copyright © 2016年 DiDi. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#include "event_detection.h"
#import "WaverView.h"

@interface ViewController () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) WaverView *waverView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat originX = 20;
    CGFloat originY = 100;
    CGFloat buttonWidth = (self.view.frame.size.width - 2 * originX - 10) / 2;
    CGFloat buttonHeight = 45;
    // 录音按钮
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake(originX, originY, buttonWidth, buttonHeight);
    recordButton.backgroundColor = [UIColor greenColor];
    [recordButton.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [recordButton setTitle:@"录音" forState:UIControlStateNormal];
    [recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(recordButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [[recordButton layer] setBorderColor:[[UIColor blueColor] CGColor]];
    [[recordButton layer] setBorderWidth:1];
    [self.view addSubview:recordButton];
    
    originX += buttonWidth + 5;
    UIButton *recogButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recogButton.frame = CGRectMake(originX, originY, buttonWidth, buttonHeight);
    recogButton.backgroundColor = [UIColor greenColor];
    [recogButton.titleLabel setFont:[UIFont systemFontOfSize:24]];
    [recogButton setTitle:@"识别" forState:UIControlStateNormal];
    [recogButton setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [recogButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [recogButton addTarget:self action:@selector(recogButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [[recogButton layer] setBorderColor:[[UIColor blueColor] CGColor]];
    [[recogButton layer] setBorderWidth:1];
    [self.view addSubview:recogButton];
    
    [self setupRecorder];
}

- (void)setupRecorder  {
    NSString *pathOfRecordingFile = [self audioRecordingPath];
    NSURL *audioRecordingUrl = [NSURL fileURLWithPath:pathOfRecordingFile];
//    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat:16000.0],
//                               AVFormatIDKey:            [NSNumber numberWithInt:kAudioFormatAppleLossless],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatLinearPCM],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt:2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt:AVAudioQualityMin]};
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:audioRecordingUrl settings:settings error:&error];
    _recorder.delegate = self;
    
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}

- (IBAction)recordButtonDidClick:(id)sender {
    BOOL success = [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    success = [self.recorder record];
    
    if (!_waverView) {
        CGFloat originX = -50; //将波纹的起始点挪至界面外
        CGFloat viewHeight = 50;
        //定制
        _waverView = [[WaverView alloc] initWithFrame:CGRectMake(originX, CGRectGetHeight(self.view.bounds)/2.0 - viewHeight, CGRectGetWidth(self.view.bounds) + 2 * ABS(originX), viewHeight * 2)];
    }
    __block AVAudioRecorder *weakRecorder = self.recorder;
    _waverView.waverLevelCallback = ^(WaverView *waverView) {
        [weakRecorder updateMeters];
        CGFloat normalizedValue = pow (10, [weakRecorder averagePowerForChannel:0] / 40);
        waverView.level = normalizedValue;
        
    };
    [self.view addSubview:_waverView];
}

- (IBAction)recogButtonDidClick:(id)sender {
     [_recorder stop];
}

//设置录制的音频文件的位置
- (NSString *)audioRecordingPath {
    NSString *result = nil;
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsFolde = [folders objectAtIndex:0];
//    result = [documentsFolde stringByAppendingPathComponent:@"Recording.m4a"];
    result = [documentsFolde stringByAppendingPathComponent:@"Recording.pcm"];
    return result;
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSLog(@"录音完成！");
        dsb::EventDetection ed;
        NSString *kRecordTonePath = @"data/";
        NSString *kRecordToneFileEx = @".cfg";
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *path = [bundle.bundlePath stringByAppendingString:@"/data/ed.cfg"];
//        NSString *path = [bundle pathForResource:@"fbank" ofType:kRecordToneFileEx inDirectory:kRecordTonePath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSData *data = [[NSData alloc] init];
        data = [fm contentsAtPath:path];
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        int ret = ed.Init();
        NSString *ed_conf_ = [bundle.bundlePath stringByAppendingString:@"/data/ed.cfg"];
        NSString *model_file_ = [bundle.bundlePath stringByAppendingString:@"/data/safety_belt.model"];
        int ret = ed.Init([ed_conf_ cStringUsingEncoding:NSASCIIStringEncoding], [model_file_ cStringUsingEncoding:NSASCIIStringEncoding]);
        if(ret != 0) {
            NSLog(@"Fail to init EventDetection");
//            return;
        }
        NSString *feat_conf_ = [bundle.bundlePath stringByAppendingString:@"/data/fbank.cfg"];
//        int result = ed.Detect([[self audioRecordingPath] cStringUsingEncoding:NSASCIIStringEncoding]);
        NSString *recordPath = [self audioRecordingPath];
//        NSString *recordPath = [bundle.bundlePath stringByAppendingString:@"/pcm/safety_belt_1.pcm"];
        int result = ed.Detect([recordPath cStringUsingEncoding:NSASCIIStringEncoding], [feat_conf_ cStringUsingEncoding:NSASCIIStringEncoding]);
        NSLog(@"Detect result:%d", result);
        //1s后消失
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0/*延迟执行时间*/ * NSEC_PER_SEC));
        if (result == 0) {
            if (!_alertView) {
                _alertView = [[UIAlertView alloc] init];
                [_alertView setTitle:[NSString stringWithFormat:@"安全带未系住"]];
            }
            [_alertView show];
            
            __block UIAlertView *weakAlertView = _alertView;
            dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                [weakAlertView dismissWithClickedButtonIndex:0 animated:YES];
            });
        } else {
            if (!_imageView) {
                CGFloat imageViewWidth = 200;
                CGFloat imageViewHeight = 100;
                CGPoint imageViewCenter = self.view.center;
                _imageView = [[UIImageView alloc] initWithFrame:(CGRect){0, 0, imageViewWidth, imageViewHeight}];
                [_imageView setBackgroundColor:[UIColor whiteColor]];
                [_imageView setCenter:imageViewCenter];
                [_imageView setImage:[UIImage imageNamed:@"redBag.png"]];
                [self.view addSubview:_imageView];
            }
            _imageView.hidden = NO;
            
            __block UIImageView *weakImageView = _imageView;
            dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                weakImageView.hidden = YES;
            });
        }
        
        //播放语音
        NSError *playbackError = nil;
        NSError *readingError = nil;
        NSData *fileData = [NSData dataWithContentsOfFile:recordPath options:NSDataReadingMapped error:&readingError];
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithData:fileData
                                                                 error:&playbackError];
        if (newPlayer != nil) {
//            newPlayer.delegate = self;
            if ([newPlayer prepareToPlay] == YES &&
                [newPlayer play] == YES) {
                NSLog(@"开始播放录制的音频！");
            } else {
                NSLog(@"不能播放录制的音频！");
            }
        }else {
            NSLog(@"音频播放失败！");
        }
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
