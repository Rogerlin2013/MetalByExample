//
//  MetalView.h
//  MetalByExample
//
//  Created by linyongzhi on 2019/2/19.
//  Copyright © 2019 BabyTiger. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalView : UIView

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@end

NS_ASSUME_NONNULL_END
