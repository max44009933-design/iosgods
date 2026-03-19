ARCHS = arm64
TARGET = iphone:clang:latest:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnityAdsTweak

# 🌟 確保 fishhook.c 有加入編譯
UnityAdsTweak_FILES = Tweak.xm fishhook.c

# 🌟 只依賴最基礎的 UIKit 和 Foundation，絕對不加 UnityAds！
UnityAdsTweak_FRAMEWORKS = UIKit Foundation

# 啟用 ARC，關閉煩人的警告
UnityAdsTweak_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS)/makefiles/tweak.mk
