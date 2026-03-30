#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StartApp/StartApp.h> 

// ==========================================
// 🔴 配置區 (Start.io 專用)
// ==========================================
NSString *const myStartAppId = @"202921894";  

// ==========================================
// 🚀 核心注入點 (完全採用官方原生機制)
// ==========================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // 延遲 5 秒等遊戲畫面稍微跑一下，再啟動 SDK
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSLog(@"[IPA918] 🚀 啟動 Start.io 官方 Splash 模式...");
            STAStartAppSDK *sdk = [STAStartAppSDK sharedInstance];
            sdk.appID = myStartAppId;
            
            // 🌟 關閉測試模式，迎接真實廣告
            sdk.testAdsEnabled = NO; 
            
            // 🌟 確保官方的「內建返回廣告」是開啟的！
            sdk.returnAdEnabled = YES; 
            
            // 🌟 殺手鐧：使用官方的「開局閃屏廣告」，填充率最高！
            [sdk showSplashAd];
            
        });
    }];
}
