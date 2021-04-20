TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = runjbupdate
ARCHS = arm64

runjbupdate_FILES = main.m
runjbupdate_CFLAGS = -fobjc-arc
runjbupdate_CODESIGN_FLAGS = -Sentitlements.plist
runjbupdate_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
