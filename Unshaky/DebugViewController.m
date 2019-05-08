//
//  DebugViewController.m
//  Unshaky
//
//  Created by Xinhong LIU on 3/14/19.
//  Copyright © 2019 Nested Error. All rights reserved.
//

#import "DebugViewController.h"
#import "ShakyPressPreventer.h"
#import "KeyboardLayouts.h"

@interface DebugViewController ()

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation DebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)appendToDebugTextView:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc]
                                    initWithString:text
                                    attributes:@{
                                                 NSForegroundColorAttributeName: [NSColor textColor],
                                                 NSFontAttributeName: [NSFont fontWithName:@"Courier New" size:10]
                                                 }];

        [[self.textView textStorage] appendAttributedString:attr];
        [self.textView scrollRangeToVisible: NSMakeRange(self.textView.string.length, 0)];
    });
}

- (void)appendEventToDebugTextview:(double)timestamp
                      keyboardType:(int64_t)keyboardType
                           keyCode:(CGKeyCode)keyCode
                         eventType:(CGEventType)eventType
       eventFlagsAboutModifierKeys:(CGEventFlags)eventFlagsAboutModifierKeys
                             delay:(int)delay {
    NSDictionary<NSNumber *, NSString *> *keyCodeToString = [[KeyboardLayouts shared] keyCodeToString];
    NSString *keyDescription = keyCodeToString[[[NSNumber alloc] initWithInt:keyCode]];
    if (keyDescription == nil) keyDescription = @"Unknown";
    NSString *eventString = [NSString stringWithFormat:@"%f Key(%3lld|%3d|%14s|%10llu|%3d) E(%u)",
                             timestamp, keyboardType, keyCode, [keyDescription UTF8String],
                             eventFlagsAboutModifierKeys, delay, eventType];
    [self appendToDebugTextView:[@"\n" stringByAppendingString:eventString]];
}

- (void)appendDismissed {
    [self appendToDebugTextView:@" DISMISSED"];
}

- (IBAction)copyClicked:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:self.textView.string forType:NSStringPboardType];
}

- (IBAction)clearClicked:(id)sender {
    self.textView.string = @"";
}

@end
