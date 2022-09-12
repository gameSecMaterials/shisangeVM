//
//  TableView.m
//  跨进程绘制
//
//  Created by 十三哥 on 2022/8/25.
//  Copyright © 2022 niu_o0. All rights reserved.
//
#import "NSTask.h"
#import "PidModel.h"
#include <stdio.h>
#include <string>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <UIKit/UIKit.h>
#import <dlfcn.h>
#import "TableView.h"
#import "ViewController.h"

@interface TableView ()
@end
static UITableView *表格列表;
static NSArray *系统进程;
static NSArray *用户进程;
@implementation TableView


- (void)viewDidLoad {
    [super viewDidLoad];
    //1.获取一个全局串行队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //2.把任务添加到队列中执行
    dispatch_async(queue, ^{
        系统进程 = [[PidModel alloc] refreshModelArray:1];
        用户进程 = [[PidModel alloc] refreshModelArray:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self 表格];
        });
    });
    
    
}

-(void)表格
{
    NSLog(@"系统进程 =%@",系统进程 );
    NSLog(@"用户进程 =%@",用户进程 );
    //默认打开的列表是0全部列表 1是收藏列表
    //表格视图
    表格列表 = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kuandu, gaodu)];
    表格列表.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    表格列表.dataSource = self;
    表格列表.delegate = self;
    表格列表.userInteractionEnabled=YES;
    表格列表.bounces = NO;//yes，就是滚动超过边界会反弹有反弹回来的效果; NO，那么滚动到达边界会立刻停止。
    表格列表.showsVerticalScrollIndicator = NO;//不显示右侧滑块
    表格列表.layer.cornerRadius=8.0f;
    表格列表.separatorStyle = UITableViewCellSeparatorStyleSingleLine;//分割线
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"< 返回" style:UIBarButtonItemStylePlain target:self action:@selector(goBackAction:)];
    //设置导航栏左边按钮文字的颜色(以及背景图片的颜色)
    leftItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    [表格列表 reloadData];
    //添加视图
    [self.view addSubview:表格列表];
    
}
- (void)goBackAction:(UIButton*)sender{
    NSString*PID=[[NSUserDefaults standardUserDefaults] objectForKey:@"PID"];
    NSString*Name=[[NSUserDefaults standardUserDefaults] objectForKey:@"Name"];
    [[ViewController alloc] PID:PID Name:Name];
    [self dismissViewControllerAnimated:YES completion:nil];
}
//分组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
//每一行显示内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // 1 初始化Cell
    // 1.1 设置Cell的重用标识
    static NSString *ID = @"cell";
    // 1.2 去缓存池中取Cell
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
        
    }
    NSString*str;
    if (indexPath.section==0) {
        str=系统进程[indexPath.row];
        
        
    }
    if (indexPath.section==1) {
        str=用户进程[indexPath.row];
        
        
    }
    NSArray *arr = [str componentsSeparatedByString:@",,"];
    NSString*pid=arr[0];
    NSString*name=arr[1];
    str = [NSString stringWithFormat:@"%@  %@",pid,name];
    if (str.length<3 ||str==NULL) {
        cell.textLabel.text = @"str";
    }
    
    cell.textLabel.text = str;

    
    return cell;
}

//返回当前操作表的行数的代理方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section==0) {
        return 系统进程.count;
    }
    if (section==1) {
        return 用户进程.count;
    }
    return 1;
}
//表格头部顶部 文字
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle; // Create
    if (section==0) {
        sectionTitle = @"系统进程";
    }
    if (section==1) {
        sectionTitle = @"用户进程";
    }
    
    return sectionTitle;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString*str;
    if (indexPath.section==0) {
        str=系统进程[indexPath.row];
    }
    if (indexPath.section==1) {
        str=用户进程[indexPath.row];
    }
    NSArray *arr = [str componentsSeparatedByString:@",,"];
    NSString*pid=arr[0];
    NSString*name=arr[1];
    NSLog(@"选择PID=%@   进程：%@",pid,name);
    [[NSUserDefaults standardUserDefaults] setObject:pid forKey:@"PID"];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Name"];
    [表格列表 reloadData];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:name];
    }
    NSString*CC=[[NSUserDefaults standardUserDefaults] objectForKey:@"PID"];
    cell.accessoryType=UITableViewCellAccessoryNone;
    cell.textLabel.textColor=[UIColor blackColor];
    if ([pid isEqual:CC]) {
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor=[UIColor greenColor];
    }
    
}
@end
