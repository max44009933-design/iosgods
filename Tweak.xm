#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> // 🌟 記得替換成 StartApp 的標頭檔

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
// 🌟 已經幫你填上你截圖裡的 App ID 囉！
NSString *const myStartAppId = @"202921894";  

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO;
static BOOL isInterstitialReady = NO; 
static BOOL hasPlayedStartupAd = NO; // 防止開局廣告重複播放的安全鎖

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
// 🌟 Start.io 廣告助手
// ==========================================
@interface StartAppHelper : NSObject <STADelegateProtocol>
@property (nonatomic, strong) STAStartAppAd *startupAd; // 開局獎勵廣告
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

// --- Start.io 廣告邏輯 ---
- (void)initializeStartApp {
    NSLog(@"[IPA918] 🚀 開始初始化 Start.io SDK...");
    STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
    sdk.appID = myStartAppId;
    
    // 🌟 修正點：官方已廢棄此屬性並強制預設為 NO，因此將其註解避免嚴格編譯模式報錯
    // sdk.returnAdEnabled = NO; 
    
    self.startupAd = [[STAStartAppAd alloc] init];
    self.returnAd = [[STAStartAppAd alloc] init];
    
    // 🌟 預載廣告：開局載入獎勵影片，返回載入一般插頁
    [self.startupAd loadRewardedVideoAdWithDelegate:self];
    [self.returnAd loadAdWithDelegate:self];
}

// 廣告載入成功 Callback
- (void)didLoadAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] ✅ 廣告下載完成！");
    if (ad == self.startupAd) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; // 嘗試觸發 10 秒開局廣告
    } else if (ad == self.returnAd) {
        isInterstitialReady = YES; // 記錄插頁廣告已就緒
    }
}

// 廣告載入失敗 Callback
- (void)failedLoadAd:(STAAbstractAd *)ad withError:(NSError *)error {
    NSLog(@"[IPA918] 🔴 廣告載入失敗: %@", error.localizedDescription);
    if (ad == self.startupAd) {
        isAdReadyToShow = NO;
    } else if (ad == self.returnAd) {
        isInterstitialReady = NO;
    }
}

// 開局 10 秒廣告邏輯
- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow && !hasPlayedStartupAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] 🎬 條件達成，開始播放 Start.io 開局廣告！");
            hasPlayedStartupAd = YES; // 鎖上，避免重複播放
            [self.startupAd showAd];
        });
    }
}

// 返回插頁廣告邏輯
- (void)tryShowReturnInterstitial {
    // 1. 檢查 60 分鐘冷卻期
    if ([self canShowReturnInterstitial]) {
        // 2. 檢查插頁廣告載好了沒
        if (isInterstitialReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[IPA918] 🎬 觸發 Start.io 背景返回插頁廣告！");
                [self.returnAd showAd];
            });
        } else {
            NSLog(@"[IPA918] ⏳ 返回廣告尚未 Ready，嘗試重新載入...");
            [self.returnAd loadAdWithDelegate:self];
        }
    }
}

// 廣告關閉 Callback (玩家看完或點擊 X 關閉)
- (void)didCloseAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] 💰 廣告已關閉！");
    
    // 如果關閉的是返回廣告，紀錄時間並重新載入下一檔
    if (ad == self.returnAd) {
        NSLog(@"[IPA918] ⏱️ 記錄播放時間，啟動 60 分鐘冷卻機制");
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        // 把下一檔廣告提早載下來備用
        [self.returnAd loadAdWithDelegate:self];
    }
}

- (void)failedShowAd:(STAAbstractAd *)ad withError:(NSError *)error {
    NSLog(@"[IPA918] 🔴 廣告播放失敗: %@", error.localizedDescription);
}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    // 1. 監聽 App 剛啟動
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"[IPA918] 📢 啟動廣播到達！");
        
        // 🌟 防卡死機制：讓 App 先專心開機 7 秒鐘！
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 7秒遊戲暖機完畢，開始初始化並下載 Start.io 廣告！");
            [[StartAppHelper sharedInstance] initializeStartApp];
        });
        
        // 🌟 10 秒倒數播放 (從 App 打開那一刻算起)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            if (isAdReadyToShow) {
                [[StartAppHelper sharedInstance] tryTriggerBulldozeShow];
            } else {
                NSLog(@"[IPA918] ⏳ 10秒到了但廣告還沒下載完，等它準備好會自動補放。");
            }
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
