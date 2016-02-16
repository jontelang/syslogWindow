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
    l = [[UITextView alloc] initWithFrame:CGRectMake(0,22,320,100)];
    l.textAlignment = NSTextAlignmentLeft;
    l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    l.textColor = [UIColor whiteColor];
    l.contentSize = l.bounds.size;
    l.clipsToBounds = YES;
    l.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    l.textContainer.lineFragmentPadding = 0;
    l.textContainerInset = UIEdgeInsetsZero;

    [self addSubview:l];

    // And others
    msgs = [[NSMutableArray alloc] init];
  }
  return self;
}

-(void)addSyslogMessage:(NSString*)message{
    // Only save the 10 latest messages
    [msgs addObject:message];
    if([msgs count]>10){
      [msgs removeObjectAtIndex:0];
    }

    // Scroll to bottom
    NSString *ss=@"";
    int i = 0;
    for(NSString *s in msgs){
      ss = [NSString stringWithFormat:@"%@%i: %@\n",ss,i,s];
      i++;
    }
    [l setText:ss];

    [l setScrollEnabled:NO];
    [l setScrollEnabled:YES];
    [l scrollRangeToVisible:NSMakeRange([l.text length], 0)];
    //[l scrollRectToVisible:CGRectMake(0,0,0,FLT_MAX) animated:NO];
    //[l setContentOffset:CGPointMake(0,l.contentSize.height-l.bounds.size.height) animated:NO];
    // [textView scrollRectToVisible:CGRectMake(5,5,5,999999999999999999) animated:NO];//for some reason the textViewDidChange auto scrolling doesnt work with a carriage return at the end of your textView... so I manually set it INSANELY low (NOT ANIMATED) here so that it automagically bounces back to the proper position before interface refreshes when textViewDidChange is called after this.
}

//Prevents touches from being blocked by the window
- (BOOL)_ignoresHitTest {
  return YES;
}

@end