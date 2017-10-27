//
//  KNLVToolbox.h
//  KNLiveView
//
//  Created by sunda on 2017/10/25.
//  Copyright © 2017年 Shawn. All rights reserved.
//

#import <Foundation/Foundation.h>

void KNLVLog(NSString* formate, ...);
void KNLVMethodLog(id returnValue, SEL selector, ...);

@interface NSObject (KNLVToolbox)
+ (void *)tryToPerformSelector:(SEL)selector, ...;
- (void *)tryToPerformSelector:(SEL)selector, ...;
@end
