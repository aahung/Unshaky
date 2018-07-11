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

typedef void (^Handler)(void);

@interface ShakyPressPreventer : NSObject

@property (weak) NSTextView *debugTextView;

+ (ShakyPressPreventer *)sharedInstance;
- (BOOL)setupInputDeviceListener;
- (CGEventRef)filterShakyPressEvent:(CGEventRef)event;
- (void)shakyPressDismissed:(Handler)handler;
- (void)loadKeyDelays;

@end
