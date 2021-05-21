TARGET = iphone:clang:latest:7.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = fatego

TWEAK_NAME = unity60fps

unity60fps_FILES = Tweak.x
unity60fps_CFLAGS = -fobjc-arc
unity60fps_LIBRARIES = dobby

ADDITIONAL_CFLAGS += -Wno-error=unused-variable -Wno-error=unused-function -Wno-error=unused-value -include Prefix.pch

SUBPROJECTS += unity60fpspref

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	@rm -f $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/unity60fps.plist
	@ln -s /var/mobile/Library/Preferences/unity60fps.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/unity60fps.plist