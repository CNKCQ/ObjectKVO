//
//  KOViewController.m
//  ObjectKVO_Example
//
//  Created by wangchengqvan@gmail.com on 01/02/2018.
//  Copyright (c) 2018 wangchengqvan@gmail.com. All rights reserved.
//

#import "OKViewController.h"
#import <ObjectKVO/NSObject+KVO.h>
#import "OKKVOViewController.h"

@interface OKViewController ()

@end

@implementation OKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"kvo";
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"入栈" style:UIBarButtonItemStylePlain target:self action:@selector(test:)];
}

- (void)test: (id)value {
    OKKVOViewController *vc = [OKKVOViewController new];
    vc.view.backgroundColor = [UIColor blueColor];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
