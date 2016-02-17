#import "Activator/libactivator.h"
@interface LogWindow: UIWindow <LAListener>
{
  NSMutableArray* savedMessages;
  UITextView *textView;
}
-(void)addSyslogMessage:(NSString*)message;
@end