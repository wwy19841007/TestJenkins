//
//  AL_CityMapInfo.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "AL_CityMapInfo.h"
#import "AFNetworking.h"
#import "tmpDefines.h"
#import "ZipArchive.h"

#define BACKGROUNDTASKIDENTIFIER 10241024
#define CITYCODEDICT @"cityCode"
#define STATUSDICT @"status"
#define VERSIONDICT @"version"

/**
 *  可能存在4种类型的AL_CityMapInfo，基础资源，省一级的不能下载的数据，代表下载全省数据的记录和地级市数据
 */
@interface AL_CityMapInfo(){
}

@property (nonatomic, strong) AFHTTPRequestOperation*         downloadOperation;

@end

static NSString *_baseUrl;
@implementation AL_CityMapInfo

+(JSONKeyMapper*)keyMapper
{
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"adcode": @"szCityCode",
                                                       @"size": @"nSize",
                                                       @"all_unzipsize": @"nAllSize",
                                                       @"all_url": @"szUrl",
                                                       @"name_en": @"szEnName",
                                                       @"name_ft": @"szTwName",
                                                       @"name_zh": @"szName",
                                                       @"updatetype": @"updateType",
                                                       @"version": @"dataNewVersion",
                                                       @"citys": @"arrayOfSubCities"
                                                       }];
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _observers = (NSMutableArray<AL_DownloadItemDelegate> *)[[NSMutableArray alloc] init];
        _isDownloaded = NO;
    }
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        if (self.szCityCode == nil || self.szCityCode.length == 0) {
            //基础资源
            NSString *szZipName = [self.szUrl lastPathComponent];
            
            self.szCityCode = @"0";
            self.szPathOnDevice =  _M_Path_Doc_Gps_;
            self.szpathOfTemp =  [NSString stringWithFormat:@"%@/%@.temp", _M_MapDataManager_TempPath, szZipName];
            self.szPathofDownload = [NSString stringWithFormat:@"%@/%@", document_path, szZipName];
            if (self.nSize == 0) {
                self.nSize = [[dict objectForKey:@"all_size"] integerValue];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.szpathOfTemp])
            {
                self.statusForDownload = AL_DownloadItemStatusStopped;
                NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:self.szpathOfTemp];
                self.nCountOfHasDownloaded = [fileData length];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.szPathofDownload])
            {
                self.statusForDownload = AL_DownloadItemStatusDownloaded;
                self.nCountOfHasDownloaded = self.nSize;
            }
            
            if ([self isHasBaseMapData])
            {
                self.statusForDownload = AL_DownloadItemStatusFinished;
                self.nCountOfHasDownloaded = self.nSize;
                self.isDownloaded = YES;
            }
        }else{
            //城市资源
            NSString *szZipName = [self.szUrl lastPathComponent];
            NSRange rangeUnderLine = [szZipName rangeOfString:@"."];
            NSString* szSubPathOnDevice = [szZipName substringToIndex:rangeUnderLine.location];//6是“.gdzip”
            
            self.szUrl = [NSString stringWithFormat:@"%@%@", _baseUrl, self.szUrl];
            self.szPathOnDevice = [NSString stringWithFormat:@"%@/chn/%@", _M_Path_Doc_Gps_, szSubPathOnDevice];
            self.szpathOfTemp =  [NSString stringWithFormat:@"%@/%@.temp", _M_MapDataManager_TempPath, szZipName];
            self.szPathofDownload = [NSString stringWithFormat:@"%@/%@", document_path, szZipName];
            if (self.nSize == 0) {
                self.nSize = [[dict objectForKey:@"all_size"] integerValue];
            }
            if  (self.nAllSize == 0){
                self.nAllSize = [[dict objectForKey:@"unzip_size"] integerValue];
            }
            
            if (!self.isProvince && [[NSFileManager defaultManager] fileExistsAtPath:self.szpathOfTemp])
            {
                self.statusForDownload = AL_DownloadItemStatusStopped;
                NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:self.szpathOfTemp];
                self.nCountOfHasDownloaded = [fileData length];
            }
            
            if (!self.isProvince && [[NSFileManager defaultManager] fileExistsAtPath:self.szPathofDownload])
            {
                self.statusForDownload = AL_DownloadItemStatusDownloaded;
                self.nCountOfHasDownloaded = self.nSize;
            }
            
            //判断下载数据是否存在
            if (!self.isProvince && [[NSFileManager defaultManager] fileExistsAtPath:self.szPathOnDevice])
            {
                self.statusForDownload = AL_DownloadItemStatusFinished;
                self.nCountOfHasDownloaded = self.nSize;
                self.isDownloaded = YES;
                //TODO isHasUpdateInfo对于旧版本的读取
            }
            
            if (self.arrayOfSubCities && self.arrayOfSubCities.count > 0) {
                self.isProvince = YES;
                
//                BOOL hasProvinceDownloaded = YES;
//                BOOL hasUpdate = NO;
//                BOOL isAllHasUpdate = YES;
//                for (AL_CityMapInfo *subCity in self.arrayOfSubCities)
//                {
//                    subCity.upperCity = self;
//                    
//                    if (!subCity.isDownloaded)
//                    {
//                        hasProvinceDownloaded = NO;
//                    }
//                    
//                    if (subCity.isHasUpdateInfo == NO)
//                    {
//                        isAllHasUpdate = NO;
//                    }
//                    
//                    if (subCity.isHasUpdateInfo)
//                    {
//                        hasUpdate = YES;
//                    }
//                }
                
//                self.isHasUpdateInfo = hasUpdate;//数据更新
                
                AL_CityMapInfo *allCityInfo = [[AL_CityMapInfo alloc] init];
                allCityInfo.szEnName = @"All Citys";
                allCityInfo.szName = @"全省";
                allCityInfo.szTwName = @"全省";
                allCityInfo.upperCity = self;
                allCityInfo.dataVersion = self.dataVersion;
                allCityInfo.dataNewVersion = self.dataNewVersion;
                allCityInfo.nSize = self.nSize;
                allCityInfo.nAllSize = self.nAllSize;
                allCityInfo.szUrl = @"";
                allCityInfo.arrayOfSubCities = nil;
//                allCityInfo.isHasUpdateInfo = isAllHasUpdate;
                allCityInfo.szCityCode = self.szCityCode;
//                if (!hasProvinceDownloaded)
//                {
//                    allCityInfo.statusForDownload = AL_DownloadItemStatusNone;
//                    self.statusForDownload        = AL_DownloadItemStatusNone;
//                }
//                else
//                {
//                    allCityInfo.statusForDownload = AL_DownloadItemStatusFinished;
//                    self.statusForDownload        = AL_DownloadItemStatusFinished;
//                }
                
                allCityInfo.isProvince = NO;
                allCityInfo.szPathOnDevice = @"";
                allCityInfo.szpathOfTemp = @"";
                allCityInfo.szPathofDownload = @"";
                allCityInfo.isError = NO;
                allCityInfo.nCountOfHasDownloaded = 0;
                
                [self.arrayOfSubCities insertObject:allCityInfo atIndex:0];
                
                [allCityInfo refreshUpperCityStatus];
            }
        }
        
        //还原历史版本和之前的下载状态，可能出现之前下载的版本和新更新的版本不一致的情况，对于之前已经加入等待序列但是还未开始下载的任务，保存状态
        NSString *cityUserDefaultCode = [NSString stringWithFormat:@"%@UDDETAIL", self.szCityCode];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]) {
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode];
            self.dataVersion = [dict objectForKey:VERSIONDICT];
            self.statusForDownload = [[dict objectForKey:STATUSDICT] integerValue];
            if (self.statusForDownload == AL_DownloadItemStatusWaitingForDownload ||
                self.statusForDownload == AL_DownloadItemStatusDownloading ||
                self.statusForDownload == AL_DownloadItemStatusPaused ||
                self.statusForDownload == AL_DownloadItemStatusStopped) {
                self.statusForDownload = AL_DownloadItemStatusStopped;
            }
        }else{
            self.dataVersion = self.dataNewVersion;
        }
        
        if ([self compareForUpdate]) {
            //如果有更新数据，则需要对当前已有的数据做处理
            switch (self.statusForDownload) {
                case AL_DownloadItemStatusWaitingForDownload:
                case AL_DownloadItemStatusDownloading:
                case AL_DownloadItemStatusPaused:
                case AL_DownloadItemStatusStopped:
                case AL_DownloadItemStatusDownloaded: {
                    [self cancel];
                    self.statusForDownload = AL_DownloadItemStatusStopped;
                    self.dataVersion = self.dataNewVersion;
                    break;
                }
                case AL_DownloadItemStatusFinished: {
                    self.isHasUpdateInfo = YES;
                    self.isDownloaded = YES;
                    break;
                }
                default: {
                    break;
                }
            }
        }
        //当重启后，状态发生变化，需要保存状态
        if (self.statusForDownload != AL_DownloadItemStatusNone) {
            [self saveItemStatus];
        }
    }
    return self;
}

