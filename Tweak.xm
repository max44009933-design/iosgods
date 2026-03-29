#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO; // 追蹤開局獎勵廣告是否準備好
static BOOL isInterstitialReady = NO; // 追蹤返回插頁廣告
static BOOL hasPlayedStartupAd = NO; 

// ==========================================
// 🌟 Start.io 廣告助手
// ==========================================
@interface StartAppHelper : NSObject <STADelegateProtocol>
@property (nonatomic, strong) STAStartAppAd *startupAd; // 開局【獎勵影片】
@property (nonatomic, strong) STAStartAppAd *returnAd;  // 返回【一般插頁】
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

// --- 🌟 全新：30分鐘新手保護期 + 30分鐘冷卻時間邏輯 ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // 1. 檢查是否是第一次打開 APP？如果是，記錄當下時間
    double firstLaunchTime = [defaults doubleForKey:@"IPA918_FirstLaunchTime"];
    if (firstLaunchTime == 0) {
        NSLog(@"[IPA918] 🆕 第一次打開 APP！啟動 30 分鐘「免廣告新手保護期」！");
        [defaults setDouble:currentTime forKey:@"IPA918_FirstLaunchTime"];
        [defaults synchronize];
        return NO; // 剛打開，絕對不能播
    }
    
    // 2. 檢查是否已經度過「首次打開後的 30 分鐘 (1800秒)」保護期？
    if (currentTime - firstLaunchTime < 1800) {
        int remaining = (1800 - (currentTime - firstLaunchTime)) / 60;
        NSLog(@"[IPA918] 🛡️ 新手保護期中，切換 APP 也不播廣告... 剩餘約 %d 分鐘", remaining);
        return NO;
    }
    
    // 3. 檢查一般冷卻時間：距離上次播「返回廣告」有沒有超過 30 分鐘？
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    if (currentTime - lastShowTime >= 1800) {
        return YES; // 超過 30 分鐘了，可以播！
    }
    
    int remainingMins = (1800 - (currentTime - lastShowTime)) / 60;
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
    
    // 測試模式 (要上線賺真錢時記得把這行砍掉或設為 NO)
    sdk.testAdsEnabled = YES; 
    
    // 1. 預載開局廣告：專屬「獎勵影片」
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadRewardedVideoAdWithDelegate:self];
    
    // 2. 預載返回廣告：一般插頁廣告
    self.returnAd = [[STAStartAppAd alloc] init];
    [self.returnAd loadAdWithDelegate:self];
}

// 廣告載入成功
- (void)didLoadAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] ✅ 廣告下載完成！");
    if (ad == self.startupAd) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; 
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

// 🌟 開局 10 秒觸發：播放獎勵影片
- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow && !hasPlayedStartupAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] 🎬 條件達成，開始播放 Start.io 開局獎勵影片！");
            hasPlayedStartupAd = YES; 
            [self.startupAd showAd];
        });
    }
}

// 🌟 返回觸發：檢查 30 分鐘保護與冷卻後播放插頁
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

// ==========================================
// 🎁 獎勵影片專屬 Callback
// ==========================================
- (void)didCompleteVideo:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] 🏆 太神啦！玩家把獎勵影片看完了！");
    // 👉 可以在這裡發送獎勵
}

// 廣告關閉後重新計時
- (void)didCloseAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] 🚪 廣告已關閉！");
    if (ad == self.returnAd) {
        NSLog(@"[IPA918] ⏱️ 啟動 30 分鐘冷卻機制");
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
// 🚀 核心注入點
// ==========================================
%ctor {
    NSLog(@"[IPA918] 💉 Dylib 成功注入！等待啟動...");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 7 秒遊戲暖機
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] ⏳ 7秒暖機完畢，初始化 Start.io！");
            [[StartAppHelper sharedInstance] initializeStartApp];
        });
        
        // 10 秒開局倒數觸發
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            [[StartAppHelper sharedInstance] tryTriggerBulldozeShow];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[IPA918] 🔄 玩家從背景返回遊戲！");
        [[StartAppHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
