TARGET = iphone:clang:11.2:9.0
INSTALL_TARGET_PROCESSES = fatego
ARCHS=arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = fgotw60fps

fgotw60fps_FILES = Tweak.x readmem/readmem.m
fgotw60fps_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += fgotw60fpspref
include $(THEOS_MAKE_PATH)/aggregate.mk