+(void)setBaseUrl:(NSString *)baseUrl{
    _baseUrl = baseUrl;
}

- (void)addObserver:(id<AL_DownloadItemDelegate>)observer{
    if (observer) {
        [_observers addObject:observer];
    }
}

- (void)removeObserver:(id<AL_DownloadItemDelegate>)observer{
    if ([_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}

-(NSArray *)downloadedCities{
    NSMutableArray *downloadedCities = [[NSMutableArray alloc] init];
    
    if (self.arrayOfSubCities && self.arrayOfSubCities.count > 0) {
        for (AL_CityMapInfo *cityInfo in self.arrayOfSubCities) {
            if ([cityInfo.szCityCode isEqualToString:self.szCityCode]) {
                continue;
            }
            if (cityInfo.isDownloaded) {
                [downloadedCities addObject:cityInfo];
            }
        }
    }
    
    return downloadedCities;
}

-(BOOL)compareForUpdate{
    if (self.dataVersion == nil || self.dataVersion.length == 0 || self.dataNewVersion == nil || self.dataNewVersion.length == 0) {
        return NO;
    }
    if (self.szCityCode == nil || self.szCityCode.length == 0) {
        if ([self.dataVersion integerValue] < [self.dataNewVersion integerValue]) {
            return YES;
        }else{
            return NO;
        }
    }else{
        NSArray *oldVersionArray = [[self.dataVersion substringFromIndex:1] componentsSeparatedByString:@"."];
        NSInteger oldBigVersion = [[oldVersionArray firstObject] integerValue];
        NSInteger oldSmallVersion = [[oldVersionArray lastObject] integerValue];
        NSArray *newVersionArray = [[self.dataNewVersion substringFromIndex:1] componentsSeparatedByString:@"."];
        NSInteger newBigVersion = [[newVersionArray firstObject] integerValue];
        NSInteger newSmallVersion = [[newVersionArray lastObject] integerValue];
        if ((oldBigVersion < newBigVersion) || (oldBigVersion == newBigVersion && oldSmallVersion < newSmallVersion)) {
            return YES;
        }else{
            return NO;
        }
    }
}

- (BOOL)isHasBaseMapData
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/chn/overall/dbinfo.dat",_M_Path_Doc_Gps_]];
}

/**
 *  每当有状态变化的时候，纪录状态
 */
- (void)saveItemStatus{
    NSString *cityUserDefaultCode = [NSString stringWithFormat:@"%@UDDETAIL", self.szCityCode];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]) {
        NSMutableDictionary *cityDictionary = [[NSMutableDictionary alloc] init];
        [cityDictionary setObject:self.szCityCode forKey:CITYCODEDICT];
        [cityDictionary setObject:[NSString stringWithFormat:@"%ld", self.statusForDownload] forKey:STATUSDICT];
        [cityDictionary setObject:self.dataVersion?self.dataVersion:@"" forKey:VERSIONDICT];
        [[NSUserDefaults standardUserDefaults] setObject:cityDictionary forKey:cityUserDefaultCode];
    }else{
        NSMutableDictionary *cityDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]];
        [cityDictionary setObject:[NSString stringWithFormat:@"%ld", self.statusForDownload] forKey:STATUSDICT];
        [[NSUserDefaults standardUserDefaults] setObject:cityDictionary forKey:cityUserDefaultCode];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  删除的时候移除纪录
 */
