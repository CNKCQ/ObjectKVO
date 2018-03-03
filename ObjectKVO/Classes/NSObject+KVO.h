//
//  NSObject+KVO.h
//  Categorys
//
//  Created by Steve on 11/12/2017.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSKeyValueObserving.h>

typedef void(^ObservingBlock)(id observedObject, NSString *observedKey, NSDictionary<NSKeyValueChangeKey,id> *change);

@interface NSObject (KVO)

- (void)ok_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(ObservingBlock)block;

- (void)ok_removeObserver:(NSObject *)observer
                   forKey:(NSString *)key;

@end
