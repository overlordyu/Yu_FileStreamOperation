# Yu_FileStreamOperation
文件切片上传，支持多线程切片上传，可设置文件切片数、上传线程数、支持切片上传后自动重试等，有GCD、NSOperation等多个版本，有任何需求请联系我。

'''
/// 根据文件路径上传文件
/// @param filePath 文件再沙盒中的路径
/// @param fileName 文件名，可用时间戳随机获取文件名
/// @param mimeType 文件类型，如：video/mov,video/mp4,image/jepg.....
/// @param contentIdentification 文件唯一标识符，可去除
-(void)uploadFileWithFilePath:(NSString *)filePath withFileName:(NSString *)fileName withMimeType:(NSString *)mimeType withIdentifier:(NSString *)contentIdentification;

///获取整个文件最终结果（成功或失败）的回调
@property(nonatomic,copy)UploadSuccessBlock uploadSuccessB;

'''