- (void)removeStatus{
    NSString *cityUserDefaultCode = [NSString stringWithFormat:@"%@UDDETAIL", self.szCityCode];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:cityUserDefaultCode];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (AFHTTPRequestOperation *)downloadOperation{
    @synchronized(self)
    {
        if (!_downloadOperation) {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.szUrl]];
            //检查文件是否已经下载了一部分
            unsigned long long downloadedBytes = 0;
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.szpathOfTemp])
            {
                //获取已下载的文件长度
                NSFileManager *fileManager = [NSFileManager defaultManager]; // default is not thread safe
                NSError *error = nil;
                NSDictionary *fileDict = [fileManager attributesOfItemAtPath:self.szpathOfTemp error:&error];
                if (error) {
                    [self errorProcess:error];
                    return nil;
                }
                if (fileDict)
                {
                    downloadedBytes = [fileDict fileSize];
                }
                if (downloadedBytes > 0)
                {
                    NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
                    NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
                    [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
                    request = mutableURLRequest;
                }
            }
            //下载请求
            _downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            //下载进度回调
            __weak AL_CityMapInfo *tmpCityInfo = self;
            
            [_downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                tmpCityInfo.nCountOfHasDownloaded = totalBytesRead + downloadedBytes;
                for (id<AL_DownloadItemDelegate> delegate in tmpCityInfo.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItem:downloadedBytes:totalBytes:)]) {
                        [delegate downloadItem:tmpCityInfo downloadedBytes:totalBytesRead + downloadedBytes totalBytes:totalBytesExpectedToRead + downloadedBytes];
                    }
                }
            }];
            
            [_downloadOperation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
                
            }];
            [_downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Download finished city:%@", tmpCityInfo.szName);
                
                [tmpCityInfo finishDownload];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [tmpCityInfo errorProcess:error];
                return;
            }];
            
            //下载路径
            _downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:self.szpathOfTemp append:YES];
        }
    }
    return _downloadOperation;
}

