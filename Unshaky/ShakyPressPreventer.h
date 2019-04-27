//
//  ShakyPressPreventer.h
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>
#include <ApplicationServices/ApplicationServices.h>
#import "DebugViewController.h"

#define N_VIRTUAL_KEY 146

typedef void (^Handler)(int);

@interface ShakyPressPreventer : NSObject

@property (class) NSDictionary<NSNumber *, NSString *> *keyCodeToString;
@property DebugViewController *debugViewController;

+ (ShakyPressPreventer *)sharedInstance;
- (BOOL)setupEventTap;
- (void)removeEventTap;
- (BOOL)eventTapEnabled;
- (CGEventRef)filterShakyPressEvent:(CGEventRef)event;
- (void)shakyPressDismissed:(Handler)handler;
- (void)loadKeyDelays;
- (void)loadIgnoreExternalKeyboard;
- (void)loadWorkaroundForCmdSpace;
- (void)loadAggressiveMode;
// This initWithKeyDelays:ignoreExternalKeyboard ...: is used for testing purpose
- (instancetype)initWithKeyDelays:(int*)keyDelays_ ignoreExternalKeyboard:(BOOL)ignoreExternalKeyboard_ workaroundForCmdSpace:(BOOL)workaroundForCmdSpace_ aggressiveMode:(BOOL)aggressiveMode_;

@end
