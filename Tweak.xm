#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>

// ==========================================
// 🔴 配置區 (一般 APP 正式廣告版)
// ==========================================
// ⚠️ 記得換成你新專案的 Game ID 和 廣告單元 ID
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"iosapp"; 

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

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

// --- UnityAds 廣告邏輯 (靜默除錯) ---
- (void)initializationComplete {
    NSLog(@"[IPA918] ✅ UnityAds 初始化成功！");
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 UnityAds 初始化失敗: %@", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] ✅ 廣告下載完成！");
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", message);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            NSLog(@"[IPA918] 🎬 條件達成，開始播放廣告！");
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 💰 廣告播放完畢！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放失敗: %@", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 啟動廣播到達！");
        
        // 🌟 防卡死機制：讓大型 App 先載入 7 秒鐘喘口氣，再來初始化 UnityAds！
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 遊戲暖機完畢，開始初始化 UnityAds！");
            [UnityAds initialize:myGameId testMode:NO initializationDelegate:[UnityAdsHelper sharedInstance]];
        });
        
        // 🌟 10 秒倒數播放 (從 App 打開那一刻算起)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            if (isAdReadyToShow) {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            } else {
                NSLog(@"[IPA918] ⏳ 10秒到了但廣告還沒抓到，等它下載好會自動補放。");
            }
        });
        
    }];
}
