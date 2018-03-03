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

- (void)cs_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(ObservingBlock)block;

- (void)cs_removeObserver:(NSObject *)observer
                   forKey:(NSString *)key;

@end
