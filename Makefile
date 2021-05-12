TARGET = iphone:clang:11.2:7.0
ARCHS = arm64


TWEAK_NAME = unity60fps

unity60fps_FILES = Tweak.x
unity60fps_CFLAGS = -fobjc-arc -Wno-error=unused-variable -Wno-error=unused-function -include Prefix.pch
unity60fps_LIBRARIES = hookzz.static

SUBPROJECTS += unity60fpspref


include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
