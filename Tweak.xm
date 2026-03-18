#import <UIKit/UIKit.h>
#import <UnityAds/UnityAds.h>

// ==========================================
// 🔴 配置區 
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 

static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 新增功能：抓取頂層畫面 & 彈窗提示神器
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

static void showDebugAlert(NSString *title, NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = getTopViewController();
        if (top) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"了解" style:UIAlertActionStyleDefault handler:nil]];
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

// ==========================================
// 🌟 廣告助手：處理載入與回報 (保留原有功能，加入彈窗)
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

- (void)initializationComplete {
    NSLog(@"[IPA918] 🟢 初始化成功！");
    // 不彈窗干擾，默默去 Load 廣告
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    // ⚠️ 新增功能：失敗時彈窗警告
    showDebugAlert(@"🔴 初始化失敗", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] 🟢 廣告載入完畢！");
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    // ⚠️ 新增功能：載入失敗時彈窗警告
    showDebugAlert(@"🔴 廣告載入失敗", [NSString stringWithFormat:@"單元: %@\n原因: %@", placementId, message]);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            // 成功抓到畫面，強制播放！
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        } else {
            // ⚠️ 新增功能：找不到畫面時彈窗
            showDebugAlert(@"🔴 播放失敗", @"找不到最頂層的畫面來播放廣告");
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    showDebugAlert(@"🎬 測試成功", @"廣告順利播放完畢！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 播放失敗", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig; 
    
    [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
    
    // 10 秒倒數計時
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isTenSecondTimerExpired = YES; 
        
        if (!isAdReadyToShow) {
            // ⚠️ 新增功能：10秒到了但還沒 Load 好，彈窗告知
            showDebugAlert(@"⏱️ 10秒到了", @"但廣告還在下載中或載入失敗，請稍候...");
        } else {
            [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
        }
    });
    
    return YES;
}

%end
