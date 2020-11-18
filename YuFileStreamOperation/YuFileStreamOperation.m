//
//  YuFileStreamOperation.m
//  CMPEditor
//
//  Created by yu on 2019/11/5.
//  Copyright © 2019 yu. All rights reserved.
//


#import "YuFileStreamOperation.h"
#import <CommonCrypto/CommonDigest.h>

@interface YuFileStreamOperation ()

///文件路径
@property(nonatomic,copy)NSString *filePath;
///文件名称
@property(nonatomic,copy)NSString *fileName;
///文件大小
@property(nonatomic,assign)NSUInteger fileSize;

///读文件
@property(nonatomic,strong)NSFileHandle *readFileHandle;

///设置每个文件切片的大小 MB
@property(nonatomic,assign)NSUInteger fileFragmentSize;

@end

@implementation YuFileStreamOperation

///创建单例
+(instancetype)shareFileOperation{
    
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

-(instancetype)initYuFileStreamOperationWithPath:(NSString *)filePath{
    self = [super init];
    if (self) {
        if (![self getFileInfoWithPath:filePath]) {
            return nil;
        }
        
        ///创建读文件操作
        _readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        ///获取文件切片
        [self getFileFragmentArr];
        
    }
    return self;
}

///获取文件所有信息，判断文件是否存在
-(BOOL )getFileInfoWithPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path]) {
        [WSProgressHUD showErrorWithStatus:@"获取视频路径发生错误，请稍后重试！"];
        [CommonInterface autoDismiss:2.0];
        return NO;
    }
    
    self.filePath = path;
    
    NSDictionary *infoDic = [fileManager attributesOfItemAtPath:path error:nil];
    self.fileSize = infoDic.fileSize;
    
    self.fileName = [path lastPathComponent];
    
    if (self.fileSize < (20*1024*1024) ) {//20MB
        
        self.fileFragmentSize = 500*1024;//500K
        
    }else if (self.fileSize < (100*1024*1024)) {//100MB
        
        self.fileFragmentSize = 2*1024*1024;//2MB
        
    }else{
        
        self.fileFragmentSize = 10*1024*1024;
    }
    
    return YES;
}

///获取文件切片
-(void)getFileFragmentArr{
    
    ///设置每个切片的大小 MB
    NSUInteger fragmentSize = self.fileFragmentSize;
    
    //切片总数，假如不能整除，就+1
    NSUInteger chunks = (int)ceil(_fileSize*1.0 / fragmentSize);
    
    _fragmentArr = [NSMutableArray array];
    for (NSInteger i = 0; i < chunks; i ++) {
        YuFileFragmentModel *model = [[YuFileFragmentModel alloc] init];
        model.uploadState = FileUploadStateWaiting;
        model.fileFragmentId = [self createFileKey];
        model.fileFragmentOffset = i * fragmentSize;
        model.chunk = i;
        model.chunks = chunks;
        
        if (i == chunks -1) {//最后一个切片的大小为：总大小 - 此切片偏移
            model.fileFragmentSize = _fileSize - model.fileFragmentOffset;
        }else{
            model.fileFragmentSize = fragmentSize;
        }
        [_fragmentArr addObject:model];
    }
    //NSLog(@"");
}

///读取文件分片的data
-(NSData *)readDataForFeagment:(YuFileFragmentModel *)fileFragment{
    //先seek到切片的偏移位置，再读取此片段的data
    if (fileFragment) {
        [_readFileHandle seekToFileOffset:fileFragment.fileFragmentOffset];
        NSData *data;
        if (fileFragment.chunk == fileFragment.chunks-1) {
            data = [_readFileHandle readDataToEndOfFile];
        }else{
            data = [_readFileHandle readDataOfLength:fileFragment.fileFragmentSize];
        }
        return data;
    }
    return nil;
}


///创建一个随机的MD5加密的id
- (NSString *)createFileKey {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)strlen(cStr), result );
    CFRelease(uuid);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08lx",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15],
            (unsigned long)(arc4random() % NSUIntegerMax)];
}


@end
