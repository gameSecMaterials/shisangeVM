//
//  ViewController.m
//  Radar
//
//  Created by 十三哥 on 2022/8/19.
//
#define 屏幕宽度  [UIScreen mainScreen].bounds.size.width
#define 屏幕高度 [UIScreen mainScreen].bounds.size.height
#import "ViewController.h"
#include <stdio.h>
#include <string>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <UIKit/UIKit.h>
#import <dlfcn.h>
#import "Root.h"
#import <AVFoundation/AVFoundation.h>
#import "TableView.h"
NSString* UDID;
NSString* udid(){
    static CFStringRef (*$MGCopyAnswer)(CFStringRef);
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    $MGCopyAnswer = reinterpret_cast<CFStringRef (*)(CFStringRef)>(dlsym(gestalt, "MGCopyAnswer"));
    UDID=(__bridge NSString *)$MGCopyAnswer(CFSTR("SerialNumber"));
    
    return UDID;
}
extern "C" kern_return_t mach_vm_region_recurse(
                       vm_map_t                 map,
                       mach_vm_address_t        *address,
                       mach_vm_size_t           *size,
                       uint32_t                 *depth,
                       vm_region_recurse_info_t info,
                       mach_msg_type_number_t   *infoCnt);
mach_port_t get_task;
pid_t get_processes_pid() {
    size_t length = 0;
    static const int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    int err = sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, NULL, &length, NULL, 0);
    if (err == -1) err = errno;
    if (err == 0) {
        struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length);
        if(procBuffer == NULL) return -1;
        
        sysctl((int *)name, (sizeof(name) / sizeof(*name)) - 1, procBuffer, &length, NULL, 0);
        int count = (int)length / sizeof(struct kinfo_proc);
        for (int i = 0; i < count; ++i) {
            const char *procname = procBuffer[i].kp_proc.p_comm;
            NSString *进程名字=[NSString stringWithFormat:@"%s",procname];
            pid_t pid = procBuffer[i].kp_proc.p_pid;
            //自己写判断进程名 和平精英
            if([进程名字 containsString:@"ShadowTracker"])
            {
                kern_return_t kret = task_for_pid(mach_task_self(), pid, &get_task);
                if (kret == KERN_SUCCESS) {
                    return pid;
                }
            }
        }
    }
    
    return  -1;
}

vm_map_offset_t get_base_address() {
    vm_map_offset_t vmoffset = 0;
    vm_map_size_t vmsize = 0;
    uint32_t nesting_depth = 0;
    struct vm_region_submap_info_64 vbr;
    mach_msg_type_number_t vbrcount = 16;
    pid_t pid =get_processes_pid();
    kern_return_t kret = task_for_pid(mach_task_self(), pid, &get_task);
    if (kret == KERN_SUCCESS) {
        mach_vm_region_recurse(get_task, &vmoffset, &vmsize, &nesting_depth, (vm_region_recurse_info_t)&vbr, &vbrcount);
    }
    
    return vmoffset;
}
bool Read(long address, void *buffer, int length)
{
//    if (address > 0x100000000 && address < 0x2000000000) return false;
    vm_size_t size = 0;
    kern_return_t error = vm_read_overwrite(get_task, (vm_address_t)address, length, (vm_address_t)buffer, &size);
    if(error != KERN_SUCCESS || size != length) {
        return false;
    }
    return true;
}
template<typename T> T 读取数据(long address) {
    T data;
    Read(address, reinterpret_cast<void *>(&data), sizeof(T));
    return data;
}


static UITextField *textField;
@interface ViewController ()
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@end
UIButton*读取;
UILabel*提示;
UILabel*地址显示;
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self UI];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"绘制开关"];

}