-(void)start{
    //还没考虑更新的情况
    
    //全省数据
    if (self.upperCity && [self.upperCity.szCityCode isEqualToString:self.szCityCode]){
        if (self.statusForDownload == AL_DownloadItemStatusNone || self.statusForDownload == AL_DownloadItemStatusStopped || self.statusForDownload == AL_DownloadItemStatusDownloaded || self.isHasUpdateInfo) {
            for (AL_CityMapInfo *city in self.upperCity.arrayOfSubCities) {
                if ([city.szCityCode isEqualToString:self.szCityCode]) {
                    continue;
                }
                if (city.statusForDownload == AL_DownloadItemStatusNone || city.statusForDownload == AL_DownloadItemStatusStopped || city.statusForDownload == AL_DownloadItemStatusDownloaded || city.isHasUpdateInfo) {
                    [city start];
                } else if (city.statusForDownload == AL_DownloadItemStatusPaused) {
                    [city resume];
                }
            }
            return;
        }
    }
    
    if (self.statusForDownload == AL_DownloadItemStatusNone || self.statusForDownload == AL_DownloadItemStatusStopped || self.statusForDownload == AL_DownloadItemStatusDownloaded || self.isHasUpdateInfo){
        
        self.statusForDownload = AL_DownloadItemStatusWaitingForDownload;
        [self saveItemStatus];
        
        for (id<AL_DownloadItemDelegate> delegate in self.observers) {
            if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                [delegate downloadItemStatusChanged:self];
            }
            if ([delegate respondsToSelector:@selector(downloadItemStarted:)]) {
                [delegate downloadItemStarted:self];
            }
        }
        
        [self refreshUpperCityStatus];
    }
}

