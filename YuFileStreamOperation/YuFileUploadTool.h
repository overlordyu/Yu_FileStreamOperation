//
//  YuFileUploadTool.h
//  CMPEditor
//
//  Created by yu on 2019/11/6.
//  Copyright © 2019 yu. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef void(^UploadSuccessBlock)(BOOL isSuccess,NSUInteger chunks);

NS_ASSUME_NONNULL_BEGIN

@interface YuFileUploadTool : NSObject

///根据文件路径上传文件
-(void)uploadFileWithFilePath:(NSString *)filePath withFileName:(NSString *)fileName withMimeType:(NSString *)mimeType withIdentifier:(NSString *)contentIdentification;

///获取最终上传的失败或者成功的回调
@property(nonatomic,copy)UploadSuccessBlock uploadSuccessB;

@end

NS_ASSUME_NONNULL_END
