#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <dlfcn.h> 
#import "fishhook.h" 

// ==========================================
// 🛡️ 不死神盾：沒收遊戲的自殺權力
// ==========================================
static void (*orig_exit)(int);
void my_exit(int s) { NSLog(@"[IPA918] 🛡️ 攔截到 exit(%d)，強行裝死中...", s); }

static int (*orig_kill)(pid_t, int);
int my_kill(pid_t p, int s) { NSLog(@"[IPA918] 🛡️ 攔截到 kill，拒絕自殺！"); return 0; }

// ==========================================
// 📺 欺騙編譯器：手動宣告 UnityAds 接口
// ==========================================
@interface UnityAds : NSObject
+ (void)initialize:(NSString *)gameId testMode:(BOOL)testMode initializationDelegate:(id)delegate;
+ (void)load:(NSString *)placementId loadDelegate:(id)delegate;
+ (void)show:(UIViewController *)viewController placementId:(NSString *)placementId showDelegate:(id)delegate;
@end

@protocol UnityAdsInitializationDelegate <NSObject>
- (void)initializationComplete;
- (void)initializationFailed:(int)error withMessage:(NSString *)message;
@end
@protocol UnityAdsLoadDelegate <NSObject>
- (void)unityAdsAdLoaded:(NSString *)placementId;
- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(int)error withMessage:(NSString *)message;
@end
@protocol UnityAdsShowDelegate <NSObject>
- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(int)state;
- (void)unityAdsShowFailed:(NSString *)placementId withError:(int)error withMessage:(NSString *)message;
- (void)unityAdsShowStart:(NSString *)placementId;
- (void)unityAdsShowClick:(NSString *)placementId;
@end

// ==========================================
// 🔴 配置區 
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 

static BOOL isTenSecondTimerExpired = NO;
static BOOL isAdReadyToShow = NO;

// ==========================================
// 🛠️ 輔助工具：抓取頂層畫面 & 彈窗提示
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
// 🌟 廣告助手 + 彈窗抹除雷達
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)startRadar;
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
    Class unityCls = NSClassFromString(@"UnityAds");
    if (unityCls) [unityCls load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(int)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 初始化失敗", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(int)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 廣告載入失敗", [NSString stringWithFormat:@"單元: %@\n原因: %@", placementId, message]);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        Class unityCls = NSClassFromString(@"UnityAds");
        if (topController && unityCls) {
            [unityCls show:topController placementId:myAdUnitId showDelegate:self];
        } else {
            showDebugAlert(@"🔴 播放失敗", @"找不到最頂層的畫面來播放廣告");
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(int)state {
    showDebugAlert(@"🎬 測試成功", @"廣告順利播放完畢！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(int)error withMessage:(NSString *)message {
    showDebugAlert(@"🔴 播放失敗", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

- (void)startRadar {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (UIWindow *window in [UIApplication sharedApplication].windows) {
                    for (UIView *subview in window.subviews) {
                        NSString *viewText = [UnityAdsHelper extractAllTextFromView:subview];
                        if ([viewText containsString:@"WARNING"] && [viewText containsString:@"tampered with"]) {
                            NSLog(@"[IPA918] 發現外掛警告窗，執行抹除！");
                            subview.hidden = YES;
                            [subview removeFromSuperview];
                        }
                    }
                }
            });
        }];
    });
}

+ (NSString *)extractAllTextFromView:(UIView *)view {
    NSMutableString *fullText = [NSMutableString string];
    if ([view isKindOfClass:[UILabel class]]) [fullText appendFormat:@"%@ ", ((UILabel *)view).text];
    else if ([view isKindOfClass:[UITextView class]]) [fullText appendFormat:@"%@ ", ((UITextView *)view).text];
    else if ([view isKindOfClass:[UIButton class]]) [fullText appendFormat:@"%@ ", ((UIButton *)view).titleLabel.text];
    for (UIView *subview in view.subviews) [fullText appendString:[self extractAllTextFromView:subview]];
    return fullText;
}
@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    // 1. 綁定不死神盾
    struct rebind_msg h[] = {
        {"exit", (void *)my_exit, (void **)&orig_exit},
        {"kill", (void *)my_kill, (void **)&orig_kill}
    };
    rebind_symbols(h, 2);
    
    // 2. 根目錄 ( / ) 物理路徑載入
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *frameworkPath = [bundlePath stringByAppendingPathComponent:@"UnityAds.framework/UnityAds"];
    void *handle = dlopen(frameworkPath.UTF8String, RTLD_NOW);
    
    // 🌟 修正：檢查 handle 是否載入成功，防止 unused variable 報錯
    if (!handle) {
        NSLog(@"[IPA918] ⚠️ dlopen 載入失敗，錯誤資訊: %s", dlerror());
    } else {
        NSLog(@"[IPA918] ✅ UnityAds 物理載入成功，位址: %p", handle);
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 啟動雷達與廣告初始化
        [[UnityAdsHelper sharedInstance] startRadar];
        Class unityCls = NSClassFromString(@"UnityAds");
        if (unityCls) {
            [unityCls initialize:myGameId testMode:YES initializationDelegate:[UnityAdsHelper sharedInstance]];
        } else {
            showDebugAlert(@"🔴 致命錯誤", @"根目錄找不到 UnityAds.framework！請確認 ESign 注入設定為根目錄 ( / )。");
        }
        
        // 10 秒後嘗試播放廣告
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
        });
    }];
}
