TARGET = iphone:clang:latest:7.0
ARCHS = arm64

INSTALL_TARGET_PROCESSES = fatego

TWEAK_NAME = Unity60FPS Unity60FPSLoader

Unity60FPS_FILES = Tweak.x
Unity60FPS_CFLAGS = -fobjc-arc
Unity60FPS_LIBRARIES = dobby

Unity60FPSLoader_FILES = TweakLoader.x
Unity60FPSLoader_CFLAGS = -fobjc-arc

ADDITIONAL_CFLAGS += -Wno-error=unused-variable -Wno-error=unused-function -Wno-error=unused-value -include Prefix.pch

SUBPROJECTS += unity60fpspref

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
