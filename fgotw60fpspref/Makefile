# TARGET = iphone:clang:11.2:9.0
include $(THEOS)/makefiles/common.mk
ARCHS= arm64 arm64e
BUNDLE_NAME = fgotw60fpspref

fgotw60fpspref_FILES = FGO60FPSRootListController.m
fgotw60fpspref_INSTALL_PATH = /Library/PreferenceBundles
fgotw60fpspref_FRAMEWORKS = UIKit
fgotw60fpspref_PRIVATE_FRAMEWORKS = Preferences
fgotw60fpspref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/fgotw60fpspref.plist$(ECHO_END)
