//
//  YuFileUploadTool.m
//  CMPEditor
//
//  Created by yu on 2019/11/6.
//  Copyright © 2019 yu. All rights reserved.
//

#import "YuFileUploadTool.h"
#import "YuFileStreamOperation.h"
#import "YuFileFragmentModel.h"

@interface YuFileUploadTool ()
@property(nonatomic,copy)NSString *fileName;//文件名
@property(nonatomic,copy)NSString *mimeType;///文件类型
@property(nonatomic,copy)NSString *contentIdentification;//视频标识符

@property(nonatomic,strong)YuFileStreamOperation *fileOperation;

///记录上传前的时间，以便获取整个上传时间
@property(nonatomic,strong)NSDate *preDate;

//统计成功的次数
@property(nonatomic,assign)NSInteger successCount;

/**控制并发数信号量*/
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
/**上传队列*/
@property (nonatomic, strong) dispatch_queue_t queue;
/**上传dispatch_group_t*/
@property (nonatomic, strong) dispatch_group_t group;
/**标记是否需要上传*/
@property (nonatomic, assign)  BOOL needRestart;

@property(nonatomic,strong)NSLock *lock;
/**上传失败后，默认重新上传3次*/
@property (nonatomic, assign)NSInteger reUploadCount;

@end

@implementation YuFileUploadTool

///根据文件路径上传文件
-(void)uploadFileWithFilePath:(NSString *)filePath withFileName:(NSString *)fileName withMimeType:(NSString *)mimeType withIdentifier:(NSString *)contentIdentification{
    
    self.fileName = fileName;
    self.mimeType = mimeType;
    self.contentIdentification = contentIdentification;
    
    ///最大4个进程
    self.semaphore = dispatch_semaphore_create(4);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.group = dispatch_group_create();
    self.needRestart = NO;
    self.reUploadCount = 3;
    self.successCount = 0;
    _lock = [[NSLock alloc] init];
    
    _fileOperation = [[YuFileStreamOperation alloc] initYuFileStreamOperationWithPath:filePath];
    
    ///开始启动多线程并上传文件切片
    [self startUploadFileFragement];
}

///开始启动多线程并上传文件切片
-(void)startUploadFileFragement{
    _preDate = [NSDate date];
  
    [self.lock lock];
    if (self.needRestart) {
        self.needRestart = NO;
    }
    [self.lock unlock];
    NSArray *fragModelArr = self.fileOperation.fragmentArr;
    __weak typeof(self) weakSelf = self;
    [fragModelArr enumerateObjectsUsingBlock:^(YuFileFragmentModel* _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (model.uploadState == FileUploadStateWaiting || model.uploadState == FileUploadStateFailure) {
            model.uploadState = FileUploadStateLoading;
            
            dispatch_group_enter(weakSelf.group);
            dispatch_group_async(weakSelf.group, weakSelf.queue, ^{
                dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
                ///上传视文件
                [self uploadFileWithFragmentModel:model];
            });
        }
    }];
    
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        if (!self.needRestart) {//假如全部成功
            //NSLog(@"时间间隔是 %d ！",(int)[[NSDate date] timeIntervalSinceDate:self.preDate]);

            if (self.uploadSuccessB) {self.uploadSuccessB(YES,self.fileOperation.fragmentArr.count);///全部上传成功！
            }
        }else{//假如存在失败的，须重新上传3次
            [self.lock lock];
            if (self.reUploadCount>0) {
                self.reUploadCount --;
                [self.lock unlock];
                [self startUploadFileFragement];
            }else{
                if (self.uploadSuccessB) {self.uploadSuccessB(NO,self.fileOperation.fragmentArr.count);///彻底上传失败！
                }
            }
        }
    });
    
}

///上传视频
-(void)uploadFileWithFragmentModel:(YuFileFragmentModel *)fragmentModel{
 
    __weak typeof(self) weakSelf = self;
    NSString *url = [NSString stringWithFormat:@"%@%@",KBaseUrlVideo,KVideoUpload];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.contentIdentification forKey:@"videoIdentification"];
    
    NSString *siteId = [[NSUserDefaults standardUserDefaults] valueForKey:KSiteId];
    long siteLong = [siteId longLongValue];
    NSNumber *siteIdLong = [NSNumber numberWithLong:siteLong];
    [params setValue:siteIdLong forKey:@"siteId"];
    
    [params setValue:@(fragmentModel.chunk) forKey:@"chunk"];
    [params setValue:@(fragmentModel.chunks) forKey:@"chunks"];
    [self.lock lock];
    NSData *data = [self.fileOperation readDataForFeagment:fragmentModel];
    [self.lock unlock];
//    NSLog(@"正在上传第%ld片，总数是%ld---%@",
//          fragmentModel.chunk+1,fragmentModel.chunks,[NSThread currentThread]);
   
    //更新上传视频的总体进度
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat completed = self.successCount*1.0f/self.fileOperation.fragmentArr.count;
        [WSProgressHUD showProgress:completed status:@"正在上传视频..." maskType:WSProgressHUDMaskTypeBlack];
    });
    
    [CommonInterface PostFileWithURL:url params:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:data name:@"file" fileName:weakSelf.fileName mimeType:weakSelf.mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(id  _Nonnull responseObject, NSURLSessionDataTask * _Nonnull task) {
        
        ///请求成功并且有值
        if ([responseObject[@"code"] integerValue] == 200) {
            [weakSelf changeStateForModel:fragmentModel withState:FileUploadStateSuccess];
            //NSLog(@"第%ld片成功了！！！",fragmentModel.chunk+1);
        }else{
            [weakSelf changeStateForModel:fragmentModel withState:FileUploadStateFailure];
            //NSLog(@"第%ld片失败了！！！",fragmentModel.chunk+1);
        }
        
        ///信号量加1
        dispatch_semaphore_signal(weakSelf.semaphore);
        ///enter跟leave一一对应
        dispatch_group_leave(weakSelf.group);
        
    } failure:^(NSError * _Nonnull error,NSURLSessionDataTask * _Nonnull task) {
        [weakSelf changeStateForModel:fragmentModel withState:FileUploadStateFailure];
        //NSLog(@"第%ld片失败了！！！",fragmentModel.chunk+1);
        
        ///信号量加1
        dispatch_semaphore_signal(weakSelf.semaphore);
        ///enter跟leave一一对应
        dispatch_group_leave(weakSelf.group);
    }];
}

///上传每个切片后，更改切片的当前状态
-(void)changeStateForModel:(YuFileFragmentModel *)model withState:(FileUploadState )state{
    [self.lock lock];
    model.uploadState = state;
    if (state == FileUploadStateSuccess) {
        self.successCount ++;
    }
    if (state == FileUploadStateFailure) {
        self.needRestart = YES;
    }
    [self.lock unlock];
}

@end
