#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

// 🌟 測試用冷卻時間：30 秒 (確認會跳廣告後，再改回 1800)
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
    
    // 🌟 確保關閉測試模式，挑戰真實廣告！
    sdk.testAdsEnabled = NO; 
    
    // 載入開局插頁
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadAdWithDelegate:self];
    
    // 預載返回插頁
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
            NSLog(@"[IPA918] 🎬 播放開局插頁廣告！");
            hasPlayedStartupAd = YES; 
            [self.startupAd showAd];
        });
    }
}

- (void)tryShowReturnInterstitial {
    if ([self canShowReturnInterstitial]) {
        if (isInterstitialReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[IPA918] 🎬 播放返回插頁廣告！");
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
// 🚀 核心注入點 (安全暖機模式)
// ==========================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 🌟 打開後 7 秒開始初始化（閃退高風險期已過，安全！）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[StartAppHelper sharedInstance] initializeStartApp];
        });

        // 🌟 15 秒開局觸發
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
