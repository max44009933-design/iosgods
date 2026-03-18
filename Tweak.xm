#import <UIKit/UIKit.h>
#import <UnityAds/UnityAds.h>

// 🔴 你的專屬 ID
NSString *const myGameId = @"6069216";
NSString *const myAdUnitId = @"test0318";

// ==========================================
// 🌟 廣告助手：負責處理載入與顯示的回報
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
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

- (void)initializationComplete {
    NSLog(@"[IPA918] 🟢 Unity SDK 初始化成功！開始預載廣告...");
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 Unity SDK 初始化失敗: %@", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] 🟢 廣告影片載入完畢！隨時可以發射！");
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", message);
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 🎬 廣告播放完成！");
}

- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放失敗: %@", message);
}

- (void)unityAdsShowStart:(NSString *)placementId {
    NSLog(@"[IPA918] 🎬 廣告開始顯示");
}

- (void)unityAdsShowClick:(NSString *)placementId {
    NSLog(@"[IPA918] 👆 用戶點擊了廣告");
}
@end

// ==========================================
// 🚀 核心注入點：App 啟動時直接霸王硬上弓！
// ==========================================

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig; 
    
    NSLog(@"[IPA918] 🚀 啟動 Unity Ads 引擎...");
    [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
    
    // 🌟 改變戰術：不管畫面了，App 啟動後直接倒數 10 秒！
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"[IPA918] 🎯 10 秒時間到！尋找最頂層畫面準備轟炸...");
        
        // 🌟 修正：使用 iOS 13+ 的最新語法來抓取 Window，避免編譯器報錯
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
        
        // 如果是舊版系統，用安全降級寫法
        if (!keyWindow) {
            keyWindow = [[UIApplication sharedApplication] windows].firstObject;
        }
        
        // 抓取最頂層畫面
        UIViewController *topController = keyWindow.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        
        if (topController) {
            NSLog(@"[IPA918] 抓到頂層畫面了！強制彈出廣告！");
            [UnityAds show:topController placementId:myAdUnitId showDelegate:[UnityAdsHelper sharedInstance]];
        } else {
            NSLog(@"[IPA918] 找不到畫面可以播廣告 QQ");
        }
    });
    
    return YES;
}

%end
