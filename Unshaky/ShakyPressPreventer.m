//
//  ShakyPressPreventer.m
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

#import "ShakyPressPreventer.h"


@implementation ShakyPressPreventer {
    NSTimeInterval lastPressedTimestamps[128];
    CGEventType lastPressedEventTypes[128];
    BOOL dismissNextEvent[128];
    int keyDelays[128];
    BOOL ignoreExternalKeyboard;
    Handler shakyPressDismissedHandler;
}

+ (ShakyPressPreventer *)sharedInstance {
    static ShakyPressPreventer *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ShakyPressPreventer alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self loadKeyDelays];
        [self loadIgnoreExternalKeyboard];
        for (int i = 0; i < 128; ++i) {
            lastPressedEventTypes[i] = 0.0;
            lastPressedEventTypes[i] = 0;
            dismissNextEvent[i] = NO;
        }
    }
    return self;
}

- (void)loadKeyDelays {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSArray *delays = [defaults arrayForKey:@"delays"];
    if (delays == nil) {
        memset(keyDelays, 0, 128 * sizeof(int));
    } else {
        for (int i = 0; i < 128; ++i) keyDelays[i] = [(NSNumber *)[delays objectAtIndex:i] intValue];
    }
}

- (void)loadIgnoreExternalKeyboard {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    ignoreExternalKeyboard = [defaults boolForKey:@"ignoreExternalKeyboard"]; // default No
}

- (CGEventRef)filterShakyPressEvent:(CGEventRef)event {

    // The incoming keycode.
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    // ignore unconfigured keys
    if (keyDelays[keyCode] == 0) return event;
    
    // keyboard type, dismiss if it is not built-in keyboard
    if (ignoreExternalKeyboard) {
        int64_t type = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
        if (type != 58) return event;
    }

    double      stamp     = [[NSDate date] timeIntervalSince1970];
    double      lastStamp = lastPressedTimestamps[keyCode];
    CGEventType eventType = CGEventGetType(event);
    
    if (lastStamp != 0.0) {
        if (dismissNextEvent[keyCode]) {
            // dismiss the corresponding keyup event
            NSLog(@"DISMISSING KEYUP:%d", keyCode);
            if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", stamp, keyCode, eventType]];
            dismissNextEvent[keyCode] = NO;
            return nil;
        }
        if (eventType == kCGEventKeyDown && lastPressedEventTypes[keyCode] == kCGEventKeyUp ) {
            // dismiss the keydown event if it follows keyup event too soon
            
            CGEventFlags eventFlags = CGEventGetFlags( event );
            if( eventFlags & kCGEventFlagMaskCommand ) {
                /** The command key was pressed, which will cause the event to be reported
                 twice in rapid succession (first without the flag, and then again with it).
                 So just ignore. */
                NSLog(@"%f\t Key(%d)\t Event(%d) NOT DISMISSING DOWN (CMD Pressed)\n",
                                                            stamp, keyCode, eventType);
                
            } else if( (int)(1000.0 * (stamp - lastStamp)) < keyDelays[keyCode] ) {
                NSLog(@"DISMISSING KEYDOWN:%d", keyCode);
                if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", stamp, keyCode, eventType]];
                
                if (shakyPressDismissedHandler != nil) {
                    shakyPressDismissedHandler();
                }
                dismissNextEvent[keyCode] = YES;
                return nil;
            }
        }
    }
    lastPressedTimestamps[keyCode] = stamp;
    lastPressedEventTypes[keyCode] = eventType;
    
    if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d)\n", stamp, keyCode, eventType]];
    return event;
}

- (BOOL)setupInputDeviceListener {
    
    CGEventMask eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp) | (1 << kCGEventFlagsChanged));
    CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0,
                                eventMask, myCGEventCallback, (__bridge void *)(self));
    if (!eventTap) {
        NSLog(@"Permission issue");
        return NO;
    }
    
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    
    return YES;
}

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    ShakyPressPreventer *kc = (__bridge ShakyPressPreventer*)refcon;
    return [kc filterShakyPressEvent: event];
}

- (void)shakyPressDismissed:(Handler)handler {
    shakyPressDismissedHandler = handler;
}

- (void)appendToDebugTextView:(NSString*)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: [NSColor textColor]}];
        
        [[self.debugTextView textStorage] insertAttributedString:attr atIndex:0];
    });
}

@end
