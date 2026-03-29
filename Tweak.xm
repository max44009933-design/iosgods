#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 
#import <AppTrackingTransparency/AppTrackingTransparency.h> // 🌟 必備：追蹤授權
#import <AdSupport/AdSupport.h>

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

// 🌟 為了方便你現在測試真實廣告，我先改成 10 秒冷卻！(上線前再改回 1800)
#define COOLDOWN_TIME 10 

static BOOL isTimerExpired = NO;
static BOOL isAdReadyToShow = NO; 
static BOOL isInterstitialReady = NO; 
static BOOL hasPlayedStartupAd = NO; 

@interface StartAppHelper : NSObject <STADelegateProtocol>
@property (nonatomic, strong) STAStartAppAd *startupAd; 
@property (nonatomic, strong) STAStartAppAd *returnAd;  
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

// --- 🌟 30秒新手保護期 (測試用) ---
- (BOOL)canShowReturnInterstitial {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    double firstLaunchTime = [defaults doubleForKey:@"IPA918_FirstLaunchTime"];
    if (firstLaunchTime == 0) {
        [defaults setDouble:currentTime forKey:@"IPA918_FirstLaunchTime"];
        [defaults synchronize];
        return NO; 
    }
    
    if (currentTime - firstLaunchTime < COOLDOWN_TIME) {
        return NO;
    }
    
    double lastShowTime = [defaults doubleForKey:@"IPA918_LastReturnAdTime"];
    if (currentTime - lastShowTime >= COOLDOWN_TIME) {
        return YES; 
    }
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
    NSLog(@"[IPA918] 🚀 開始初始化真實廣告模式...");
    STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
    sdk.appID = myStartAppId;
    
    // 🌟 強制關閉測試模式，迎接真實廣告！
    sdk.testAdsEnabled = NO; 
    
    self.startupAd = [[STAStartAppAd alloc] init];
    [self.startupAd loadAdWithDelegate:self];
    
    self.returnAd = [[STAStartAppAd alloc] init];
    [self.returnAd loadAdWithDelegate:self];
}

- (void)didLoadAd:(STAAbstractAd *)ad {
    NSLog(@"[IPA918] ✅ 真實廣告下載完成！");
    if (ad == self.startupAd) {
        isAdReadyToShow = YES;
        [self tryTriggerBulldozeShow]; 
    } else if (ad == self.returnAd) {
        isInterstitialReady = YES;
    }
}

- (void)failedLoadAd:(STAAbstractAd *)ad withError:(NSError *)error {
    // 🌟 如果還是失敗，看這裡的 Log：如果是 204 代表伺服器還是沒東西給你
    NSLog(@"[IPA918] 🔴 真實廣告載入失敗: %@", error.localizedDescription);
}

- (void)tryTriggerBulldozeShow {
    if (isTimerExpired && isAdReadyToShow && !hasPlayedStartupAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[IPA918] 🎬 播放開局插頁廣告！");
            hasPlayedStartupAd = YES; 
            [self.startupAd showAd];
        });
    }
}

- (void)tryShowReturnInterstitial {
    if ([self canShowReturnInterstitial]) {
        if (isInterstitialReady) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"[IPA918] 🎬 播放返回插頁廣告！");
                [self.returnAd showAd];
            });
        } else {
            [self.returnAd loadAdWithDelegate:self];
        }
    }
}

- (void)didCloseAd:(STAAbstractAd *)ad {
    if (ad == self.returnAd) {
        [self recordInterstitialShowTime];
        isInterstitialReady = NO;
        [self.returnAd loadAdWithDelegate:self];
    }
}

@end

// ==========================================
// 🚀 核心注入點
// ==========================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 🌟 1. 首先彈出「要求追蹤權限」視窗 (iOS 14+ 提高填充率關鍵)
        if (@available(iOS 14, *)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                    NSLog(@"[IPA918] 🛡️ 追蹤授權狀態: %lu", (unsigned long)status);
                    
                    // 🌟 2. 授權結束後 (不論點允許還是拒絕)，再開始初始化廣告
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[StartAppHelper sharedInstance] initializeStartApp];
                    });
                }];
            });
        } else {
            // iOS 14 以下直接初始化
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[StartAppHelper sharedInstance] initializeStartApp];
            });
        }

        // 🌟 3. 15 秒開局倒數觸發
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isTimerExpired = YES; 
            [[StartAppHelper sharedInstance] tryTriggerBulldozeShow];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[StartAppHelper sharedInstance] tryShowReturnInterstitial];
    }];
}
