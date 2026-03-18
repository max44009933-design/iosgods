# 🌟 只編譯 arm64，確保與你手邊的 UnityAds 庫完全相容
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 包含 Tweak 邏輯與啟動 Swift 引擎的魔法檔案
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 基礎系統框架，確保廣告播放與網頁顯示正常
UnityAdsTweak_FRAMEWORKS = UIKit Foundation WebKit AVFoundation CoreMedia

# 🌟 編譯參數：指向你存放 UnityAds.framework 的位置
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks

# 🌟 【最重要】連結參數：
# 1. -framework UnityAds: 連結你的廣告庫
# 2. -rpath @executable_path/Frameworks: 告訴 dylib 去 IPA 內部的 Frameworks 資料夾找人 (解決閃退關鍵！)
# 3. -rpath /usr/lib/swift: 確保 Swift 環境正常
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks \
                        -framework UnityAds \
                        -rpath @executable_path/Frameworks \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
