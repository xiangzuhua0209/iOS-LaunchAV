//
//  AVPlayerVC.m
//  LuanceVedio
//
//  Created by DayHR on 2017/5/26.
//  Copyright © 2017年 xiangzuhua. All rights reserved.
//

#import "AVPlayerVC.h"
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "AppDelegate.h"
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kIsFirstLunchApp @"isFirstLunchApp"
@interface AVPlayerVC ()
//播放开始之前的图片
@property(nonatomic,strong)UIImageView * startPlayerImageView;
//播放中断时的图片
@property(nonatomic,strong)UIImageView * pausePlayerImageView;
//进入应用按钮
@property(nonatomic,strong)UIButton * enterMainButton;
//是否第一次进入App
@property(nonatomic,assign)BOOL isFirstLunchApp;
@end

@implementation AVPlayerVC
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.player) {
        self.player = nil;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}
#pragma mark -- 初始化视图
-(void)initView{
    //添加一个图片，在视频播放之前放一张图片，这张图片和LunchScreen.storyboard中的相同,这样的话效果看起来连贯
    self.startPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lauch"]];
    self.startPlayerImageView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [self.contentOverlayView addSubview:self.startPlayerImageView];
    /*对于contentOverlayView 官方解释是这样的：A view displayed between the video content and the playback controls.*/
    //第一次进入软件播放长一点的视频，并且带有“进入应用的按钮”；第二次进入软件播放短一点的视频，并且无进入按钮
    self.isFirstLunchApp = [[NSUserDefaults standardUserDefaults] boolForKey:kIsFirstLunchApp];
    if (!self.isFirstLunchApp) {//第一次启动软件
        //添加“进入应用”按钮
        [self addEnterButton];
    }
    //添加监听通知
    [self addNotification];
    //初始化视频
    [self prepareAV];
}
//添加通知
-(void)addNotification{
    //添加播放器的几个通知--1.播放开始的时候，要删掉开始的占位图，如果是第一次进入应用，在没有点击“进入应用”时，需要循环播放
    if (self.isFirstLunchApp) {
        //第二次进入app视频需要直接结束
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackComplete) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];//视频播放结束时添加通知
    }else {
        //第一次进入app视频需要轮播
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackAgain) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];//视频播放结束时添加通知
    }
    //播放开始
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStart) name:AVPlayerItemTimeJumpedNotification object:nil];
}
//初始化播放器
-(void)prepareAV{
    //首次运行
    NSString *filePath = nil;
    if (!self.isFirstLunchApp) {//没有值，说明是第一次
        //第一次安装
        filePath = [[NSBundle mainBundle] pathForResource:@"opening_long_1080*1920.mp4" ofType:nil];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsFirstLunchApp];
    }else {
        filePath = [[NSBundle mainBundle] pathForResource:@"opening_short_1080*1920.mp4" ofType:nil];
    }
    //初始化player
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    self.showsPlaybackControls = NO;
    //播放视频
    [self.player play];
}
-(void)addEnterButton{
    self.enterMainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _enterMainButton.frame = CGRectMake(24, kScreenHeight - 32 - 48, kScreenWidth - 48, 48);
    _enterMainButton.layer.borderWidth =1;
    _enterMainButton.layer.cornerRadius = 24;
    _enterMainButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [_enterMainButton setTitle:@"进入应用" forState:UIControlStateNormal];
    [self.view addSubview:_enterMainButton];
    [_enterMainButton addTarget:self action:@selector(enterMainAction:) forControlEvents:UIControlEventTouchUpInside];
    _enterMainButton.hidden = YES;//先设置为隐藏，等过三秒的时间在显示该按钮，
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _enterMainButton.hidden = NO;
    });
}
#pragma mark -- 点击事件及通知事件
//进入按钮点击事件
-(void)enterMainAction:(UIButton*)sender{
    //暂停播放
    [self.player pause];
    //添加一个imageView,用于放置暂停播放时的图片
    self.pausePlayerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    [self.contentOverlayView addSubview:self.pausePlayerImageView];
    self.pausePlayerImageView.contentMode = UIViewContentModeScaleAspectFit;//设置
    //截图并展示截图
    [self getoverPlayerImage];
    //播放结束要移除相关的对象
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moviePlaybackComplete];
    });
    
}
//结束播放删除对应的对象和注销通知事件
-(void)moviePlaybackComplete{
    //移除播放前的占位图
    [self.startPlayerImageView removeFromSuperview];
    self.startPlayerImageView = nil;
    //移除暂停播放的占位图
    [self.pausePlayerImageView removeFromSuperview];
    self.pausePlayerImageView = nil;
    //跳转到新界面
    [self pushToNewController];
}
//循环播放事件
-(void)moviePlaybackAgain{
    //添加播放前的占位图
    self.startPlayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lauchAgain"]];
    _startPlayerImageView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [self.contentOverlayView addSubview:_startPlayerImageView];
    [self.pausePlayerImageView removeFromSuperview];
    self.pausePlayerImageView = nil;
    //初始化player
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"opening_long_1080*1920.mp4" ofType:nil];
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    self.showsPlaybackControls = NO;
    //播放视频
    [self.player play];
}
//开始播放通知事件
- (void)moviePlaybackStart {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.startPlayerImageView removeFromSuperview];
        self.startPlayerImageView = nil;
    });
}
#pragma mark -- 私有方法
//获取截图
- (void)getoverPlayerImage {
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:self.player.currentItem.asset];
    gen.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CMTime actualTime;
    CMTime now = self.player.currentTime;
    [gen setRequestedTimeToleranceAfter:kCMTimeZero];
    [gen setRequestedTimeToleranceBefore:kCMTimeZero];
    CGImageRef image = [gen copyCGImageAtTime:now actualTime:&actualTime error:&error];
    if (!error) {
        UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
        self.pausePlayerImageView.image = thumb;
    }
    NSLog(@"%f , %f",CMTimeGetSeconds(now),CMTimeGetSeconds(actualTime));
    NSLog(@"%@",error);
}
//跳转到新的控制器
-(void)pushToNewController{
    AppDelegate * appde = (AppDelegate*)[UIApplication sharedApplication].delegate;
    UIViewController * mainC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    appde.window.rootViewController = mainC;
    [appde.window makeKeyWindow];
}


@end
