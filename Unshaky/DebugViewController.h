//
//  DebugViewController.h
//  Unshaky
//
//  Created by Xinhong LIU on 3/14/19.
//  Copyright © 2019 Nested Error. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DebugViewController : NSViewController

- (void)appendEventToDebugTextview:(double)timestamp
                      keyboardType:(int64_t)keyboardType
                           keyCode:(CGKeyCode)keyCode
                         eventType:(CGEventType)eventType
       eventFlagsAboutModifierKeys:(CGEventFlags)eventFlagsAboutModifierKeys
                             delay:(int)delay;

- (void)appendDismissed;

@end

NS_ASSUME_NONNULL_END
