ARCHS = arm64 arm64e
BUNDLE_NAME = unity60fpspref

unity60fpspref_FILES = Unity60FPSRootListController.m BDInfoListController.m BDAppListController.m LowiOSVersionCompatibility.x FPSLicenseViewController.m
unity60fpspref_INSTALL_PATH = /Library/PreferenceBundles
unity60fpspref_FRAMEWORKS = UIKit
unity60fpspref_PRIVATE_FRAMEWORKS = Preferences
unity60fpspref_CFLAGS = -fobjc-arc -include Prefix.pch
unity60fpspref_LIBRARIES = applist

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/unity60fpspref.plist$(ECHO_END)
