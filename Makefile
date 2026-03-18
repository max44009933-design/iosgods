ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
# 🌟 魔法：把 Dummy.swift 加進來一起編譯，強迫啟動 Swift 引擎！
UnityAdsTweak_FILES = Tweak.xm Dummy.swift

# 🌟 補裝備：除了原本的，再把缺少的 WebKit 跟 CoreAudioTypes 系統框架補上
UnityAdsTweak_FRAMEWORKS = UIKit Foundation WebKit CoreAudioTypes

UnityAdsTweak_CFLAGS = -fobjc-arc -F./layout/Library/Frameworks
# 🌟 終極連線：同時載入 UnityAds 還有剛上傳的 UnitySwiftProtobuf
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds -framework UnitySwiftProtobuf -rpath /usr/lib/swift

include $(THEOS_MAKE_PATH)/tweak.mk
