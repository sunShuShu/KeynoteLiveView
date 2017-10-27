//
//  KNLVToolbox.m
//  KNLiveView
//
//  Created by sunda on 2017/10/25.
//  Copyright © 2017年 Shawn. All rights reserved.
//

#import "KNLVToolbox.h"
#import <objc/message.h>

void KNLVLog(NSString* formate, ...) {
#ifdef DEBUG
    va_list args;
    va_start(args, formate);
    NSString *content = [NSString stringWithFormat:formate, args];
    va_end(args);
    content = [NSString stringWithFormat:@"🚀KNLiveView: %@", content];
    NSLog(content, nil);
#endif
}

void KNLVMethodLog(id returnValue, SEL selector, ...) {
    va_list args;
    va_start(args, selector);
    NSString *returnString = nil;
    if (object_isClass(returnValue)) {
        returnString = [returnValue description];
    }
    NSString *info = [NSString stringWithFormat:@"%@ (%@)", returnString, NSStringFromSelector(selector)];
    NSArray *subStringArray = [NSStringFromSelector(selector) componentsSeparatedByString:@":"];
    for (NSInteger i = 0; i < subStringArray.count - 1; i++) {
        info = [info stringByAppendingFormat:@"%@, ", va_arg(args, id)];
    }
    va_end(args);
    KNLVLog(info);
}

@implementation NSObject (KNLVToolbox)
+ (void *)tryToPerformSelector:(SEL)selector, ... {
    va_list args;
    va_start(args, selector);
    void *returnValue = [self tryObj:self toPerformSelector:selector, args];
    va_end(args);
    return returnValue;
}

- (void *)tryToPerformSelector:(SEL)selector, ... {
    va_list args;
    va_start(args, selector);
    void *returnValue = [NSObject tryObj:self toPerformSelector:selector, args];
    va_end(args);
    return returnValue;
}

+ (void *)tryObj:(id)obj toPerformSelector:(SEL)selector, ... {
    void* returnValue = nil;
    va_list args;
    va_start(args, selector);
    if ([obj respondsToSelector:selector]) {
        returnValue = ((void*(*)(id,SEL,...))objc_msgSend)(obj, selector, args);
    } else {
        NSString *info = [NSString stringWithFormat:@"%@ can not responds to selector: %@", NSStringFromClass(self.class), NSStringFromSelector(selector)];
        NSAssert(NO, info);
    }
    va_end(args);
    return returnValue;
}
@end
