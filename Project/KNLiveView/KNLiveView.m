//
//  KNLiveView.m
//  KNLiveView
//
//  Created by Shawn on 2017/10/22.
//  Copyright © 2017年 Shawn. All rights reserved.
//

#import "KNLiveView.h"
#import "substrate.h"
#import <mach-o/dyld.h>
#import "KNLVOriginHeader.h"
#import "KNLVToolbox.h"

//@class TMAInsertShapePopoverContentViewController;
@interface TSWPStorage {
    NSString *_string;
}
@end
@interface TSWPShapeInfo {
    TSWPStorage *_containedStorage;
}
@end

static void* (*originBlockTo)(id,SEL,id,id,id);
static id (*originDrawableInfo)(id,SEL,int,id,id,id);
static id (*originPerformInsert)(id,SEL);
static NSUInteger (*originSetPresent)(id,SEL,id,id);
static id (*originShapeStyle)(id,SEL,int,id,id,id);
static id (*originOne)(id,SEL,id);

#pragma clang diagnostic ignored"-Wundeclared-selector"
static id newOne(id self,SEL _cmd,id arg1) {
    id r = originOne(self, _cmd, arg1);
    return r;
}
static void* newBlockTo(id self,SEL _cmd,id drawable,id button,id controller) {
    void *originReturn = originBlockTo(self, _cmd, drawable, button, controller);
    NSLog(@"KNLiveView: (%@)(%@)%@, %@, %@",originReturn, NSStringFromSelector(_cmd), drawable, button, controller);
    return nil;
}
static id newDrawableInfo(id self,SEL _cmd,int arg1, id arg2, id arg3, id arg4) {
    id originReturn = originDrawableInfo(self, _cmd, arg1, arg2, arg3, arg4);
//    NSLog(@"KNLiveView: (%@)(%@)%@",originReturn, NSStringFromSelector(_cmd), button);
    id map = [[originReturn valueForKey:@"shapeStyle"] valueForKey:@"mOverridePropertyMap"];
    id p = ((id(*)(id,SEL,int))objc_msgSend)(map, @selector(objectForProperty:), 517);
//    id p = [map tryToPerformSelector:@selector(objectForProperty:), (int)517];
    return originReturn;
}
static id newPerformInsert(id self, SEL _cmd) {
    id originReturn = originPerformInsert(self, _cmd);
//    NSLog(@"KNLiveView: (%@)(%@)%@",originReturn, NSStringFromSelector(_cmd), arg1);
    return originReturn;
}
static NSUInteger newSetPresent(id self, SEL _cmd, id arg1, id arg2) {
    [KNLiveView insertShape:self];
    NSUInteger originReturn = originSetPresent(self, _cmd, arg1, arg2);
    KNLVMethodLog(nil, _cmd, arg1, arg2);
    return originReturn;
}
static id newShapeStyle(id self, SEL _cmd, int arg1, id arg2, id arg3, id arg4) {
    id originReturn = originShapeStyle(self, _cmd, arg1, arg2, arg3, arg4);
    KNLVMethodLog(originReturn, _cmd, nil, arg2, arg3, arg4);
    return originReturn;
}

static void __attribute__((constructor)) initialize(void) { 
    for (int i = 0; i < _dyld_image_count(); i++) {
        char *image_name = (char *)_dyld_get_image_name(i);
        if ([[NSString stringWithUTF8String:image_name] containsString:@"Keynote"]) {
            intptr_t vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
            NSLog(@"KNLiveView: Image name %s, ASLR slide 0x%lx.\n",
                  image_name, vmaddr_slide);
            break;
        }
    }
    
    MSHookMessageEx(objc_getClass("TMAInsertShapePopoverContentViewController"), @selector(blockToRunCommandToPostProcessNewDrawable:button:targetInteractiveCanvasController:), (IMP)&newBlockTo, (IMP*)&originBlockTo);
    MSHookMessageEx(objc_getClass("TSADrawableFactory"), @selector(shapeInfoWithType:pathSource:preset:targetInteractiveCanvasController:), (IMP)&newDrawableInfo, (IMP*)&originDrawableInfo);
    MSHookMessageEx(objc_getClass("TSWPShapeInfo"), @selector(i_ownedTextStorage), (IMP)&newPerformInsert, (IMP*)&originPerformInsert);
//    MSHookMessageEx(objc_getClass(""), @selector(drawableFactory), (IMP)&new, (IMP*)&origin);
    MSHookMessageEx(objc_getClass("TMADocumentWindowToolbarController"), @selector(mediaBrowserViewController:didChooseMediaAtURLs:), (IMP)&newSetPresent, (IMP*)&originSetPresent);
    MSHookMessageEx(objc_getClass("TSADrawableFactory"), @selector(shapeInfoWithType:pathSource:preset:targetInteractiveCanvasController:), (IMP)&newShapeStyle, (IMP*)&originShapeStyle);
    MSHookMessageEx(objc_getClass("KNMacAnimatedPlaybackViewController"), @selector(initWithRenderingController:), (IMP)&newOne, (IMP*)&originOne);
}