-(void)UI
{
    UIButton*xzjc= [[UIButton alloc] initWithFrame:CGRectMake(屏幕宽度/2-50, 150,100, 40)];
    [xzjc setTitle:@"选择进程" forState:UIControlStateNormal];
    [xzjc setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    xzjc.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
    [xzjc.titleLabel setFont:[UIFont systemFontOfSize:20]];
    xzjc.layer.cornerRadius = 5;
    [xzjc addTarget:self action:@selector(xzbg) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:xzjc];
    
    UILabel *gequming = [[UILabel alloc] initWithFrame:CGRectMake(50, 80,屏幕宽度-100, 50)];
    gequming.numberOfLines = 0;
    gequming.lineBreakMode = NSLineBreakByCharWrapping;
    //替换某个字符
    gequming.text = @"测试跨进程读取";
    gequming.textAlignment = NSTextAlignmentCenter;
    gequming.font = [UIFont boldSystemFontOfSize:30];
    gequming.textColor = [UIColor greenColor];
    [self.view addSubview:gequming];
    
    
    textField = [[UITextField alloc] init];
    
    // 数字键盘
    //textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.font = [UIFont systemFontOfSize:14];//大小
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:@"请输入要读取的基址" attributes:
                                      @{NSForegroundColorAttributeName:[UIColor colorWithRed:1 green:0 blue:0 alpha:1],//默认文字颜色
                                        NSFontAttributeName:textField.font
                                      }];
    textField.attributedPlaceholder = attrString;
    textField.clearButtonMode = UITextFieldViewModeAlways;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.backgroundColor=[UIColor colorWithRed:0 green:1 blue:1 alpha:1];
    textField.textAlignment = NSTextAlignmentCenter;
    textField.delegate = self;
    textField.textColor=[UIColor colorWithRed:1 green:0.7569 blue:0.7569 alpha:1];//输入文字颜色
    
    textField.frame=CGRectMake(屏幕宽度/2-80, 220, 160, 30);
    textField.layer.cornerRadius = 15;//圆角
    textField.layer.shadowRadius=15;
    [textField addTarget:self action:@selector(textFieldDidEndEditing:) forControlEvents:UIControlEventEditingChanged];
    
    [self.view addSubview:textField];
    
    
    //时间显示
    地址显示 = [[UILabel alloc] initWithFrame:CGRectMake(50, 屏幕高度/3,屏幕宽度-100, 150)];
    地址显示.numberOfLines = 0;
    地址显示.lineBreakMode = NSLineBreakByCharWrapping;
    //替换某个字符
    地址显示.text = [NSString stringWithFormat:@"成功ROOT运行\n获取到序列号\n%@\n\n请选择进程操作",udid()];
    地址显示.textAlignment = NSTextAlignmentCenter;
    地址显示.font = [UIFont boldSystemFontOfSize:20];
    地址显示.textColor = [UIColor colorWithRed:1 green:0 blue:1 alpha:1];
    [self.view addSubview:地址显示];
    
    读取= [[UIButton alloc] initWithFrame:CGRectMake(50, 屏幕高度-100,屏幕宽度-100, 50)];
    [读取 setTitle:@"读取" forState:UIControlStateNormal];
    [读取 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    读取.backgroundColor = [UIColor colorWithRed:0 green:1 blue:1 alpha:1];
    [读取.titleLabel setFont:[UIFont systemFontOfSize:20]];
    读取.layer.cornerRadius = 5;
    [读取 addTarget:self action:@selector(读取数据) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:读取];
    
    提示 = [[UILabel alloc] initWithFrame:CGRectMake(50, 200,屏幕宽度-100, 150)];
    提示.numberOfLines = 0;
    提示.lineBreakMode = NSLineBreakByCharWrapping;
    //替换某个字符
    提示.text = [NSString stringWithFormat:@""];
    提示.textAlignment = NSTextAlignmentCenter;
    提示.font = [UIFont boldSystemFontOfSize:20];
    提示.textColor = [UIColor colorWithRed:1 green:0 blue:1 alpha:1];
    [self.view addSubview:提示];
}

-(void)xzbg
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TableView *settingVc = [[TableView alloc] init];
        UIViewController *tabbarVc = UIApplication.sharedApplication.keyWindow.rootViewController;

        UINavigationController *hookNavi = [[UINavigationController alloc] initWithRootViewController:settingVc];
        [tabbarVc presentViewController:hookNavi animated:YES completion:nil];
    });
}
- (void)textFieldDidEndEditing:(UITextField *)textField  {
    if(textField.text.length == 0){
        提示.text=@"请输入基址地址";
        //输入为空不操作 刷新表格
    }else{
        提示.text=textField.text;
    }
    
}
UILabel*地址数据;
UIButton*启动绘制;
-(void)读取数据
{
    [地址数据 removeFromSuperview];
    地址数据 = [[UILabel alloc] initWithFrame:CGRectMake(50, 屏幕高度/2,屏幕宽度-100, 250)];
    地址数据.numberOfLines = 0;
    地址数据.lineBreakMode = NSLineBreakByCharWrapping;
    地址数据.textAlignment = NSTextAlignmentCenter;
    地址数据.font = [UIFont boldSystemFontOfSize:20];
    地址数据.textColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
    [self.view addSubview:地址数据];
    
    
    if (get_processes_pid()==-1) {
        地址数据.text = [NSString stringWithFormat:@"先启动游戏"];
    }else{
        
        long addrss;
        unsigned long red = strtoul([textField.text UTF8String],0,16);
        addrss=读取数据<long>(get_base_address()+red);
        
        NSString*dizhi=[NSString stringWithFormat:@"起始地址\n0x%llx\n  +  0x%@\n读取坐标数据\n0x%lx\n%ld",get_base_address(),textField.text,addrss,addrss];
        地址数据.text = [NSString stringWithFormat:@"%@",dizhi];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (UDID==NULL) {
            [读取 setTitle:@"读取失败 未获取到ROOT权限" forState:UIControlStateNormal];
        }else if(textField.text.length<3){
            [读取 setTitle:@"请先输入基址地址" forState:UIControlStateNormal];
        }
        else{
            [读取 setTitle:@"读取成功" forState:UIControlStateNormal];
            if (textField.text!=nil) {
                [启动绘制 removeFromSuperview];
                启动绘制= [[UIButton alloc] initWithFrame:CGRectMake(50, 屏幕高度-200,屏幕宽度-100, 50)];
                [启动绘制 setTitle:@"启动绘制" forState:UIControlStateNormal];
                [启动绘制 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                启动绘制.backgroundColor = [UIColor colorWithRed:0.5 green:1 blue:1 alpha:1];
                [启动绘制.titleLabel setFont:[UIFont systemFontOfSize:20]];
                启动绘制.layer.cornerRadius = 5;
                [启动绘制 addTarget:self action:@selector(启动) forControlEvents:UIControlEventTouchUpInside];
                [self.view addSubview:启动绘制];
            }
            
            
        }
        
        读取.backgroundColor=[UIColor colorWithRed:0 green:1 blue:0 alpha:1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [读取 setTitle:@"读取数据" forState:UIControlStateNormal];
            读取.backgroundColor=[UIColor colorWithRed:0 green:1 blue:1 alpha:1];
        });
    });
    
}
-(void)PID:(NSString*)PID Name:(NSString*)Name
{
    地址显示.text = [NSString stringWithFormat:@"成功ROOT运行\n获取到序列号\n%@\n\nPID:%@  Name:%@",udid(),PID,Name];
}
static BOOL 绘制开关=YES;
-(void)启动
{
    绘制开关=!绘制开关;
    
    if (绘制开关) {
        [启动绘制 setTitle:@"启动绘制" forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"绘制开关"];
        启动绘制.backgroundColor = [UIColor colorWithRed:1 green:0.5 blue:1 alpha:1];
    }else{
        [启动绘制 setTitle:@"关闭绘制" forState:UIControlStateNormal];
        启动绘制.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"绘制开关"];
    }
   
    
}

@end
