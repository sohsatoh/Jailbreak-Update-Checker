TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = runupdatejb
ARCHS = arm64

runupdatejb_FILES = main.m
runupdatejb_CFLAGS = -fobjc-arc
runupdatejb_CODESIGN_FLAGS = -Sentitlements.plist
runupdatejb_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
