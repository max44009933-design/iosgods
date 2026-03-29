# 🌟 只編譯 arm64，確保相容性
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

# 專案名稱維持原樣，避免 GitHub Actions 腳本找不到檔案
TWEAK_NAME = UnityAdsTweak

# 🌟 回歸純淨環境，只編譯必備檔案
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 補齊 Start.io 官方強烈要求的 JavaScriptCore, QuartzCore, CoreAudio 等底層渲染庫！
UnityAdsTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia AdSupport StoreKit SystemConfiguration CoreTelephony WebKit CoreGraphics JavaScriptCore QuartzCore CoreAudio

# 🌟 告訴編譯器標頭檔在哪裡 (已拔除無用的 UnityAds 路徑)
UnityAdsTweak_CFLAGS = -fobjc-arc -F$(THEOS_PROJECT_DIR)

# 🌟 【關鍵更新】：徹底和 UnityAds 分手！只綁定 StartApp 和官方要求的解壓縮神器 -lz
UnityAdsTweak_LDFLAGS = -F$(THEOS_PROJECT_DIR) \
                        -framework StartApp \
                        -lz \
                        -rpath @executable_path/Frameworks \
                        -rpath @executable_path \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
