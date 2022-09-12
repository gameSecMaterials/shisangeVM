//
//  TableView.h
//  跨进程绘制
//
//  Created by 十三哥 on 2022/8/25.
//  Copyright © 2022 niu_o0. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kuandu  [UIScreen mainScreen].bounds.size.width
#define gaodu [UIScreen mainScreen].bounds.size.height
NS_ASSUME_NONNULL_BEGIN

@interface TableView : UIViewController<UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate>

@end

NS_ASSUME_NONNULL_END
