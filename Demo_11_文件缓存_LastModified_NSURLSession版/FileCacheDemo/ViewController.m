//
//  ViewController.m
//  FileCacheDemo
//
//  Created by 微博@iOS程序犭袁（ http://weibo.com/luohanchenyilong/） on 15/9/1.
//  Copyright (c) 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "ViewController.h"

typedef void (^GetDataCompletion)(NSData *data);

static NSString *const kLastModifiedImageURL = @"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
// 响应的 LastModified
@property (nonatomic, copy) NSString *localLastModified;
@end

@implementation ViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super didReceiveMemoryWarning];
    [self getData:^(NSData *data) {
        self.iconView.image = [UIImage imageWithData:data];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self getData:^(NSData *data) {
        self.iconView.image = [UIImage imageWithData:data];
    }];
}

/*!
 @brief 如果本地缓存资源为最新，则使用使用本地缓存。如果服务器已经更新或本地无缓存则从服务器请求资源。
 
 @details
 
 步骤：
 1. 请求是可变的，缓存策略要每次都从服务器加载
 2. 每次得到响应后，需要记录住 LastModified
 3. 下次发送请求的同时，将LastModified一起发送给服务器（由服务器比较内容是否发生变化）
 
 @return 图片资源
 */
- (void)getData:(GetDataCompletion)completion {
    NSURL *url = [NSURL URLWithString:kLastModifiedImageURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];

    // 发送 LastModified
    if (self.localLastModified.length > 0) {
        [request setValue:self.localLastModified forHTTPHeaderField:@"If-Modified-Since"];
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // NSLog(@"%@ %tu", response, data.length);
        // 类型转换（如果将父类设置给子类，需要强制转换）
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"statusCode == %@", @(httpResponse.statusCode));
        // 判断响应的状态码是否是 304 Not Modified （更多状态码含义解释： https://github.com/ChenYilong/iOSDevelopmentTips）
        if (httpResponse.statusCode == 304) {
            NSLog(@"加载本地缓存图片");
            // 如果是，使用本地缓存
            // 根据请求获取到`被缓存的响应`！
            NSCachedURLResponse *cacheResponse =  [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
            // 拿到缓存的数据
            data = cacheResponse.data;
        }

        // 获取并且纪录 LastModified
        self.localLastModified = httpResponse.allHeaderFields[@"Last-Modified"];
        NSLog(@"%@", self.localLastModified);
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(data);
        });
    }] resume];
}

@end
