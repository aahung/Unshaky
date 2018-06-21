//
//  ShakyPressPreventer.h
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <ApplicationServices/ApplicationServices.h>

typedef void (^Handler)(void);

@interface ShakyPressPreventer : NSObject

- (BOOL)setupInputDeviceListener;
- (CGEventRef)filterShakyPressEvent:(CGEventRef)event;
- (void)shakyPressDismissed:(Handler)handler;

@end