-(void)resume{
    if (self.statusForDownload == AL_DownloadItemStatusPaused){
        self.statusForDownload = AL_DownloadItemStatusWaitingForDownload;
        [self saveItemStatus];
        
        for (id<AL_DownloadItemDelegate> delegate in self.observers) {
            if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                [delegate downloadItemStatusChanged:self];
            }
            if ([delegate respondsToSelector:@selector(downloadItemResumed:)]) {
                [delegate downloadItemResumed:self];
            }
        }
        
        [self refreshUpperCityStatus];
    }
}

-(void)begin{
    if (self.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
        if (!self.isProvince && [[NSFileManager defaultManager] fileExistsAtPath:self.szpathOfTemp] && self.nCountOfHasDownloaded == self.nSize)
        {
            [self finishDownload];
            return;
        }
        if (!self.isProvince && [[NSFileManager defaultManager] fileExistsAtPath:self.szPathofDownload])
        {
            self.statusForDownload = AL_DownloadItemStatusDownloaded;
            [self saveItemStatus];
            
            for (id<AL_DownloadItemDelegate> delegate in self.observers) {
                if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                    [delegate downloadItemStatusChanged:self];
                }
            }
            
            [self refreshUpperCityStatus];
            [self unZipData];
            return;
        }
        if (self.downloadOperation.isPaused) {
            [self.downloadOperation resume];
        }else{
            [self.downloadOperation start];
        }
        self.statusForDownload = AL_DownloadItemStatusDownloading;
        [self saveItemStatus];
        
        for (id<AL_DownloadItemDelegate> delegate in self.observers) {
            if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                [delegate downloadItemStatusChanged:self];
            }
            if ([delegate respondsToSelector:@selector(downloadItemBegan:)]) {
                [delegate downloadItemBegan:self];
            }
        }
        
        [self refreshUpperCityStatus];
    }
}

-(void)pause{
    if (self.statusForDownload == AL_DownloadItemStatusDownloading || self.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
        if (self.downloadOperation.isExecuting){
            [self.downloadOperation pause];
        }
        
        self.statusForDownload = AL_DownloadItemStatusPaused;
        [self saveItemStatus];
        
        for (id<AL_DownloadItemDelegate> delegate in self.observers) {
            if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                [delegate downloadItemStatusChanged:self];
            }
            if ([delegate respondsToSelector:@selector(downloadItemPaused:)]) {
                [delegate downloadItemPaused:self];
            }
        }
        
        [self refreshUpperCityStatus];
    }
}

-(void)stop{
    if (self.statusForDownload == AL_DownloadItemStatusDownloading || self.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
        if (self.downloadOperation.isExecuting){
            [self.downloadOperation pause];
            [self.downloadOperation cancel];
        }
        _downloadOperation = nil;
        
        self.statusForDownload = AL_DownloadItemStatusStopped;
        [self saveItemStatus];
        
        for (id<AL_DownloadItemDelegate> delegate in self.observers) {
            if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                [delegate downloadItemStatusChanged:self];
            }
            if ([delegate respondsToSelector:@selector(downloadItemStopped:)]) {
                [delegate downloadItemStopped:self];
            }
        }
        
        [self refreshUpperCityStatus];
    }
}

-(void)cancel{
    if (self.statusForDownload == AL_DownloadItemStatusNone) {
        return;
    }
    
    if (self.statusForDownload == AL_DownloadItemStatusDownloading || self.statusForDownload == AL_DownloadItemStatusWaitingForDownload || self.statusForDownload == AL_DownloadItemStatusDownloaded) {
        [self stop];
    }
    
    NSError *error = nil;
    NSFileManager *fileManager=[NSFileManager defaultManager];
    
    
    if (self.isDownloaded && self.statusForDownload == AL_DownloadItemStatusFinished) {
        //删除已下载数据，针对所有已下载且未更新的情况
        if ([fileManager fileExistsAtPath:self.szPathOnDevice])
        {
            [fileManager removeItemAtPath:self.szPathOnDevice error:&error];
            if (error) {
                [self errorProcess:error];
                return;
            }
        }
        self.isDownloaded = NO;
        self.statusForDownload = AL_DownloadItemStatusNone;
        self.isHasUpdateInfo = NO;
    }else{
        //删除下载中数据，针对初次下载和更新下载
        if ([fileManager fileExistsAtPath:self.szpathOfTemp])
        {
            [fileManager removeItemAtPath:self.szpathOfTemp error:&error];
            if (error) {
                [self errorProcess:error];
                return;
            }
        }
        //删除已下载未解压的数据
        if ([fileManager fileExistsAtPath:self.szPathofDownload])
        {
            [fileManager removeItemAtPath:self.szPathofDownload error:&error];
            if (error) {
                [self errorProcess:error];
                return;
            }
        }
        if (!self.isDownloaded) {
            self.statusForDownload = AL_DownloadItemStatusNone;
            self.isHasUpdateInfo = NO;
        }else{
            self.statusForDownload = AL_DownloadItemStatusFinished;
        }
    }
    //需要判断解压状态
    
    [self removeStatus];
    
    for (id<AL_DownloadItemDelegate> delegate in self.observers) {
        if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
            [delegate downloadItemStatusChanged:self];
        }
        if ([delegate respondsToSelector:@selector(downloadItemCancelled:)]) {
            [delegate downloadItemCancelled:self];
        }
    }
    
    [self refreshUpperCityStatus];
}

