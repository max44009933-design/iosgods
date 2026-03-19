#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import "fishhook.h" // 🌟 引入底層 Hook 庫防護

// ==========================================
// 🛡️ 不死神盾：沒收遊戲的自殺權力
// ==========================================
static void (*orig_exit)(int);
void my_exit(int s) { NSLog(@"[IPA918] 🛡️ 攔截到 exit(%d)，強行裝死中...", s); }

static int (*orig_kill)(pid_t, int);
int my_kill(pid_t p, int s) { NSLog(@"[IPA918] 🛡️ 攔截到 kill，拒絕自殺！"); return 0; }

// ==========================================
// 🔴 配置區 (正式上線賺錢版)
// ==========================================
NSString *const myGameId = @"6069216";    
NSString *const myAdUnitId = @"test0318"; 

static BOOL isTenSecondTimerExpired = NO;
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
// 🌟 廣告助手 + 無敵防護雷達
// ==========================================
@interface UnityAdsHelper : NSObject <UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate>
+ (instancetype)sharedInstance;
- (void)tryTriggerBulldozeShow; 
- (void)startRadar;
- (void)scanAndWipe:(UIView *)view; 
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
    NSLog(@"[IPA918] ✅ UnityAds 正式版初始化成功！準備載入廣告...");
    [UnityAds load:myAdUnitId loadDelegate:self];
}

- (void)initializationFailed:(UnityAdsInitializationError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 UnityAds 初始化失敗: %@", message);
}

- (void)unityAdsAdLoaded:(NSString *)placementId {
    NSLog(@"[IPA918] ✅ 廣告影片已下載完成，隨時可以播放！");
    isAdReadyToShow = YES;
    [self tryTriggerBulldozeShow]; 
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", message);
    isAdReadyToShow = NO;
}

- (void)tryTriggerBulldozeShow {
    if (isTenSecondTimerExpired && isAdReadyToShow) {
        UIViewController *topController = getTopViewController();
        if (topController) {
            NSLog(@"[IPA918] 🎬 條件達成，開始播放正式廣告！");
            [UnityAds show:topController placementId:myAdUnitId showDelegate:self];
        } else {
            NSLog(@"[IPA918] 🔴 找不到最頂層畫面，放棄播放。");
        }
    }
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
    NSLog(@"[IPA918] 💰 廣告播放完畢！準備收錢！");
}
- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
    NSLog(@"[IPA918] 🔴 廣告播放中斷/失敗: %@", message);
}
- (void)unityAdsShowStart:(NSString *)placementId {}
- (void)unityAdsShowClick:(NSString *)placementId {}

// --- 🎯 無敵防護雷達：默默粉碎隱形觸控牆 ---
- (void)startRadar {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    NSArray *windows = [[UIApplication sharedApplication].windows copy];
                    for (UIWindow *window in windows) { 
                        NSString *windowClass = NSStringFromClass([window class]);
                        // 略過系統鍵盤與安全視窗，避免誤殺
                        if ([windowClass containsString:@"Remote"] || 
                            [windowClass containsString:@"Keyboard"] || 
                            [windowClass containsString:@"TextEffects"] || 
                            [windowClass containsString:@"Host"] || 
                            [windowClass containsString:@"Secure"]) {
                            continue; 
                        }
                        [self scanAndWipe:window]; 
                    }
                } @catch (NSException *e) {}
            });
        }];
    });
}

- (void)scanAndWipe:(UIView *)view {
    @try {
        if (!view || view.hidden) return; 

        NSString *txt = nil;
        if ([view isKindOfClass:[UILabel class]]) txt = ((UILabel *)view).text;
        else if ([view isKindOfClass:[UIButton class]]) txt = ((UIButton *)view).titleLabel.text;

        if (txt && txt.length > 0) {
            // 鎖定外掛警告窗的關鍵字
            if ([txt containsString:@"tampered"] || [txt containsString:@"injected"] || 
                [txt isEqualToString:@"Understood"] || [txt isEqualToString:@"WARNING"]) {
                
                // 往上尋找外掛鋪設的隱形全螢幕玻璃
                UIView *shield = view;
                while (shield.superview) {
                    UIView *parent = shield.superview;
                    NSString *parentClass = NSStringFromClass([parent class]);
                    
                    // 邊界防禦：碰到遊戲主畫布就停下來
                    if ([parent isKindOfClass:[UIWindow class]]) break;
                    if (parent == parent.window.rootViewController.view) break;
                    if ([parentClass containsString:@"Unity"]) break;
                    if ([parentClass containsString:@"Transition"]) break;
                    if ([parentClass containsString:@"DropShadow"]) break;
                    
                    shield = parent;
                }
                
                NSLog(@"[IPA918] 🎯 默默拔除外掛警告窗，深藏功與名！");
                shield.hidden = YES;
                shield.userInteractionEnabled = NO;
                shield.alpha = 0.0;
                shield.frame = CGRectMake(-9999, -9999, 1, 1); 
                [shield removeFromSuperview];
            }
        }
        
        NSArray *subs = [view.subviews copy];
        for (UIView *sub in subs) {
            [self scanAndWipe:sub];
        }
    } @catch (NSException *e) {}
}

@end

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
        
        NSLog(@"[IPA918] 📢 啟動廣播到達！");
        
        // 🌟 優先啟動彈窗抹除雷達 (保護遊戲畫面乾淨)
        [[UnityAdsHelper sharedInstance] startRadar];
        
        // 🌟 解決初次啟動黑屏：讓廣告引擎晚 3 秒再啟動，避開資源載入高峰
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 遊戲暖機完畢，開始初始化 UnityAds！");
            [UnityAds initialize:myGameId testMode:NO initializationDelegate:[UnityAdsHelper sharedInstance]];
        });
        
        // 🌟 10 秒倒數，時間到且廣告備妥就直接放！
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTenSecondTimerExpired = YES; 
            
            if (isAdReadyToShow) {
                [[UnityAdsHelper sharedInstance] tryTriggerBulldozeShow];
            } else {
                NSLog(@"[IPA918] ⏳ 10秒到了但正式廣告還沒抓到，等它下載好會自動補放。");
            }
        });
        
    }];
}
