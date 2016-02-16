
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();
extern "C" int startTheSyslogThingy();

#include "syslogWindow.h"
static LogWindow *logWindow = nil;

void syslogMethodCallback(CFNotificationCenterRef center, 
                          void *observer, 
                          CFStringRef name, 
                          const void *object, 
                          CFDictionaryRef userInfo) {
  if( logWindow ){
    NSString *message = [((NSDictionary*)userInfo) objectForKey:@"message"];
    [logWindow addSyslogMessage:message];
  }
}

%hook SBUIController
-(void)finishLaunching{
   %orig();
   logWindow = [[LogWindow alloc] init];
}
%end

%ctor{
    CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                    NULL,
                                    (CFNotificationCallback)syslogMethodCallback,
                                    CFSTR("com.syslogWindow.syslogMethodCallback"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);

    dispatch_queue_t backgroundQueue = dispatch_queue_create("bgSyslogQueue", 0);
    dispatch_async(backgroundQueue, ^{
        startTheSyslogThingy();
    });

}