-(NSString *)status{
    switch (self.statusForDownload) {
        case AL_DownloadItemStatusNone: {
            return @"未下载";
            break;
        }
        case AL_DownloadItemStatusWaitingForDownload: {
            return @"等待中";
            break;
        }
        case AL_DownloadItemStatusDownloading: {
            return @"正在下载";
            break;
        }
        case AL_DownloadItemStatusPaused: {
            return @"已暂停";
            break;
        }
        case AL_DownloadItemStatusStopped: {
            return @"已停止";
            break;
        }
        case AL_DownloadItemStatusDownloaded: {
            return @"下载完成";
            break;
        }
        case AL_DownloadItemStatusFinished: {
            return @"处理完成";
            break;
        }
        default: {
            return @"未下载";
            break;
        }
    }
}

-(void)finishDownload{
    //TODO 更新isDownload
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:self.szpathOfTemp toPath:self.szPathofDownload error:&error];
    if (error) {
        //删除已下载的数据
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.szpathOfTemp])
        {
            NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:self.szpathOfTemp error:&err];
            if (err) {
                [self errorProcess:err];
                return;
            }
        }
        [self errorProcess:error];
        return;
    }
    self.statusForDownload = AL_DownloadItemStatusDownloaded;
    [self saveItemStatus];
    
    for (id<AL_DownloadItemDelegate> delegate in self.observers) {
        if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
            [delegate downloadItemStatusChanged:self];
        }
    }
    
    [self refreshUpperCityStatus];
    
    [self unZipData];
}

-(void)unZipData{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        ZipArchive *zipArchiver = [[ZipArchive alloc] init];
        NSString* szPathDest = _M_Path_MultiCityData_;
        NSError *error = nil;
        
        //如果有全量更新就删除原先的数据
        if (self.updateType == 0 && self.isHasUpdateInfo)
        {
            [[NSFileManager defaultManager] removeItemAtPath:self.szPathOnDevice error:&error];
            if (error) {
                [self errorProcess:error];
                return;
            }
        }
        
        if (![zipArchiver UnzipOpenFile:self.szPathofDownload])
        {
            [self errorProcess:[NSError errorWithDomain:@"ZipArchive" code:0 userInfo:@{@"unzip open error":@"description"}]];
            return;
        }
        if (![zipArchiver UnzipFileTo:szPathDest overWrite:YES])
        {
            [zipArchiver UnzipCloseFile];
            //删除已解压的数据
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.szPathOnDevice])
            {
                [[NSFileManager defaultManager] removeItemAtPath:self.szPathOnDevice error:&error];
                if (error) {
                    [self errorProcess:error];
                    return;
                }
            }
            [self errorProcess:[NSError errorWithDomain:@"ZipArchive" code:0 userInfo:@{@"unzip error":@"description"}]];
            return;
        }
        [zipArchiver UnzipCloseFile];
        
        [[NSFileManager defaultManager] removeItemAtPath:self.szPathofDownload error:&error];
        if (error) {
            [self errorProcess:error];
            return;
        }
        self.statusForDownload = AL_DownloadItemStatusFinished;
        self.isDownloaded = YES;
        [self saveItemStatus];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (id<AL_DownloadItemDelegate> delegate in self.observers) {
                if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                    [delegate downloadItemStatusChanged:self];
                }
                if ([delegate respondsToSelector:@selector(downloadItemFinished:)]) {
                    [delegate downloadItemFinished:self];
                }
            }
            
            [self refreshUpperCityStatus];
        });
    });
    
}

