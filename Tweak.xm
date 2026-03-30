#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

// 🌟 正式上線：30分鐘 (1800秒) 新手保護與冷卻時間
#define COOLDOWN_TIME 1800 

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

// --- 🌟 30分鐘新手保護期 + 冷卻邏輯 ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 1. 第一次打開 APP
    double firstLaunchTime = [defaults doubleForKey:@"IPA918_FirstLaunchTime"];
    if (firstLaunchTime == 0) {
        NSLog(@"[IPA918] 🆕 第一次打開 APP！啟動 30 分鐘「免廣告新手保護期」！");
        [defaults setDouble:currentTime forKey:@"IPA918_FirstLaunchTime"];
        [defaults synchronize];
        return NO; 
    }
    
    // 2. 檢查保護期
    if (currentTime - firstLaunchTime < COOLDOWN_TIME) {
        int remaining = (COOLDOWN_TIME - (currentTime - firstLaunchTime)) / 60;
        NSLog(@"[IPA918] 🛡️ 新手保護期中... 剩餘約 %d 分鐘", remaining);
        return NO;
    }
    
    // 3. 檢查返回廣告冷卻
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    if (currentTime - lastShowTime >= COOLDOWN_TIME) {
        return YES; 
    }
    
    int remainingMins = (COOLDOWN_TIME - (currentTime - lastShowTime)) / 60;
    NSLog(@"[IPA918] ⏳ 返回廣告冷卻中... 剩餘約 %d 分鐘", remainingMins);
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
    NSLog(@"[IPA918] 🚀 啟動 Start.io 真實廣告模式...");
    STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
    sdk.appID = myStartAppId;
    
    // 🌟 關閉測試模式，等伺服器派發真廣告！
    sdk.testAdsEnabled = NO; 
    
    // 開局載入獎勵影片 (單價最高)
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadRewardedVideoAdWithDelegate:self];
    
    // 返回載入一般插頁
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
