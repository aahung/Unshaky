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

- (CGEventRef)filterShakyPressEvent:(CGEventRef)event {
    
    // The incoming keycode.
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventType eventType = CGEventGetType(event);
    
    // ignore unconfigured keys
    if (keyDelays[keyCode] == 0) return event;
    
    if (lastPressedTimestamps[keyCode] == 0.0) {
        lastPressedTimestamps[keyCode] = [[NSDate date] timeIntervalSince1970];
        lastPressedEventTypes[keyCode] = eventType;
    } else {
        if (dismissNextEvent[keyCode]) {
            // dismiss the corresponding keyup event
            NSLog(@"DISMISSING KEYUP:%d", keyCode);
            if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", [[NSDate date] timeIntervalSince1970], keyCode, eventType]];
            dismissNextEvent[keyCode] = NO;
            return nil;
        }
        if (eventType == kCGEventKeyDown
            && lastPressedEventTypes[keyCode] == kCGEventKeyUp
            && 1000 * ([[NSDate date] timeIntervalSince1970] - lastPressedTimestamps[keyCode]) < keyDelays[keyCode]) {
            // dismiss the keydown event if it follows keyup event too soon
            NSLog(@"DISMISSING KEYDOWN:%d", keyCode);
            if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", [[NSDate date] timeIntervalSince1970], keyCode, eventType]];
            
            if (shakyPressDismissedHandler != nil) {
                shakyPressDismissedHandler();
            }
            dismissNextEvent[keyCode] = YES;
            return nil;
        }
        lastPressedTimestamps[keyCode] = [[NSDate date] timeIntervalSince1970];
        lastPressedEventTypes[keyCode] = eventType;
    }
    
    if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d)\n", [[NSDate date] timeIntervalSince1970], keyCode, eventType]];
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
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
        
        [[self.debugTextView textStorage] insertAttributedString:attr atIndex:0];
    });
}

@end
