ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:11.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak
UnityAdsTweak_FILES = Tweak.xm
UnityAdsTweak_CFLAGS = -fobjc-arc

# 宣告要連結 UnityAds 框架 (超級重要)
UnityAdsTweak_FRAMEWORKS = UIKit Foundation
UnityAdsTweak_LDFLAGS = -F./layout/Library/Frameworks -framework UnityAds

include $(THEOS_MAKE_PATH)/tweak.mk