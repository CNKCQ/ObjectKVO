//
//  OKKVOViewController.m
//  ObjectKVO_Example
//
//  Created by Steve on 03/03/2018.
//  Copyright © 2018 wangchengqvan@gmail.com. All rights reserved.
//

#import "OKKVOViewController.h"
#import <ObjectKVO/NSObject+KVO.h>

@interface Person: NSObject

@property (nonatomic, assign) CGFloat age;

@property (nonatomic, strong) Person *son;

@property (nonatomic, assign) BOOL yesOrNot;

@end

@implementation Person


@end


@interface OKKVOViewController ()

@property (nonatomic, strong) Person *person;


@end

@implementation OKKVOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"kvo";
    Person *son1 = [Person new];
    son1.age = 10;
    _person = [[Person alloc] init];
    _person.son = son1;
    _person.age = 100;
//    [_person addObserver:self forKeyPath:@"son" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    _person.yesOrNot = YES;
    [_person ok_addObserver:self forKey:@"son" withBlock:^(id observedObject, NSString *observedKey, NSDictionary<NSKeyValueChangeKey,id> *change) {
        NSLog(@"oldValue == %f --- newValue == %f", ((Person *)change[NSKeyValueChangeOldKey]).age, ((Person *)change[NSKeyValueChangeNewKey]).age);
    }];
    [_person ok_addObserver:self forKey:@"yesOrNot" withBlock:^(id observedObject, NSString *observedKey, NSDictionary<NSKeyValueChangeKey,id> *change) {
        NSLog(@"oldValue == %@ --- newValue == %@", change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
    }];

    _person.yesOrNot = NO;
    _person.age = 23;
    Person *son2 = [Person new];
    son2.age = 20;
    _person.son = son2;
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"orign -- oldValue == %@ --- newValue == %@", change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
//}

 - (void)dealloc {
     [_person ok_removeObserver:self forKey:@"son"];
     [_person ok_removeObserver:self forKey:@"yesOrNot"];
 }

@end
