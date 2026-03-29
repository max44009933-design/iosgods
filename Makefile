# 🌟 只編譯 arm64，確保與你手邊的 UnityAds 庫完全相容
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 保留原有的：已經拔除 fishhook.c，回歸最純淨的編譯環境，並支援 Swift！
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 保留原有庫，並補齊必備的系統底層框架！(新增 WebKit 確保 StartApp 網頁彈窗正常運作)
UnityAdsTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia AdSupport StoreKit SystemConfiguration CoreTelephony WebKit CoreGraphics

# 🌟 保留原有的 UnityAds 路徑，並【新增】StartApp 所在的根目錄路徑 $(THEOS_PROJECT_DIR)
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks -F$(THEOS_PROJECT_DIR)

# 🌟 保留原有的 UnityAds 綁定，並【新增】StartApp 框架與路徑！
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -F$(THEOS_PROJECT_DIR) \
                        -framework UnityAds \
                        -framework StartApp \
                        -rpath @executable_path/Frameworks \
                        -rpath @executable_path \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
