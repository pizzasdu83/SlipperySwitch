export PACKAGE_VERSION := 1.3

ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := DayNightSwitch

DayNightSwitch_FILES += Tweak.xm
DayNightSwitch_FILES += DayNightSwitch.m
DayNightSwitch_FILES += JoyConSwitch.m
DayNightSwitch_FILES += SimpleSwitch.m
DayNightSwitch_FRAMEWORKS += AudioToolbox
DayNightSwitch_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
ICON_PATH := /var/jb/Library/PreferenceBundles/DayNightSwitch.bundle/icon@3x.png
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
ICON_PATH := /var/jb/Library/PreferenceBundles/DayNightSwitch.bundle/icon@3x.png
else
ICON_PATH := /Library/PreferenceBundles/DayNightSwitch.bundle/icon@3x.png
endif

before-package::
	$(ECHO_NOTHING)echo "Icon: file://$(ICON_PATH)" >> "$(THEOS_STAGING_DIR)/DEBIAN/control"$(ECHO_END)
	
after-install::
	install.exec "killall -9 SpringBoard backboardd"

SUBPROJECTS += daynightswitch

include $(THEOS_MAKE_PATH)/aggregate.mk
