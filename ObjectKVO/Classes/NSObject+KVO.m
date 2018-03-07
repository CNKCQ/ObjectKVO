//
//  NSObject+KVO.m
//  Categorys
//
//  Created by Steve on 11/12/2017.
//

#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>


//Not support Basic data type

NSString *const kKVOClassPrefix = @"KVOClassPrefix_";
NSString *const kKVOAssociatedObservers = @"KVOAssociatedObservers";

#pragma mark - ObservationInfo
@interface ObservationInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) ObservingBlock block;

@end

@implementation ObservationInfo

- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(ObservingBlock)block
{
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end

#pragma mark - Helpers

static NSString * getter4Setter(NSString *setter) {
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    return key;
}


static NSString * setter4Getter(NSString *getter) {
    if (getter.length <= 0) {
        return nil;
    }
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    return setter;
}

static Class kvo_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - Overridden Methods



static void kvo_setter(id self, SEL _cmd, void *newValue) {
    // can't get the double value
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getter4Setter(setterName);
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    SEL getterMethod = NSSelectorFromString(getterName);
    id oldValue = [self valueForKey:getterName];
    NSMethodSignature *sig = [self methodSignatureForSelector:getterMethod];
    const char *returnType = sig.methodReturnType;
    id result;
    // 一开始是用 va_list 的方式获取参数，结果发现 arm64 下不可用 See: http://blog.cnbang.net/tech/2808/
    if(!strcmp(returnType, @encode(void))){
        result =  nil;
    } else if (!strcmp(returnType, @encode(id))){
        result = (__bridge id)(newValue);
    } else {
        // TODO: NOT ALL TEST YET
        if (!strcmp(returnType, @encode(char))) {
            result = [NSNumber numberWithChar:*(char *)&newValue];
        } else if (!strcmp(returnType, @encode(int))) {
            result = [NSNumber numberWithInt:*(int *)&newValue];
        } else if (!strcmp(returnType, @encode(short))) {
            result = [NSNumber numberWithShort:*(short *)&newValue];
        } else if (!strcmp(returnType, @encode(long))) {
            result = [NSNumber numberWithLong:*(long *)&newValue];
        } else if (!strcmp(returnType, @encode(long long))) {
            result = [NSNumber numberWithLongLong:*(long long *)&newValue];
        } else if (!strcmp(returnType, @encode(unsigned char))) {
            result = [NSNumber numberWithUnsignedChar:*(unsigned char *)&newValue];
        } else if (!strcmp(returnType, @encode(unsigned int))) {
            result = [NSNumber numberWithUnsignedInt:*(unsigned int *)&newValue];
        } else if (!strcmp(returnType, @encode(unsigned short))) {
            result = [NSNumber numberWithUnsignedShort:*(unsigned short *)&newValue];
        } else if (!strcmp(returnType, @encode(unsigned long))) {
            result = [NSNumber numberWithUnsignedLong:*(unsigned long *)&newValue];
        } else if (!strcmp(returnType, @encode(unsigned long long))) {
            result = [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)&newValue];
        } else if (!strcmp(returnType, @encode(float))) {
            result = [NSNumber numberWithFloat:*(float *)&newValue];
        } else if (!strcmp(returnType, @encode(double))) {
            result = [NSNumber numberWithDouble:*(double *)&newValue];
        } else if (!strcmp(returnType, @encode(BOOL))) {
            result = [NSNumber numberWithBool:*(BOOL *)&newValue];
        } else if (!strcmp(returnType, @encode(NSInteger))) {
            result = [NSNumber numberWithInteger:*(NSInteger *)&newValue];
        } else if (!strcmp(returnType, @encode(NSUInteger))) {
            result = [NSNumber numberWithUnsignedInteger:*(NSUInteger *)&newValue];
        } else if (!strcmp(returnType, @encode(CGPoint))) {
            result = [NSValue valueWithCGPoint:*(CGPoint *)&newValue];
        } else if (!strcmp(returnType, @encode(CGVector))) {
            result = [NSValue valueWithCGVector:*(CGVector *)&newValue];
        } else if (!strcmp(returnType, @encode(CGSize))) {
            result = [NSValue valueWithCGSize:*(CGSize *)&newValue];
        } else if (!strcmp(returnType, @encode(CGRect))) {
            result = [NSValue valueWithCGRect:*(CGRect *)&newValue];
        } else if (!strcmp(returnType, @encode(CGAffineTransform))) {
            result = [NSValue valueWithCGAffineTransform:*(CGAffineTransform *)&newValue];
        } else if (!strcmp(returnType, @encode(UIEdgeInsets))) {
            result = [NSValue valueWithUIEdgeInsets:*(UIEdgeInsets *)&newValue];
        } else if (!strcmp(returnType, @encode(UIOffset))) {
            result = [NSValue valueWithUIOffset:*(UIOffset *)&newValue];
        } else {
            result = nil;
        }
    }
    struct objc_super superclass = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    // cast our pointer so the compiler won't complain
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    // call super's setter, which is original class's setter method
    objc_msgSendSuperCasted(&superclass, _cmd, result);
    // look up observers and call the blocks
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));
    for (ObservationInfo *each in observers) {
        if (nil == each.observer) {
            [observers removeObject:each];
            return;
        }
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDictionary<NSKeyValueChangeKey, id> *change = @{
                                                                 NSKeyValueChangeOldKey: oldValue
                                                                 ,             NSKeyValueChangeNewKey: result
                                                                 };
                each.block(self, getterName, change);
            });
        }
    }
}

@implementation NSObject (KVO)

- (void)ok_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(ObservingBlock)block {
    SEL setterSelector = NSSelectorFromString(setter4Getter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    Class class = object_getClass(self);
    NSString *className = NSStringFromClass(class);
    // if not an KVO class yet
    if (![className hasPrefix: kKVOClassPrefix]) {
        class = [self makeKvoClassWithOriginalClassName:className];
        object_setClass(self, class);
    }
    // add our kvo setter if this class (not superclasses) doesn't implement the setter?
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(class, setterSelector, (IMP)kvo_setter, types);
    }
    ObservationInfo *info = [[ObservationInfo alloc] initWithObserver:observer Key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}


/**
 Remove observer

 @param observer the observer
 @param key the key
 */
- (void)ok_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));
    ObservationInfo *infoToRemove;
    for (ObservationInfo* info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            infoToRemove = info;
            break;
        }
    }
    [observers removeObject:infoToRemove];
}

- (Class)makeKvoClassWithOriginalClassName:(NSString *)originalClassName
{
    NSString *kvoClassName = [kKVOClassPrefix stringByAppendingString:originalClassName];
    Class class = NSClassFromString(kvoClassName);
    if (class) {
        return class;
    }
    // class doesn't exist yet, make it
    Class originalClass = object_getClass(self);
    Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
    // grab class method's signature so we can borrow it
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    const char *types = method_getTypeEncoding(classMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_class, types);
    objc_registerClassPair(kvoClass);
    return kvoClass;
}

- (BOOL)hasSelector:(SEL)selector
{
    Class class = object_getClass(self);
    unsigned int methodCount = 0;
    Method* methodList = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

@end
