TARGET = iphone:clang:11.2:9.0
ARCHS=arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = fgotw60fps

fgotw60fps_FILES = Tweak.x readmem/readmem.m
fgotw60fps_CFLAGS = -fobjc-arc -Wno-unused-function

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += fgotw60fpspref
include $(THEOS_MAKE_PATH)/aggregate.mk
