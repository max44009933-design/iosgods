#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "fishhook.h" // 🛡️ 引入底層 Hook 庫防護

// ==========================================
// 🛡️ 不死神盾：沒收遊戲的自殺權力
// ==========================================
static void (*orig_exit)(int);
void my_exit(int s) { NSLog(@"[IPA918] 🛡️ 攔截到 exit(%d)，強行裝死中...", s); }

static int (*orig_kill)(pid_t, int);
int my_kill(pid_t p, int s) { NSLog(@"[IPA918] 🛡️ 攔截到 kill，拒絕自殺！"); return 0; }

// ==========================================
// 🔴 配置區 
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 

static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 抓取頂層畫面 & 彈窗提示神器
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

- (void)initializationComplete {
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 初始化失敗", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 廣告載入失敗", [NSString stringWithFormat:@"單元: %@\n原因: %@", placementId, message]);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        } else {
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
// 🎯 終極神盾：攔截原生系統彈窗的「出生地」
// ==========================================

%hook UIViewController

// 這個方法是 iOS 系統跳出任何原生彈窗所使用的核心方法
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // 1. 檢查這個被彈出的視窗是否為 UIAlertController（iOS 原生彈窗）
    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alertController = (UIAlertController *)viewControllerToPresent;
        NSString *title = alertController.title;
        NSString *message = alertController.message;
        
        // 2. 鎖定 Spoofer 的關鍵字：標題是 "WARNING"，內容有 "tampered with"
        if ([title isEqualToString:@"WARNING"] && [message containsString:@"tampered with"]) {
            // 對上了！我們直接拦截，不執行系統的彈出動作。NSLog 用來在除錯日誌裡確認攔截成功
            NSLog(@"[IPA918] 🎯 發現外掛警告窗，底層攔截成功！不彈出。");
            return; // 💥 直接沒收彈出動作！
        }
    }
    // 3. 如果不符合關鍵字，就讓系統正常執行彈窗（例如廣告助手自己的 UIAlertController）
    %orig(viewControllerToPresent, flag, completion);
}

%end

// ==========================================
// 🚀 核心注入點：監聽系統啟動廣播
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！綁定不死神盾...");
    
    // 1. 綁定不死神盾
    struct rebind_msg h[] = {
        {"exit", (void *)my_exit, (void **)&orig_exit},
        {"kill", (void *)my_kill, (void **)&orig_kill}
    };
    rebind_symbols(h, 2);
    
    // 2. 監聽「App 啟動完成」的系統廣播
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 收到啟動廣播！開始執行 UnityAds 邏輯");
        
        // 1. 初始化 UnityAds (你的完美代碼)
        [UnityAds initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
        
        // 2. 開始 10 秒倒數計時
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            
            if (!isAdReadyToShow) {
                showDebugAlert(@"⏱️ 10秒到了", @"廣告正在努力下載中，如果一直沒出來可能是網路或後台設定問題。");
            } else {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            }
        });
        
    }];
}
