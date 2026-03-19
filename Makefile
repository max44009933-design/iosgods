# 🌟 只編譯 arm64，確保與你手邊的 UnityAds 庫完全相容
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 已經拔除 fishhook.c，回歸最純淨的編譯環境！
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 基礎系統框架 (已移除不需要的 WebKit，達到極致輕量化)
UnityAdsTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia

# 🌟 編譯參數：指向你存放 UnityAds.framework 的位置
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks

# 🌟 【最重要】連結參數：
# 1. -framework UnityAds: 連結你的廣告庫
# 2. -rpath @executable_path/Frameworks: 讓 iOS 去標準資料夾找 framework
# 3. -rpath @executable_path: (保險絲) 如果 ESign 塞在根目錄 (/) 也能找到！
# 4. -rpath /usr/lib/swift: 確保 Swift 環境正常
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks \
                        -framework UnityAds \
                        -rpath @executable_path/Frameworks \
                        -rpath @executable_path \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
