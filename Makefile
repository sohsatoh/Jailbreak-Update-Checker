TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = JailbreakUpdateChecker
ARCHS = arm64 arm64e

JailbreakUpdateChecker_FILES = JBUCommandOutputViewController.m JBUManager.m Tweak.x
JailbreakUpdateChecker_CFLAGS = -fobjc-arc -include Prefix.pch
JailbreakUpdateChecker_PRIVATE_FRAMEWORKS = AppSupport
include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += runjbupdate
include $(THEOS_MAKE_PATH)/aggregate.mk
