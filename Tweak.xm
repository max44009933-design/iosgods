#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

// ==========================================
// 🔴 配置區 (一般 APP 正式廣告版)
// ==========================================
// ⚠️ 記得換成你新專案的 Game ID 和 廣告單元 ID
NSString *const myGameId = @"5698859";    
NSString *const myAdUnitId = @"Rewarded_iOS"; 
NSString *const myInterstitialId = @"Interstitial_iOS"; // 🌟 新增：返回時的插頁廣告版位

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO;
static BOOL isInterstitialReady = NO; // 🌟 新增：追蹤返回廣告是否就緒

// ==========================================
// 🛠️ 抓取頂層畫面神器 (播放廣告必備)
// ==========================================
static UIViewController *getTopViewController() {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [[UIApplication sharedApplication] windows].firstObject;
    }
    
    UIViewController *topController = keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

// ==========================================
// 🌟 廣告助手
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)tryShowReturnInterstitial; // 🌟 新增：嘗試播放返回廣告
@end

@implementation UnityAdsHelper

+ (instancetype)sharedInstance {
    static UnityAdsHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[UnityAdsHelper alloc] init];
    });
    return sharedInstance;
}

// --- 🌟 冷卻時間檢查邏輯 ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 60 分鐘 = 3600 秒
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

// --- UnityAds 廣告邏輯 (靜默除錯) ---
- (void)initializationComplete {
    NSLog(@"[IPA918] ✅ UnityAds 初始化成功！");
    // 🌟 同時預載兩種廣告
    [UnityAds load:myAdUnitId loadDelegate:self];
    [UnityAds load:myInterstitialId loadDelegate:self]; 
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 UnityAds 初始化失敗: %@", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] ✅ 廣告下載完成: %@", placementId);
    
    if ([placementId isEqualToString:myAdUnitId]) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; // 嘗試觸發開局廣告
    } else if ([placementId isEqualToString:myInterstitialId]) {
        isInterstitialReady = YES; // 記錄插頁廣告已就緒
    }
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗 (%@): %@", placementId, message);
    if ([placementId isEqualToString:myAdUnitId]) {
        isAdReadyToShow = NO;
    } else if ([placementId isEqualToString:myInterstitialId]) {
        isInterstitialReady = NO;
    }
}

// 原本的 10 秒開局廣告邏輯
- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            NSLog(@"[IPA918] 🎬 條件達成，開始播放開局廣告！");
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        }
    }
}

// 🌟 新增：返回時觸發的插頁廣告邏輯
- (void)tryShowReturnInterstitial {
    // 1. 檢查 60 分鐘冷卻期
    if ([self canShowReturnInterstitial]) {
        // 2. 檢查插頁廣告載好了沒
        if (isInterstitialReady) {
            UIViewController *topController = getTopViewController();
            if (topController) {
                NSLog(@"[IPA918] 🎬 觸發背景返回插頁廣告！");
                [UnityAds show:topController placementId:myInterstitialId showDelegate:self];
            }
        } else {
            NSLog(@"[IPA918] ⏳ 返回廣告尚未 Ready，嘗試重新載入...");
            [UnityAds load:myInterstitialId loadDelegate:self];
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 💰 廣告播放完畢: %@", placementId);
    
    // 如果播放的是返回廣告，紀錄時間並重新載入下一檔
    if ([placementId isEqualToString:myInterstitialId]) {
        NSLog(@"[IPA918] ⏱️ 記錄播放時間，啟動 60 分鐘冷卻機制");
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        // 把下一檔廣告提早載下來備用
        [UnityAds load:myInterstitialId loadDelegate:self];
    }
}

- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放失敗 (%@): %@", placementId, message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    // 1. 監聽 App 剛啟動 (保留你原本的功能)
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 啟動廣播到達！");
        
        // 🌟 防卡死機制：讓 App 先專心開機 7 秒鐘！
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 7秒遊戲暖機完畢，開始初始化並下載 UnityAds 廣告！");
            [UnityAds initialize:myGameId testMode:NO initializationDelegate:[UnityAdsHelper sharedInstance]];
        });
        
        // 🌟 10 秒倒數播放 (從 App 打開那一刻算起)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            if (isAdReadyToShow) {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            } else {
                NSLog(@"[IPA918] ⏳ 10秒到了但廣告還沒下載完，等它準備好會自動補放。");
            }
        });
        
    }];
    
    // 2. 🌟 新增：監聽 App 從背景切換回前景
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[IPA918] 🔄 玩家從背景返回遊戲！");
        [[UnityAdsHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
