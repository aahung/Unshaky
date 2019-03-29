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
    BOOL aggressiveMode;

    BOOL dismissNextEvent[N_VIRTUAL_KEY];
    int keyDelays[N_VIRTUAL_KEY];
    BOOL ignoreExternalKeyboard;
    Handler shakyPressDismissedHandler;
}

static NSDictionary<NSNumber *, NSString *> *_keyCodeToString;

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
        [self loadAggressiveMode];
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            lastPressedTimestamps[i] = 0.0;
            lastPressedEventTypes[i] = 0;
            dismissNextEvent[i] = NO;
        }
    }
    return self;
}

// This initWithKeyDelays:ignoreExternalKeyboard: is used for testing purpose
- (instancetype)initWithKeyDelays:(int*)keyDelays_ ignoreExternalKeyboard:(BOOL)ignoreExternalKeyboard_ workaroundForCmdSpace:(BOOL)workaroundForCmdSpace_ aggressiveMode:(BOOL)aggressiveMode_ {
    if (self = [super init]) {
        ignoreExternalKeyboard = ignoreExternalKeyboard_;
        workaroundForCmdSpace = workaroundForCmdSpace_;
        aggressiveMode = aggressiveMode_;
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

- (void)loadAggressiveMode {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    aggressiveMode = [defaults boolForKey:@"aggressiveMode"]; // default No
}

- (CGEventRef)filterShakyPressEvent:(CGEventRef)event {
    // keyboard type, dismiss if it is not built-in keyboard
    if (ignoreExternalKeyboard) {
        int64_t keyboardType = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
        if (keyboardType != 58) return event;
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

    if (_debugViewController != nil) {
        int64_t keyboardType = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
        [_debugViewController appendEventToDebugTextview:currentTimestamp
                                            keyboardType:keyboardType
                                                 keyCode:keyCode
                                               eventType:eventType
                             eventFlagsAboutModifierKeys:eventFlagsAboutModifierKeys
                                                   delay:keyDelays[keyCode]];
    }

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
            if (_debugViewController != nil) {
                [_debugViewController appendDismissed];
            }

            dismissNextEvent[keyCode] = NO;
            if (aggressiveMode) lastPressedTimestamps[keyCode] = currentTimestamp;
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
                if (_debugViewController != nil) {
                    [_debugViewController appendDismissed];
                }

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
    CFRelease(runLoopSource);

    return YES;
}

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    ShakyPressPreventer *kc = (__bridge ShakyPressPreventer*)refcon;
    return [kc filterShakyPressEvent: event];
}

- (void)shakyPressDismissed:(Handler)handler {
    shakyPressDismissedHandler = handler;
}

+ (NSDictionary<NSNumber *, NSString *> *)keyCodeToString {
    if (_keyCodeToString == nil) {
        // this list credits to the answer at https://stackoverflow.com/a/36901239/2361752
        _keyCodeToString = @{
                             @29: @" 0",
                             @18: @" 1",
                             @19: @" 2",
                             @20: @" 3",
                             @21: @" 4",
                             @23: @" 5",
                             @22: @" 6",
                             @26: @" 7",
                             @28: @" 8",
                             @25: @" 9",
                             @0: @" A",
                             @11: @" B",
                             @8: @" C",
                             @2: @" D",
                             @14: @" E",
                             @3: @" F",
                             @5: @" G",
                             @4: @" H",
                             @34: @" I",
                             @38: @" J",
                             @40: @" K",
                             @37: @" L",
                             @46: @" M",
                             @45: @" N",
                             @31: @" O",
                             @35: @" P",
                             @12: @" Q",
                             @15: @" R",
                             @1: @" S",
                             @17: @" T",
                             @32: @" U",
                             @9: @" V",
                             @13: @" W",
                             @7: @" X",
                             @16: @" Y",
                             @6: @" Z",
                             @10: @"SectionSign",
                             @50: @"Grave",
                             @27: @"Minus",
                             @24: @"Equal",
                             @33: @"LeftBracket",
                             @30: @"RightBracket",
                             @41: @"Semicolon",
                             @39: @"Quote",
                             @43: @"Comma",
                             @47: @"Period",
                             @44: @"Slash",
                             @42: @"Backslash",
                             @82: @"Keypad0 0",
                             @83: @"Keypad1 1",
                             @84: @"Keypad2 2",
                             @85: @"Keypad3 3",
                             @86: @"Keypad4 4",
                             @87: @"Keypad5 5",
                             @88: @"Keypad6 6",
                             @89: @"Keypad7 7",
                             @91: @"Keypad8 8",
                             @92: @"Keypad9 9",
                             @65: @"KeypadDecimal",
                             @67: @"KeypadMultiply",
                             @69: @"KeypadPlus",
                             @75: @"KeypadDivide",
                             @78: @"KeypadMinus",
                             @81: @"KeypadEquals",
                             @71: @"KeypadClear",
                             @76: @"KeypadEnter",
                             @49: @"Space",
                             @36: @"Return",
                             @48: @"Tab",
                             @51: @"Delete",
                             @117: @"ForwardDelete",
                             @52: @"Linefeed",
                             @53: @"Escape",
                             @57: @"CapsLock",
                             @122: @"F1",
                             @120: @"F2",
                             @99: @"F3",
                             @118: @"F4",
                             @96: @"F5",
                             @97: @"F6",
                             @98: @"F7",
                             @100: @"F8",
                             @101: @"F9",
                             @109: @"F10",
                             @103: @"F11",
                             @111: @"F12",
                             @105: @"F13",
                             @107: @"F14",
                             @113: @"F15",
                             @106: @"F16",
                             @64: @"F17",
                             @79: @"F18",
                             @80: @"F19",
                             @90: @"F20",
                             @72: @"VolumeUp",
                             @73: @"VolumeDown",
                             @74: @"Mute",
                             @114: @"Help/Insert",
                             @115: @"Home",
                             @119: @"End",
                             @116: @"PageUp",
                             @121: @"PageDown",
                             @123: @"Arrow Left",
                             @124: @"Arrow Right",
                             @125: @"Arrow Down",
                             @126: @"Arrow Up",
                             @145: @"Brightness Down",
                             @144: @"Brightness Up",
                             @130: @"Dashboard",
                             @131: @"LaunchPad"
                             };
    }
    return _keyCodeToString;
}
@end
