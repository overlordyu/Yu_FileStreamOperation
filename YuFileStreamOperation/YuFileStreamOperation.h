//
//  YuFileStreamOperation.h
//  CMPEditor
//
//  Created by yu on 2019/11/5.
//  Copyright © 2019 yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuFileFragmentModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YuFileStreamOperation : NSObject

///定义为单例
+(instancetype)shareFileOperation;

///根据路径创建
-(instancetype)initYuFileStreamOperationWithPath:(NSString *)filePath;

///读取文件分片的data
-(NSData *)readDataForFeagment:(YuFileFragmentModel *)fileFragment;

///文件分片数组
@property(nonatomic,strong)NSMutableArray<YuFileFragmentModel *> *fragmentArr;


@end

NS_ASSUME_NONNULL_END
