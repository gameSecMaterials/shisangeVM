//
//  PidModel.m
//  BeautyList
//
//  Created by HaoCold on 2020/11/23.
//  Copyright © 2020 HaoCold. All rights reserved.
//

#import "PidModel.h"
#import "NSTask.h"
//#import "YYModel.h"
#import <UIKit/UIKit.h>
//#import "JHLog.h"

@implementation PidModel

- (NSArray *)refreshModelArray:(int)sys
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/ps"];
    [task setArguments:[NSArray arrayWithObjects:@"aux", nil, nil]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    [task waitUntilExit];
    
    NSString * string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //NSLog(@"**** Result: %@", string);
    
    NSArray *array = [self modelArray:string sys:sys];
    
    return array;
}

- (NSArray *)modelArray:(NSString *)input sys:(int)sys
{
    NSString *str = input;
    
    NSArray *arr = [str componentsSeparatedByString:@"\n"];
    //NSLog(@"arr = %@", @(arr.count));
    
    NSMutableArray *marr = @[].mutableCopy;
    NSMutableArray *marr1 = @[].mutableCopy;
    NSString *pre = @"/var/containers/Bundle/Application/";
    NSString *pre1 = @" /Applications/";
    for (NSString *s in arr) {
        if ([s containsString:pre]) {
            [marr addObject:s];
        }else if ([s containsString:pre1]) {
            [marr1 addObject:s];
        }
    }
    
    //NSLog(@"marr = %@", @(marr.count));
    
    // 用户程序
    NSArray *arr1 = [self getModel:marr pre:pre];
    // 系统
    NSArray *arr2 = [self getModel:marr1 pre:pre1];
    if (sys==0) {
        return arr1;
    }
    if (sys==1) {
        return arr2;
    }
    return @[arr1, arr2];
}

- (NSArray *)getModel:(NSArray *)marr pre:(NSString *)pre
{
    NSMutableArray *result = @[].mutableCopy;
    for (NSString *s in marr) {
        NSArray *arr = [NSMutableArray arrayWithArray:[s componentsSeparatedByString:pre]];
        
        NSMutableArray *strs = [arr[0] componentsSeparatedByString:@" "].mutableCopy;
        [strs removeObject:@""];
        //NSLog(@"strs = %@", strs);
        
        NSString *name = [[arr[1] componentsSeparatedByString:@".app/"] lastObject];
        if ([name containsString:@"/"]) {
            break;
        }
        
        PidModel *model = [[PidModel alloc] init];
        model.name = name;
        model.pid = strs[1];
        
        [result addObject:[NSString stringWithFormat:@"%@,,%@",strs[1],name]];
    }
    return result;
}

@end