-(void)errorProcess:(NSError *)error{
    [self stop];
    for (id<AL_DownloadItemDelegate> delegate in self.observers) {
        if ([delegate respondsToSelector:@selector(downloadItem:FailedWithError:)]) {
            [delegate downloadItem:self FailedWithError:error];
        }
    }
}

-(NSString *)description{
    if (self.arrayOfSubCities) {
        NSString *result = [NSString stringWithFormat:@"%@{\r%@\r}", self.szName, self.arrayOfSubCities];
        return result;
    }else{
        NSString *result = [NSString stringWithFormat:@"%@", self.szName];
        return result;
    }
}

- (void)refreshUpperCityStatus{
    //TODO 数据更新和已下载状态
    if (self.upperCity == nil) {
        return;
    }
    AL_CityMapInfo *province = self.upperCity;
    AL_CityMapInfo *subProvince;
    for (AL_CityMapInfo *city in province.arrayOfSubCities) {
        if ([city.szCityCode isEqualToString:province.szCityCode]) {
            subProvince = city;
            break;
        }
    }
    
    for (AL_CityMapInfo *city in province.arrayOfSubCities) {
        if ([city.szCityCode isEqualToString:province.szCityCode]) {
            continue;
        }
        if (city.isHasUpdateInfo) {
            province.isHasUpdateInfo = YES;
            subProvince.isHasUpdateInfo = YES;
        }
        switch (city.statusForDownload) {
            case AL_DownloadItemStatusNone: {
                province.statusForDownload = AL_DownloadItemStatusNone;
                [province saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in province.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:province];
                    }
                }
                subProvince.statusForDownload = AL_DownloadItemStatusNone;
                [subProvince saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in subProvince.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:subProvince];
                    }
                }
                return;
            }
            case AL_DownloadItemStatusWaitingForDownload:
            case AL_DownloadItemStatusDownloading:
            case AL_DownloadItemStatusDownloaded: {
                province.statusForDownload = AL_DownloadItemStatusDownloading;
                [province saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in province.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:province];
                    }
                }
                subProvince.statusForDownload = AL_DownloadItemStatusDownloading;
                [subProvince saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in subProvince.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:subProvince];
                    }
                }
                return;
            }
            case AL_DownloadItemStatusPaused:
            case AL_DownloadItemStatusStopped: {
                province.statusForDownload = AL_DownloadItemStatusStopped;
                [province saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in province.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:province];
                    }
                }
                subProvince.statusForDownload = AL_DownloadItemStatusStopped;
                [subProvince saveItemStatus];
                for (id<AL_DownloadItemDelegate> delegate in subProvince.observers) {
                    if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
                        [delegate downloadItemStatusChanged:subProvince];
                    }
                }
                return;
            }
            case AL_DownloadItemStatusFinished: {
                break;
            }
            default: {
                break;
            }
        }
    }
    
    province.statusForDownload = AL_DownloadItemStatusFinished;
    [province saveItemStatus];
    for (id<AL_DownloadItemDelegate> delegate in province.observers) {
        if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
            [delegate downloadItemStatusChanged:province];
        }
    }
    subProvince.statusForDownload = AL_DownloadItemStatusFinished;
    [subProvince saveItemStatus];
    for (id<AL_DownloadItemDelegate> delegate in subProvince.observers) {
        if ([delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
            [delegate downloadItemStatusChanged:subProvince];
        }
    }
}

-(void)dealloc{
    [self.observers removeAllObjects];
    [[UIApplication sharedApplication] endBackgroundTask:BACKGROUNDTASKIDENTIFIER];
}

@end
