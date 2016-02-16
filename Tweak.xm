
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();
#include "syslogWindow.h"
static LogWindow *logWindow = nil;
extern "C" int startTheSyslogThingy();

void shareSnap(CFNotificationCenterRef center, 
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
                                    (CFNotificationCallback)shareSnap,
                                    CFSTR("com.jontelang.snapper2.sharesnap2GRR"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);

    dispatch_queue_t backgroundQueue = dispatch_queue_create("bgsyslogqueueu", 0);
    dispatch_async(backgroundQueue, ^{
        startTheSyslogThingy();
    });

}