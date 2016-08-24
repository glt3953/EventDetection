//
//  WaverView.m
//  WaverView
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#import "WaverView.h"
#import "UIColor+NingXia.h"

#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
static CGFloat waveOffsetWidth = 0; //各波纹间的偏移值

@interface WaverView ()

@property (nonatomic) CGFloat phase;
@property (nonatomic) CGFloat amplitude; //振幅
@property (nonatomic) NSMutableArray * waves; //波纹
@property (nonatomic) CGFloat waveHeight;
@property (nonatomic) CGFloat waveWidth;
@property (nonatomic) CGFloat waveMid;
@property (nonatomic) CGFloat maxAmplitude;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation WaverView


- (id)init
{
    if(self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.waves = [NSMutableArray new];
    
    self.frequency = 1.2f;
    
    self.amplitude = 1.0f;
    self.idleAmplitude = 0.01f;
    
    self.numberOfWaves = 5;
    self.phaseShift = -0.25f;
    self.density = 1.f;
    
    self.waveColor = [UIColor whiteColor];
    self.mainWaveWidth = 2.0f;
    self.decorativeWavesWidth = 1.0f;
    
	self.waveHeight = CGRectGetHeight(self.bounds);
    self.waveWidth  = CGRectGetWidth(self.bounds);
    self.waveMid    = self.waveWidth / 2.0f;
//    self.maxAmplitude = self.waveHeight - 4.0f;
    self.maxAmplitude = 60;
    
    NSArray *waveLineWidths = @[@2, @1.75, @1.35, @1];
    NSArray *waveStrokeColors = @[[UIColor colorFromHexString:@"#fcc080"], [UIColor colorFromHexString:@"#ffb8b6" alpha:0.8], [UIColor colorFromHexString:@"#fcc080" alpha:0.6], [UIColor colorFromHexString:@"#ffb8b6" alpha:0.4]];
    //定制样式
    for (int i = 0; i < self.numberOfWaves; i++) {
        CAShapeLayer *waveline = [CAShapeLayer layer];
        CGRect frame = self.frame;
        frame.origin.x = -waveOffsetWidth * i; //各波纹的起始点不同
        frame.origin.y = 0;
        frame.size.width += waveOffsetWidth * i;
        [waveline setFrame:frame];
        waveline.lineCap       = kCALineCapButt; //指定线的边缘
        waveline.lineJoin      = kCALineJoinRound;
        waveline.fillColor     = [[UIColor clearColor] CGColor]; //波纹的填充色
        if (waveStrokeColors.count > i) {
            [waveline setLineWidth:[waveLineWidths[i] floatValue]];
            waveline.strokeColor = [waveStrokeColors[i] CGColor]; //指定path的渲染颜色
        }
        [self.layer addSublayer:waveline];
        [self.waves addObject:waveline];
        
        //设置波纹的渐变效果
        NSArray *gradientLayerColors = @[[UIColor colorFromHexString:@"#fcc080"], [UIColor colorFromHexString:@"#ffb8b6"], [UIColor colorFromHexString:@"#fcc080"], [UIColor colorFromHexString:@"#ffb8b6"]];
        CGFloat spaceX = 50;
        CGFloat layerWidth = self.frame.size.width/2 - spaceX;
        CALayer *gradientLayer = [CALayer layer];
        CAGradientLayer *gradientLayer1 = [CAGradientLayer layer];
        gradientLayer1.frame = CGRectMake(spaceX, 0, layerWidth, self.frame.size.height);
        if (gradientLayerColors.count > i) {
            [gradientLayer1 setColors:[NSArray arrayWithObjects:(id)[[gradientLayerColors[i] colorWithAlphaComponent:0.001] CGColor], (id)[gradientLayerColors[i] CGColor], nil]];
        }
//        [gradientLayer1 setLocations:@[@0.5,@0.9,@1 ]];
        [gradientLayer1 setStartPoint:CGPointMake(0, 1)];
        [gradientLayer1 setEndPoint:CGPointMake(1, 1)];
        [gradientLayer addSublayer:gradientLayer1];
        
        CAGradientLayer *gradientLayer2 = [CAGradientLayer layer];
        gradientLayer2.frame = CGRectMake(self.frame.size.width/2, 0, layerWidth, self.frame.size.height);
        if (gradientLayerColors.count > i) {
            [gradientLayer2 setColors:[NSArray arrayWithObjects:(id)[gradientLayerColors[i] CGColor], (id)[[gradientLayerColors[i] colorWithAlphaComponent:0.001] CGColor], nil]];
        }
//        [gradientLayer2 setLocations:@[@0.1,@0.5,@1]];
        [gradientLayer2 setStartPoint:CGPointMake(0, 1)];
        [gradientLayer2 setEndPoint:CGPointMake(1, 1)];
        [gradientLayer addSublayer:gradientLayer2];
        
        [gradientLayer setMask:waveline]; //用waveline来截取渐变层，注释掉可查看渐变层的效果
        [self.layer addSublayer:gradientLayer];
    }
}

- (void)setWaverLevelCallback:(void (^)(WaverView *waverView))waverLevelCallback {
    _waverLevelCallback = waverLevelCallback;

    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(invokeWaveCallback)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)invokeWaveCallback
{
    self.waverLevelCallback(self);
}

- (void)setLevel:(CGFloat)level
{
    _level = level;
    
    self.phase += self.phaseShift; // Move the wave
    
    self.amplitude = fmax(level, self.idleAmplitude);
//    NSLog(@"_level:%f, self.phaseShift:%f, self.phase:%f, self.idleAmplitude:%f, self.amplitude:%f", _level, self.phaseShift, self.phase, self.idleAmplitude, self.amplitude);
    
    [self updateMeters];
}


- (void)updateMeters
{
	self.waveHeight = CGRectGetHeight(self.bounds);
//	self.waveWidth  = CGRectGetWidth(self.bounds);
//	self.waveMid    = self.waveWidth / 2.0f;
//	self.maxAmplitude = self.waveHeight - 4.0f;
    self.maxAmplitude = 60;
	
    UIGraphicsBeginImageContext(self.frame.size);
    
    for (int i = 0; i < self.numberOfWaves; i++) {
        UIBezierPath *wavelinePath = [UIBezierPath bezierPath];
        self.waveWidth  = CGRectGetWidth(self.bounds) + i * waveOffsetWidth;
        self.waveMid    = self.waveWidth / 2.0f;
        
        // Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
        CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
        CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
//        NSLog(@"progress:%f, self.amplitude:%f, normedAmplitude:%f", progress, self.amplitude, normedAmplitude);
        CAShapeLayer *waveline = [self.waves objectAtIndex:i];
        
        //x初始值依赖于self.frame.origin.x
        for (CGFloat x = self.frame.origin.x; x < self.waveWidth + self.density; x += self.density) {
            //Thanks to https://github.com/stefanceriu/SCSiriWaveformView
            // We use a parable to scale the sinus wave, that has its peak in the middle of the view.
            //缩放
            //double pow (double base, double exponent);求base的exponent次方值
            if (self.waveMid == 0) {
                continue;
            }
            CGFloat scaling = -pow(x / self.waveMid  - 1, 2) + 1; // make center bigger
            //sinf：计算正弦值和双曲线的正弦值
            CGFloat y = scaling * self.maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / self.waveWidth) * self.frequency + self.phase) + (self.waveHeight * 0.5);
            
            if (x == self.frame.origin.x) {
                /**
                 *  设置第一个起始点到接收器
                 *  @param point 起点坐标
                 */
                [wavelinePath moveToPoint:CGPointMake(x, y)];
            } else {
                /**
                 *  附加一条直线到接收器的路径
                 *  @param point 要到达的坐标
                 */
                [wavelinePath addLineToPoint:CGPointMake(x, y)];
            }
        }
        
        waveline.path = [wavelinePath CGPath];
    }
    
    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [_displayLink invalidate];
}

@end