@implementation KNLiveView
+ (void)insertShape:(id)toolbarController {
    id shapeVC = [toolbarController valueForKey:@"_insertShapePopoverViewController"];
    if ([[shapeVC valueForKey:@"_isReplacingDocument"] charValue] != 0) {
        return;
    }
    
    void(^actionBlock)(void) = ^{
        id<TMAInsertPopoverContentViewControllerDelegate> delegate = [shapeVC valueForKey:@"_delegate"];
        id canvasEditor = [delegate insertPopoverContentViewControllerCanvasEditor:shapeVC];
//        id canvasController = [canvasEditor interactiveCanvasController];
        id drawableFactory = [delegate insertPopoverContentViewControllerDrawableFactory:shapeVC];
        CGRect rect = CGRectMake(0, 0, 300, 500);
        id bezierPath = ((id(*)(id,SEL,CGRect))objc_msgSend)(objc_getClass("TSUBezierPath"), @selector(bezierPathWithRect:), rect);
        ((void(*)(id,SEL,double))objc_msgSend)(bezierPath, @selector(setLineWidth:), 10);
        id editablePathSource = ((id(*)(id,SEL,id))objc_msgSend)(objc_getClass("TSDEditableBezierPathSource"), @selector(editableBezierPathSourceWithBezierPath:), bezierPath);
        id shapeInfo = ((id(*)(id,SEL,id))objc_msgSend)(drawableFactory, @selector(shapeInfoWithEditablePathSource:), editablePathSource);
        id storage = [shapeInfo valueForKey:@"i_ownedTextStorage"];
        [storage setValue:@"aabbcv" forKey:@"string"];
        id colorFill = [objc_getClass("TSDColorFill") tryToPerformSelector:@selector(blackColor)];
        ((void(*)(id,SEL,id))objc_msgSend)(shapeInfo, @selector(setFill:), colorFill);
//        id block = ((id(*)(id,SEL,id,int,id))objc_msgSend)(drawableFactory, @selector(blockToRunCommandToPostProcessNewDrawable:shapeType:targetInteractiveCanvasController:), shapeInfo, 3, canvasController);
        id map = [[shapeInfo valueForKey:@"shapeStyle"] valueForKey:@"mOverridePropertyMap"];
        id stroke = [objc_getClass("TSDStroke") tryToPerformSelector:@selector(emptyStroke)];
        ((void(*)(id,SEL,id,int))objc_msgSend)(map, @selector(setObject:forProperty:), stroke, 517);
        id windowController = [objc_getClass("TSCHMacCDEWindowController") tryToPerformSelector:@selector(sharedController)];
        void* isShowing = [windowController tryToPerformSelector:@selector(isShowing)];
        if (isShowing != 0x0) {
            [windowController tryToPerformSelector:@selector(commitCurrentCellText)];
        }
        NSArray *drawableInfoArray = @[shapeInfo];
        id context = [objc_getClass("TSDInsertionContext") tryToPerformSelector:@selector(nonInteractiveInsertionContext)];
        id editor = [delegate editorForInsertingDrawables:drawableInfoArray insertionContext:context];
        if (editor == nil) {
            return;
        }
        ((void(*)(id,SEL,...))objc_msgSend)(canvasEditor, @selector(prepareGeometryForInsertingDrawables:withInsertionContext:), drawableInfoArray, context);
        ((void(*)(id,SEL,...))objc_msgSend)(canvasEditor, @selector(insertDrawables:withInsertionContext:postProcessBlock:), drawableInfoArray, context, nil);
    };
    
    id documentRootContext = [[shapeVC valueForKey:@"documentRoot"] valueForKey:@"context"];
    ((void(*)(id,SEL,...))objc_msgSend)(documentRootContext, @selector(canPerformUserActionUsingBlock:), actionBlock);
}
@end
