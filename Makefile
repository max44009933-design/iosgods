# 🌟 只編譯 arm64，確保與你手邊的 UnityAds 庫完全相容
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 保留原有的：已經拔除 fishhook.c，回歸最純淨的編譯環境，並支援 Swift！
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 【新增功能】：保留原有庫，並補齊 UnityAds 必備的系統底層框架！(少了 AdSupport, StoreKit 等等絕對會編譯失敗)
UnityAdsTweak_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia AdSupport StoreKit SystemConfiguration CoreTelephony

# 🌟 保留原有的：編譯參數，指向你存放 UnityAds.framework 的位置
UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks

# 🌟 保留原有的：連結參數，Theos 會在這裡把 UnityAds 靜態綁定進 dylib！
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks \
                        -framework UnityAds \
                        -rpath @executable_path/Frameworks \
                        -rpath @executable_path \
                        -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
