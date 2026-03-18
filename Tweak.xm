#import <UIKit/UIKit.h>
#import <UnityAds/UnityAds.h>

// ==========================================
// 🔴 配置區：填入你的 Unity 資訊
// ==========================================
NSString *const myGameId = @"5059216";    // 你的 Game ID
NSString *const myAdUnitId = @"test0318"; // 你的 Ad Unit ID (Placement ID)

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

// SDK 初始化成功
- (void)initializationComplete {
    NSLog(@"[IPA918] 🟢 Unity SDK 初始化成功！開始預載廣告...");
    [UnityAds load:myAdUnitId loadDelegate:self];
}

// SDK 初始化失敗
- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 Unity SDK 初始化失敗: %@", message);
}

// 廣告載入成功
- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] 🟢 廣告影片載入完畢！隨時可以播放。");
}

// 廣告載入失敗
- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", message);
}

// 廣告播放完畢 (⚠️ 這裡已修正為最新版的 withFinishState)
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
// 🚀 注入點：Hook 系統方法
// ==========================================

%hook UIApplication
// 在 App 啟動時初始化 Unity Ads
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig; 
    
    NSLog(@"[IPA918] 正在初始化 Unity Ads 引擎...");
    // 啟動初始化程序
    [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
    
    return YES;
}
%end

%hook UIViewController
// 攔截畫面載入，執行 5 秒倒數邏輯
- (void)viewDidAppear:(BOOL)animated {
    %orig; 
    
    // 使用 static 確保這個自動跳轉邏輯在 App 啟動後只執行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[IPA918] ⏱️ 偵測到畫面載入，5 秒倒數開始...");
        
        // 延遲 5.0 秒執行
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"[IPA918] 🎯 時間到！嘗試呼叫廣告播放...");
            // 呼叫播放，並帶入 Helper 作為代理
            [UnityAds show:self placementId:myAdUnitId showDelegate:[UnityAdsHelper sharedInstance]];
            
        });
    });
}
%end
