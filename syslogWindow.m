#import <objc/runtime.h>
#include <dlfcn.h>
#include "syslogWindow.h"

@implementation LogWindow

-(id)init{
  self = [super initWithFrame:[UIScreen mainScreen].bounds];
  if(self){
    // Setup the window
    self.backgroundColor = [UIColor clearColor];
    self.windowLevel = UIWindowLevelStatusBar + 10000;
    self.hidden = NO;

    // Setup the label stuff
    textView = [[UITextView alloc] initWithFrame:CGRectMake(0,0,320,150)];
    textView.textAlignment = NSTextAlignmentLeft;
    textView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95f];
    textView.textColor = [UIColor whiteColor];
    textView.contentSize = textView.bounds.size;
    textView.clipsToBounds = YES;
    textView.contentInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0;
    textView.textContainerInset = UIEdgeInsetsMake(2.0f, 2.0f, 2.0f, 2.0f);

    [self addSubview:textView];

    [self initActivatorListener];

    // And others
    savedMessages = [[NSMutableArray alloc] init];
  }
  return self;
}

#define LINE_REGEX "(\\w+\\s+\\d+\\s+\\d+:\\d+:\\d+)\\s+(\\S+|)\\s+(\\w+)\\[(\\d+)\\]\\s+\\<(\\w+)\\>:\\s(.*)"
-(void)addSyslogMessage:(NSString*)message{
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@LINE_REGEX options:NSRegularExpressionCaseInsensitive error:&error];
  NSArray *matches = [regex matchesInString:message options:0 range:NSMakeRange(0, [message length])];

  for (NSTextCheckingResult *match in matches) {
    if ([match numberOfRanges] < 6) {
      // if entry doesn't match regex, print uncolored
      [savedMessages addObject:message];
      continue;
    }

    // Find ranges
    NSRange dateRange    =  [match rangeAtIndex:1];
    NSRange deviceRange  =  [match rangeAtIndex:2];
    NSRange processRange =  [match rangeAtIndex:3];
    NSRange pidRange     =  [match rangeAtIndex:4];
    NSRange typeRange    =  [match rangeAtIndex:5];
    NSRange logRange     =  [match rangeAtIndex:6];

    // Extract string content
    NSString *date       =  [message substringWithRange:dateRange];
    NSString *device     =  [message substringWithRange:deviceRange];
    NSString *process    =  [message substringWithRange:processRange];
    NSString *pid        =  [message substringWithRange:pidRange];
    NSString *type       =  [message substringWithRange:typeRange];
    NSString *log        =  [message substringWithRange:NSMakeRange(logRange.location, [message length] - logRange.location)];
    log = [log stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    // Colorize
    NSAttributedString *dateAttr = [self string:date color:[UIColor grayColor]];
    NSAttributedString *deviceAttr = [self string:device color:[UIColor blueColor]];
    NSAttributedString *processAttr = [self string:process color:[UIColor redColor]];
    NSAttributedString *pidAttr = [self string:pid color:[UIColor yellowColor]];
    NSAttributedString *typeAttr = [self string:type color:[UIColor greenColor]];
    NSAttributedString *logAttr = [self string:log color:[UIColor whiteColor]];

    // // Build final string
    NSMutableAttributedString *build = [NSMutableAttributedString new];
    [build appendAttributedString:dateAttr];
    [build appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [build appendAttributedString:deviceAttr];
    [build appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [build appendAttributedString:processAttr];
    [build appendAttributedString:[self string:@"[" color:[UIColor grayColor]]];
    [build appendAttributedString:pidAttr];
    [build appendAttributedString:[self string:@"]" color:[UIColor grayColor]]];
    [build appendAttributedString:[self string:@" <" color:[UIColor grayColor]]];
    [build appendAttributedString:typeAttr];
    [build appendAttributedString:[self string:@">:" color:[UIColor grayColor]]];
    [build appendAttributedString:logAttr];

    // Save to full message log
    [savedMessages addObject:build];
  }

  // Only save the 10 latest messages
  if( [savedMessages count] > 10 ){
    [savedMessages removeObjectAtIndex:0];
  }

  // // Scroll to bottom
  NSMutableAttributedString *fullLog = [[NSMutableAttributedString alloc] initWithString:@""];
  for(NSMutableAttributedString *previousLog in savedMessages){
    [fullLog appendAttributedString:previousLog];
    [fullLog appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
  }
  [textView setAttributedText:fullLog];

  // Scroll to bottom 
  [textView setScrollEnabled:NO];  // ios7 bug
  [textView setScrollEnabled:YES]; // ios7 bug
  [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
}

-(NSAttributedString*)string:(NSString*)str color:(UIColor*)color{
  NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:str];
  [attrText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:8.0f] range:NSMakeRange(0, [str length])];
  [attrText addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [str length])];
  return attrText;
}

//Prevents touches from being blocked by the window
- (BOOL)_ignoresHitTest {
  return YES;
}

-(void)initActivatorListener{ // if it is installed
    dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
    Class laactivatorClass = objc_getClass("LAActivator");
    if( laactivatorClass == nil ){
        NSLog(@"Class 'LAActivator' not found. Activator is not installed.");
    }else{
        [[laactivatorClass sharedInstance] registerListener:self forName:@"com.jontelang.syslogwindow.alpha"];
        [[laactivatorClass sharedInstance] registerListener:self forName:@"com.jontelang.syslogwindow.hidden"];
    }
}


- (void)activator:(LAActivator *)activator 
     receiveEvent:(LAEvent *)event 
  forListenerName:(NSString *)listenerName{
    if( [listenerName isEqualToString:@"com.jontelang.syslogwindow.alpha"] ){
      self.alpha = self.alpha == 1.0f ? 0.25f : 1.0f;
    }else if( [listenerName isEqualToString:@"com.jontelang.syslogwindow.hidden"] ){
      self.hidden = !self.hidden;
    }else{
        NSLog(@"hello");
    }
}

// - (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event{
//     if( snapperWindow != nil ){
//         if( [snapperWindow isCropping] || [snapperWindow isPresentingSnapperHistory] ){
//             [snapperWindow hideCropOverlay];
//             [snapperWindow hideSnapperHistory];
//             event.handled = YES;
//         }
//     }
// }

@end