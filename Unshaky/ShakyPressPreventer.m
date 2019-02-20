//
//  ShakyPressPreventer.m
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

#import "ShakyPressPreventer.h"

@implementation ShakyPressPreventer {
    NSTimeInterval lastPressedTimestamps[N_VIRTUAL_KEY];
    CGEventType lastPressedEventTypes[N_VIRTUAL_KEY];

    CGEventFlags lastEventFlagsAboutModifierKeysForSpace;
    BOOL cmdSpaceAllowance;
    BOOL workaroundForCmdSpace;

    BOOL dismissNextEvent[N_VIRTUAL_KEY];
    int keyDelays[N_VIRTUAL_KEY];
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
        [self loadWorkaroundForCmdSpace];
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            lastPressedTimestamps[i] = 0.0;
            lastPressedEventTypes[i] = 0;
            dismissNextEvent[i] = NO;
        }
    }
    return self;
}

// This initWithKeyDelays:ignoreExternalKeyboard: is used for testing purpose
- (instancetype)initWithKeyDelays:(int*)keyDelays_ ignoreExternalKeyboard:(BOOL)ignoreExternalKeyboard_ workaroundForCmdSpace:(BOOL)workaroundForCmdSpace_ {
    if (self = [super init]) {
        ignoreExternalKeyboard = ignoreExternalKeyboard_;
        workaroundForCmdSpace = workaroundForCmdSpace_;
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            keyDelays[i] = keyDelays_[i];
            lastPressedTimestamps[i] = 0.0;
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
        memset(keyDelays, 0, N_VIRTUAL_KEY * sizeof(int));
    } else {
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            keyDelays[i] = i >= [delays count] ? 0 : [(NSNumber *)[delays objectAtIndex:i] intValue];
        }
    }
}

- (void)loadIgnoreExternalKeyboard {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    ignoreExternalKeyboard = [defaults boolForKey:@"ignoreExternalKeyboard"]; // default No
}

- (void)loadWorkaroundForCmdSpace {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    workaroundForCmdSpace = [defaults boolForKey:@"workaroundForCmdSpace"]; // default No
}

- (CGEventRef)filterShakyPressEvent:(CGEventRef)event {
    // keyboard type, dismiss if it is not built-in keyboard
    if (ignoreExternalKeyboard) {
        int64_t type = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
        if (type != 58) return event;
    }

    // The incoming keycode.
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    // ignore unconfigured keys
    if (keyCode >= N_VIRTUAL_KEY || keyDelays[keyCode] == 0) return event;

    CGEventType eventType = CGEventGetType(event);
    CGEventFlags eventFlagsAboutModifierKeys = (kCGEventFlagMaskShift | kCGEventFlagMaskControl |
                                                kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand |
                                                kCGEventFlagMaskSecondaryFn) & CGEventGetFlags(event);
    double currentTimestamp = [[NSDate date] timeIntervalSince1970];

    if (lastPressedTimestamps[keyCode] != 0.0) {
        /** @ghost711: CMD+Space was pressed, which causes a duplicate pair of down/up
         keyEvents to occur 1-5 msecs after the "real" pair of events.
         - If the CMD key is released first, it will look like:
         CMD+Space Down
         Space Up
         CMD+Space Down
         CMD+Space Up
         - Whereas if the space bar is released first, it will be:
         CMD+Space Down
         CMD+Space Up
         CMD+Space Down
         CMD+Space Up
         - The issue only appears to happen with CMD+Space,
         not CMD+<any other key>, or <any other modifier key>+Space.*/
        // So here we allow one double-press to slip away

        // reset allowance to 1
        if (keyCode == 49 && eventFlagsAboutModifierKeys && 1000 * (currentTimestamp - lastPressedTimestamps[keyCode]) >= keyDelays[keyCode]) {
            cmdSpaceAllowance = YES;
        }

        if (dismissNextEvent[keyCode]) {
            // dismiss the corresponding keyup event
            NSLog(@"DISMISSING KEYUP:%d", keyCode);
            if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", currentTimestamp, keyCode, eventType]];
            dismissNextEvent[keyCode] = NO;
            return nil;
        }
        if (eventType == kCGEventKeyDown
            && lastPressedEventTypes[keyCode] == kCGEventKeyUp
            && 1000 * (currentTimestamp - lastPressedTimestamps[keyCode]) < keyDelays[keyCode]) {

            // let it slip away if allowance is 1 for CMD+SPACE
            if (keyCode == 49 && lastEventFlagsAboutModifierKeysForSpace &&
                eventFlagsAboutModifierKeys && workaroundForCmdSpace && cmdSpaceAllowance) {
                cmdSpaceAllowance = NO;
            } else {
                // dismiss the keydown event if it follows keyup event too soon
                NSLog(@"DISMISSING KEYDOWN:%d", keyCode);
                if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d) DISMISSED\n", currentTimestamp, keyCode, eventType]];

                if (shakyPressDismissedHandler != nil) {
                    shakyPressDismissedHandler();
                }
                dismissNextEvent[keyCode] = YES;
                return nil;
            }
        }
    } else if (keyCode == 49 && eventFlagsAboutModifierKeys) cmdSpaceAllowance = YES;

    lastPressedTimestamps[keyCode] = currentTimestamp;
    lastPressedEventTypes[keyCode] = eventType;
    if (keyCode == 49) lastEventFlagsAboutModifierKeysForSpace = eventFlagsAboutModifierKeys;
    
    if (_debugTextView != nil) [self appendToDebugTextView:[NSString stringWithFormat:@"%f\t Key(%d)\t Event(%d)\n", currentTimestamp, keyCode, eventType]];
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
