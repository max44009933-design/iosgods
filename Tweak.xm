#import <UIKit/UIKit.h>
#import <UnityAds/UnityAds.h>

// 🔴 在這裡填入你的 Unity Ads 後台數據！
NSString *const myGameId = @"6069216";    // 替換成你的 Game ID
NSString *const myAdUnitId = @"test0318"; // 替換成你的 Ad Unit ID (Placement ID)

%hook UIApplication
// App 啟動時，第一時間喚醒 Unity Ads SDK
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    %orig; // 先保留原本 App 啟動的功能
    
    // 初始化 Unity SDK (開發測試階段 testMode 先設為 YES，確保不會被鎖帳號！上線請改成 NO)
    [UnityAds initialize:myGameId testMode:YES];
    NSLog(@"[IPA918] 🚀 Unity Ads SDK 已啟動！Game ID: %@", myGameId);
    
    return YES;
}
%end

%hook UIViewController
// 攔截 App 的畫面載入
- (void)viewDidAppear:(BOOL)animated {
    %orig; // 先保留原本畫面載入的功能
    
    // 使用 dispatch_once 確保這個五秒計時器只會觸發一次，避免每次切換畫面都瘋狂跳廣告
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[IPA918] ⏱️ 畫面載入完畢，開始倒數 5 秒...");
        
        // 設定 5 秒的延遲計時器
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 檢查廣告影片是不是已經下載好、準備就緒了？
            if ([UnityAds isReady:myAdUnitId]) {
                NSLog(@"[IPA918] 🎬 廣告準備好了，強制彈出！ID: %@", myAdUnitId);
                [UnityAds show:self placementId:myAdUnitId];
            } else {
                NSLog(@"[IPA918] ⚠️ 尷尬了，等了 5 秒廣告還沒 Load 完...");
            }
            
        });
    });
}
%end