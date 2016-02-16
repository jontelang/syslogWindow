TARGET=iphone:clang:8.4
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = syslogWindow
syslogWindow_FILES = Tweak.xm main.m syslogWindow.m
syslogWindow_FRAMEWORKS = CoreGraphics UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
