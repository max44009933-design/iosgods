#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO; // 🌟 復活：追蹤開局廣告是否準備好
static BOOL isInterstitialReady = NO; 
static BOOL hasPlayedStartupAd = NO; 

// ==========================================
// 🌟 Start.io 廣告助手
// ==========================================
@interface StartAppHelper : NSObject <STADelegateProtocol>
@property (nonatomic, strong) STAStartAppAd *startupAd; // 🌟 復活：開局專用廣告
@property (nonatomic, strong) STAStartAppAd *returnAd;  // 返回插頁廣告
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

// --- 🌟 60分鐘冷卻時間檢查邏輯 ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 3600 秒 = 60 分鐘
    if (currentTime - lastShowTime >= 3600) {
        return YES;
    }
    
    int remainingMins = (3600 - (currentTime - lastShowTime)) / 60;
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
    NSLog(@"[IPA918] 🚀 開始初始化 Start.io SDK...");
    STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
    sdk.appID = myStartAppId;
    
    
    // 🌟 復活：同時預載「開局廣告」與「返回廣告」
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadAdWithDelegate:self];
    
    self.returnAd = [[STAStartAppAd alloc] init];
    [self.returnAd loadAdWithDelegate:self];
}

// 廣告載入成功
- (void)didLoadAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] ✅ 廣告下載完成！");
    if (ad == self.startupAd) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; // 下載完剛好倒數也到了的話就直接播
    } else if (ad == self.returnAd) {
        isInterstitialReady = YES;
    }
}

// 廣告載入失敗
- (void)failedLoadAd:(STAAbstractAd *)ad withError:(NSError *)error {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", error.localizedDescription);
    if (ad == self.startupAd) {
        isAdReadyToShow = NO;
    } else if (ad == self.returnAd) {
        isInterstitialReady = NO;
    }
}

// 🌟 開局 10 秒廣告：回歸最穩定的一般插頁播法
- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow && !hasPlayedStartupAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] 🎬 條件達成，開始播放 Start.io 開局插頁廣告！");
            hasPlayedStartupAd = YES; 
            [self.startupAd showAd];
        });
    }
}

// 🌟 返回插頁廣告：套用你的專屬冷卻邏輯
- (void)tryShowReturnInterstitial {
    if ([self canShowReturnInterstitial]) {
        if (isInterstitialReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[IPA918] 🎬 觸發背景返回插頁廣告！");
                [self.returnAd showAd];
            });
        } else {
            NSLog(@"[IPA918] ⏳ 返回廣告還沒 Ready，重新載入中...");
            [self.returnAd loadAdWithDelegate:self];
        }
    }
}

// 廣告關閉後重新計時
- (void)didCloseAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] 💰 廣告已關閉！");
    if (ad == self.returnAd) {
        NSLog(@"[IPA918] ⏱️ 啟動 60 分鐘冷卻機制");
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        [self.returnAd loadAdWithDelegate:self];
    }
}

- (void)failedShowAd:(STAAbstractAd *)ad withError:(NSError *)error {
    NSLog(@"[IPA918] 🔴 廣告播放失敗: %@", error.localizedDescription);
}

@end

// ==========================================
// 🚀 核心注入點 (保留所有暖機與倒數功能)
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    // 1. 監聽 App 剛啟動
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 🌟 7 秒遊戲暖機
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 7秒暖機完畢，初始化 Start.io！");
            [[StartAppHelper sharedInstance] initializeStartApp];
        });
        
        // 🌟 10 秒開局倒數觸發
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            [[StartAppHelper sharedInstance] tryTriggerBulldozeShow];
        });
    }];
    
    // 2. 監聽 App 從背景切換回前景
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[IPA918] 🔄 玩家從背景返回遊戲！");
        [[StartAppHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
