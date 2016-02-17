#import "Activator/libactivator.h"
@interface LogWindow: UIWindow <LAListener>
{
  NSMutableArray* msgs;
  UITextView *l;
}
-(void)addSyslogMessage:(NSString*)message;
@end