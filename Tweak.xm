#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

// 🌟 測試用冷卻時間：30 秒 
#define COOLDOWN_TIME 30 

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO; 
static BOOL isInterstitialReady = NO; 
static BOOL hasPlayedStartupAd = NO; 

@interface StartAppHelper : NSObject <STADelegateProtocol>
@property (nonatomic, strong) STAStartAppAd *startupAd; 
@property (nonatomic, strong) STAStartAppAd *returnAd;  
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)tryShowReturnInterstitial; 
@end

@implementation StartAppHelper

+ (instancetype)sharedInstance {
    static StartAppHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StartAppHelper alloc] init];
    });
    return sharedInstance;
}

// --- 🌟 30秒新手保護期 (測試用邏輯) ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    double firstLaunchTime = [defaults doubleForKey:@"IPA918_FirstLaunchTime"];
    if (firstLaunchTime == 0) {
        [defaults setDouble:currentTime forKey:@"IPA918_FirstLaunchTime"];
        [defaults synchronize];
        return NO; 
    }
    
    if (currentTime - firstLaunchTime < COOLDOWN_TIME) {
        return NO;
    }
    
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    if (currentTime - lastShowTime >= COOLDOWN_TIME) {
        return YES; 
    }
    return NO;
}

- (void)recordInterstitialShowTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    [defaults setDouble:currentTime forKey:@"IPA918_LastReturnAdTime"];
    [defaults synchronize];
}

// --- 🚀 初始化與廣告載入 ---
- (void)initializeStartApp {
    NSLog(@"[IPA918] 🚀 初始化 Start.io...");
    STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
    sdk.appID = myStartAppId;
    
    // 🌟 1. 強制打開測試模式！(我們要找回上次成功彈出測試的那個畫面)
    sdk.testAdsEnabled = YES; 
    
    // 🌟 2. 換回之前 100% 成功彈出的「獎勵影片」載入法
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadRewardedVideoAdWithDelegate:self];
    
    // 返回插頁保持原樣
    self.returnAd = [[STAStartAppAd alloc] init];
    [self.returnAd loadAdWithDelegate:self];
}

- (void)didLoadAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] ✅ 廣告下載完成！");
    if (ad == self.startupAd) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; 
    } else if (ad == self.returnAd) {
        isInterstitialReady = YES;
    }
}

- (void)failedLoadAd:(STAAbstractAd *)ad withError:(NSError *)error {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", error.localizedDescription);
}

- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow && !hasPlayedStartupAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] 🎬 播放開局廣告！");
            hasPlayedStartupAd = YES; 
            [self.startupAd showAd];
        });
    }
}

- (void)tryShowReturnInterstitial {
    if ([self canShowReturnInterstitial]) {
        if (isInterstitialReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[IPA918] 🎬 播放返回廣告！");
                [self.returnAd showAd];
            });
        } else {
            [self.returnAd loadAdWithDelegate:self];
        }
    }
}

- (void)didCloseAd:(STAAbstractAd *)ad {
    if (ad == self.returnAd) {
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        [self.returnAd loadAdWithDelegate:self];
    }
}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 🌟 退回原本最完美的 7 秒暖機 + 10 秒倒數
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[StartAppHelper sharedInstance] initializeStartApp];
        });

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            [[StartAppHelper sharedInstance] tryTriggerBulldozeShow];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[StartAppHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
