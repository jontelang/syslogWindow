#import "Activator/libactivator.h"
@interface LogWindow: UIWindow <LAListener>
{
  NSMutableArray* savedMessages;
  UITextView *textView;
  NSString *messageToMatch;
}
-(void)addSyslogMessage:(NSString*)message;
@end