@interface LogWindow: UIWindow
{
  NSMutableArray* msgs;
  UITextView *l;
}
-(void)addSyslogMessage:(NSString*)message;
@end