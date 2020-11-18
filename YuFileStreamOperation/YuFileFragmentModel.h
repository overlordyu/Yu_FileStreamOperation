//
//  YuFileFragmentModel.h
//  CMPEditor
//
//  Created by yu on 2019/11/5.
//  Copyright © 2019 yu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YuFileFragmentModel : NSObject

typedef enum : NSUInteger {
    FileUploadStateWaiting,//等待上传
    FileUploadStateLoading,//上传中
    FileUploadStateSuccess,//上传成功
    FileUploadStateFailure//上传失败
} FileUploadState;

///上传状态
@property(nonatomic,assign)FileUploadState uploadState;
///每个分片的大小
@property(nonatomic,assign)NSUInteger fileFragmentSize;
///每个分片的偏移位置,从0开始
@property(nonatomic,assign)NSUInteger fileFragmentOffset;
///每个分片的标识
@property(nonatomic,copy)NSString *fileFragmentId;
///切片位置 0.。。1.。。2
@property(nonatomic,assign)NSUInteger chunk;
///切片总数
@property(nonatomic,assign)NSUInteger chunks;
///重新上传的次数，超过三次，就直接标识整个文件上传失败
@property(nonatomic,assign)NSUInteger reuploadCount;

@end

NS_ASSUME_NONNULL_END
