//
//  ShakyPressPreventer.m
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

#import "ShakyPressPreventer.h"
#import "KeyboardLayouts.h"

#define AUTO_EXPANSION_IGNORE_THRESHOLD 5
#define KEYCODE_SPACE 49

@implementation ShakyPressPreventer {
    NSTimeInterval lastPressedTimestamps[N_VIRTUAL_KEY];
    CGEventType lastPressedEventTypes[N_VIRTUAL_KEY];

    CGEventFlags lastEventFlagsAboutModifierKeysForSpace;
    BOOL cmdSpaceAllowance;
    BOOL workaroundForCmdSpace;
    BOOL aggressiveMode;
    BOOL statisticsDisabled;

    BOOL dismissNextEvent[N_VIRTUAL_KEY];
    int keyDelays[N_VIRTUAL_KEY];
    BOOL ignoreExternalKeyboard;
    BOOL ignoreInternalKeyboard;
    Handler statisticsHandler;

    CFMachPortRef eventTap;

    BOOL disabled;
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
        eventTap = NULL;
        [self loadKeyDelays];
        [self loadIgnoreExternalKeyboard];
        [self loadIgnoreInternalKeyboard];
        [self loadWorkaroundForCmdSpace];
        [self loadAggressiveMode];
        [self loadStatisticsDisabled];
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            lastPressedTimestamps[i] = 0.0;
            lastPressedEventTypes[i] = 0;
            dismissNextEvent[i] = NO;
        }
        disabled = NO;
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

    // load enableds first
    int keyEnableds[N_VIRTUAL_KEY];
    NSArray *enableds = [defaults arrayForKey:@"enableds"];
    if (enableds == nil) {
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            keyEnableds[i] = true;
        }
    } else {
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            keyEnableds[i] = i >= [enableds count] ? true : [(NSNumber *)[enableds objectAtIndex:i] boolValue];
        }
    }

    // set delays
    if (delays == nil) {
        memset(keyDelays, 0, N_VIRTUAL_KEY * sizeof(int));
    } else {
        for (int i = 0; i < N_VIRTUAL_KEY; ++i) {
            keyDelays[i] = (i >= [delays count] || keyEnableds[i] == false) ?
                0 : [(NSNumber *)[delays objectAtIndex:i] intValue];
        }
    }
}

- (void)loadIgnoreExternalKeyboard {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    ignoreExternalKeyboard = [defaults boolForKey:@"ignoreExternalKeyboard"]; // default No
}

- (void)loadIgnoreInternalKeyboard {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    ignoreInternalKeyboard = [defaults boolForKey:@"ignoreInternalKeyboard"]; // default No
}

- (void)loadWorkaroundForCmdSpace {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    workaroundForCmdSpace = [defaults boolForKey:@"workaroundForCmdSpace"]; // default No
}

- (void)loadAggressiveMode {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    aggressiveMode = [defaults boolForKey:@"aggressiveMode"]; // default No
}

- (void)loadStatisticsDisabled {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    statisticsDisabled = [defaults boolForKey:@"statisticsDisabled"]; // default No
}

- (void)setDisabled:(BOOL)_disabled {
    disabled = _disabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enabled-toggled" object:nil];
}

- (BOOL)isDisabled {
    return disabled;
}

- (CGEventRef)filterShakyPressEvent:(CGEventRef)event {
    if (disabled) {
        return event;
    }

    // keyboard type, used if user specify ignore-external or ignore-internal
    if (ignoreExternalKeyboard || ignoreInternalKeyboard) {
        int64_t keyboardType = CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
        // 58: seems to be the value for pre-2018 models
        // 59: MacBook Pro (15-inch, 2018) https://github.com/aahung/Unshaky/issues/40
        if (ignoreExternalKeyboard && keyboardType != 58 && keyboardType != 59) return event;
        if (ignoreInternalKeyboard && (keyboardType == 58 || keyboardType == 59)) return event;
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
        if (keyCode == KEYCODE_SPACE && eventFlagsAboutModifierKeys && 1000 * (currentTimestamp - lastPressedTimestamps[keyCode]) >= keyDelays[keyCode]) {
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
        
        float msElapsed;
        if (eventType == kCGEventKeyDown
            && lastPressedEventTypes[keyCode] == kCGEventKeyUp
            && (msElapsed = 1000 * (currentTimestamp - lastPressedTimestamps[keyCode])) > AUTO_EXPANSION_IGNORE_THRESHOLD
            && msElapsed < keyDelays[keyCode]) {

            // let it slip away if allowance is 1 for CMD+SPACE
            if (keyCode == KEYCODE_SPACE && lastEventFlagsAboutModifierKeysForSpace &&
                eventFlagsAboutModifierKeys && workaroundForCmdSpace && cmdSpaceAllowance) {
                cmdSpaceAllowance = NO;
            } else {
                // dismiss the keydown event if it follows keyup event too soon
                if (_debugViewController != nil) {
                    [_debugViewController appendDismissed];
                }

                if (statisticsHandler != nil && !statisticsDisabled) {
                    statisticsHandler(keyCode);
                }
                dismissNextEvent[keyCode] = YES;
                return nil;
            }
        }
    } else if (keyCode == KEYCODE_SPACE && eventFlagsAboutModifierKeys) cmdSpaceAllowance = YES;

    lastPressedTimestamps[keyCode] = currentTimestamp;
    lastPressedEventTypes[keyCode] = eventType;
    if (keyCode == KEYCODE_SPACE) lastEventFlagsAboutModifierKeysForSpace = eventFlagsAboutModifierKeys;
    
    return event;
}

- (BOOL)setupEventTap {
    
    CGEventMask eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp) | (1 << kCGEventFlagsChanged));
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0,
                                eventMask, eventTapCallback, (__bridge void *)(self));
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

- (void)removeEventTap {
    if (eventTap == NULL) return;
    @try {
        CFMachPortInvalidate(eventTap);
        CFRelease(eventTap);
        eventTap = NULL;
    }
    @catch(NSException *exception) {
        NSLog(@"Fail to remove event tap.");
    }
}

- (BOOL)eventTapEnabled {
    if (eventTap == NULL) return false;
    if (CGEventTapIsEnabled(eventTap) == false) return false;
    return true;
}

CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    ShakyPressPreventer *kc = (__bridge ShakyPressPreventer*)refcon;
    return [kc filterShakyPressEvent: event];
}

- (void)setStatisticsHandler:(Handler)handler {
    statisticsHandler = handler;
}

+ (void)setKeyCodeToString:(NSDictionary<NSNumber *,NSString *> *)keyCodeToString {
    _keyCodeToString = keyCodeToString;
}
@end
