# 🌟 只編譯 arm64，確保相容性
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 保留原有的：已經拔除 fishhook.c，回歸純淨環境
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 【新舊融合】：保留你原本的庫，並補齊 Start.io 官方強烈要求的 JavaScriptCore, QuartzCore, CoreAudio 等底層渲染庫！
UnityAdsTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia AdSupport StoreKit SystemConfiguration CoreTelephony WebKit CoreGraphics JavaScriptCore QuartzCore CoreAudio

# 🌟 告訴編譯器標頭檔在哪裡
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks -F$(THEOS_PROJECT_DIR)

# 🌟 【關鍵更新】：連結 UnityAds、StartApp，並且加上官方要求的解壓縮神器 -lz
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -F$(THEOS_PROJECT_DIR) \
                        -framework UnityAds \
                        -framework StartApp \
                        -lz \
                        -rpath @executable_path/Frameworks \
                        -rpath @executable_path \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
