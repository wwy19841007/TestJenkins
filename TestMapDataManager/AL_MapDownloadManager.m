//
//  AL_MapDownloadManager.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "AL_MapDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "ZipArchive.h"
#import "zlib.h"
#import "ASIHTTPRequest.h"
#import "AFNetworking.h"

@interface AL_MapDownloadManager()<AL_DownloadItemDelegate>

@property (nonatomic, strong, readwrite) NSMutableArray *downloadingItems;

@property (nonatomic, strong, readwrite) NSMutableArray *downloadedItems;

//@property (nonatomic, strong) NSMutableArray *downloadingOperations;

@end

@implementation AL_MapDownloadManager

//MD5加密
- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

-(NSData *)uncompressZippedData:(NSData *)compressedData
{
    if ([compressedData length] == 0) return compressedData;
    
    NSUInteger full_length = [compressedData length];
    
    NSUInteger half_length = [compressedData length] / 2;
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = (uint)[compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uint)([decompressed length] - strm.total_out);
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
        
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}

+ (AL_MapDownloadManager *)shareInstance
{
    static AL_MapDownloadManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AL_MapDownloadManager alloc] init];
    });
    return instance;
}

- (id)init;
{
    self = [super init];
    if (self){
//        self.mapVersion = @"V27.2.030005.0014";
        self.mapVersion = @"V29.1.030005.0003";
        self.engineVersion = @"V 7.1.030005.0065";
        
        //已下载城市
        self.downloadedItems = [[NSMutableArray alloc] init];
        
        //正在下载城市
        self.downloadingItems = [[NSMutableArray alloc] init];
        
        NSFileManager *fileManager=[NSFileManager defaultManager];
        NSString *webPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/NaviTemp"];
        if(![fileManager fileExistsAtPath:webPath])
        {
            [fileManager createDirectoryAtPath:webPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

-(NSInteger)downloadingItemCount{
    NSInteger count = 0;
    for (id<AL_DownloadItem> downloadItem in self.downloadingItems) {
        if (downloadItem.statusForDownload == AL_DownloadItemStatusDownloading || downloadItem.statusForDownload == AL_DownloadItemStatusDownloaded) {
            count++;
        }
    }
    return count;
}

- (void)refreshDownloadingQueue{
    //构建正在下载城市
    [self.downloadingItems removeAllObjects];
    if (self.baseMapInfo.statusForDownload == AL_DownloadItemStatusStopped || self.baseMapInfo.statusForDownload == AL_DownloadItemStatusDownloaded) {
        [self.downloadingItems addObject:self.baseMapInfo];
    }
    for (AL_CityMapInfo *city in self.cities) {
        switch (city.statusForDownload) {
            case AL_DownloadItemStatusWaitingForDownload:
            case AL_DownloadItemStatusDownloading:
            case AL_DownloadItemStatusPaused:
            case AL_DownloadItemStatusStopped:
            case AL_DownloadItemStatusDownloaded: {
                if (city.arrayOfSubCities == nil || city.arrayOfSubCities.count == 0) {
                    [self.downloadingItems addObject:city];
                }
                break;
            }
            case AL_DownloadItemStatusFinished: {
                break;
            }
            default: {
                break;
            }
        }
        for (AL_CityMapInfo *subCity in city.arrayOfSubCities) {
            if ([city.szCityCode isEqualToString:subCity.szCityCode]) {
                continue;
            }
            switch (subCity.statusForDownload) {
                case AL_DownloadItemStatusWaitingForDownload:
                case AL_DownloadItemStatusDownloading:
                case AL_DownloadItemStatusPaused:
                case AL_DownloadItemStatusStopped:
                case AL_DownloadItemStatusDownloaded: {
                    [self.downloadingItems addObject:subCity];
                    break;
                }
                case AL_DownloadItemStatusFinished: {
                    break;
                }
                default: {
                    break;
                }
            }
        }
    }
}

- (void)refreshDownloadedQueue{
    //TODO需要根据已下载内容刷新下载列表
    //构建已下载城市
    [self.downloadedItems removeAllObjects];
    if ([self isBaseMapInfoAvailable]) {
        [self.downloadedItems addObject:self.baseMapInfo];
    }
    for (AL_CityMapInfo *city in self.cities) {
        switch (city.statusForDownload) {
            case AL_DownloadItemStatusWaitingForDownload:
            case AL_DownloadItemStatusDownloading:
            case AL_DownloadItemStatusPaused:
            case AL_DownloadItemStatusStopped:
            case AL_DownloadItemStatusDownloaded: {
                break;
            }
            case AL_DownloadItemStatusFinished: {
                //二级已下载列表由item自身生成
                [self.downloadedItems addObject:city];
                break;
            }
            default: {
                break;
            }
        }
        for (AL_CityMapInfo *subCity in city.arrayOfSubCities) {
            switch (subCity.statusForDownload) {
                case AL_DownloadItemStatusWaitingForDownload:
                case AL_DownloadItemStatusDownloading:
                case AL_DownloadItemStatusPaused:
                case AL_DownloadItemStatusStopped:
                case AL_DownloadItemStatusDownloaded: {
                    break;
                }
                case AL_DownloadItemStatusFinished: {
                    //二级已下载列表由item自身生成
                    [self.downloadedItems addObject:city];
                    break;
                }
                default: {
                    break;
                }
            }
            if ([self.downloadedItems containsObject:city]) {
                break;
            }
        }
    }
}

- (void)requestCities:(void (^)(void))requestCitiesBlock{
    NSString *osVersion = [NSString stringWithFormat:@"%@",[[UIDevice currentDevice] systemVersion]];
    UIScreen *MainScreen = [UIScreen mainScreen];
    CGSize Size = [MainScreen bounds].size;
    CGFloat scale = [MainScreen scale];
    CGFloat screenWidth = Size.width * scale;
    CGFloat screenHeight = Size.height * scale;
    NSString *screenResolution;
    if (screenWidth<screenHeight)
    {
        screenResolution = [NSString stringWithFormat:@"%dx%d_%d",(int)screenWidth,(int)screenHeight,[osVersion intValue]];
    }
    else
    {
        screenResolution = [NSString stringWithFormat:@"%dx%d_%d",(int)screenHeight,(int)screenWidth,[osVersion intValue]];
    }
    
    NSString *szURL = _URL_MAP_DOWNLOAD_CHECK_CITIES_LIST(screenResolution);
    
    NSString *sysCode = Syscode;
    NSString *apkVersion = ResourceVersion;
    NSString *resourceVersion = ResourceVersion;
    
    NSString *key = @"370060C88A374151A175AB60C5FCA7C5";
    NSString *keyWord = [NSString stringWithFormat:@"%@%@%@",sysCode,apkVersion,resourceVersion];
    NSString *md5Words = [NSString stringWithFormat:@"%@@%@",keyWord,key];
    NSString *sign = [[self md5:md5Words] uppercaseString];
    
    NSDictionary *svccountDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"2"               ,@"pid",
                                 apkVersion         ,@"apkv",
                                 sysCode            ,@"syscode",
                                 resourceVersion    ,@"resv",
                                 @[self.mapVersion] ,@"mapvlist",
                                 screenResolution   ,@"resolution",
                                 osVersion          ,@"osv",
                                 @"1"               ,@"needtaiwan",
                                 self.engineVersion ,@"enginev",
                                 sign               ,@"sign",
                                 nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDictionary *postDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"0001"    ,@"activitycode",
                             strDate    ,@"processtime",
                             @"1"       ,@"protversion",
                             @"0"       ,@"language",
                             svccountDic,@"svccont",
                             nil];
    
    NSData *adverEnvelope = nil;
    if (postDic)
    {
        adverEnvelope = [NSJSONSerialization dataWithJSONObject:postDic options:NSJSONWritingPrettyPrinted error:nil];
    }
    NSURL *url = [NSURL URLWithString:[szURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    
    ASIHTTPRequest *asiRequest;
    asiRequest = [ASIHTTPRequest requestWithURL:url];
    [asiRequest addRequestHeader:@"Host" value:[url host]];
    [asiRequest addRequestHeader:@"Content-Type" value:@"text/json; charset=UTF-8"];
    [asiRequest addRequestHeader:@"Content-Length" value:[NSString stringWithFormat:@"%lu", (unsigned long)[adverEnvelope length]]];
    [asiRequest addRequestHeader:@"SOAPAction" value:[NSString stringWithFormat:@"%@",@""]];
    [asiRequest setRequestMethod:nil==adverEnvelope?@"GET":@"POST"];
    [asiRequest appendPostData:adverEnvelope];
    [asiRequest setValidatesSecureCertificate:NO];
    [asiRequest setTimeOutSeconds:60.0];
    [asiRequest setDefaultResponseEncoding:NSUTF8StringEncoding];
    
    __block ASIHTTPRequest *tempRequest = asiRequest;
    
    [asiRequest setCompletionBlock:^{
        NSData *responseObject = [self uncompressZippedData:[tempRequest responseData]];
        [tempRequest clearDelegatesAndCancel];
        
        
        NSError *err = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&err];
        if (err) {
            NSLog(@"%@", err);
            return;
        }
        NSString *resultCode = [[dictionary objectForKey:@"response"] objectForKey:@"rspcode"];
        if (![resultCode isEqualToString:@"0000"]) {
            NSLog(@"Request city data failed!");
            return;
        }
        
        NSDictionary *mapDictionary = [dictionary objectForKey:@"svccont"];
        NSDictionary *baseMapDictionary = mapDictionary;
        self.baseMapInfo = [[AL_BaseResource alloc] initWithDictionary:baseMapDictionary error:&err];
        [self.baseMapInfo addObserver:self];
        [AL_CityMapInfo setBaseUrl:[mapDictionary objectForKey:@"baseurl"]];
        NSMutableArray *cities = [[NSMutableArray alloc] init];
        for (NSDictionary *cityDictionary in [mapDictionary objectForKey:@"provinces"]) {
            AL_CityMapInfo *city = [[AL_CityMapInfo alloc] initWithDictionary:cityDictionary error:&err];
            [cities addObject:city];
        }
        self.cities = cities;
        
        for (AL_CityMapInfo *city in self.cities) {
            [city addObserver:self];
            if (city.arrayOfSubCities && city.arrayOfSubCities.count > 0) {
                for (AL_CityMapInfo *subCity in city.arrayOfSubCities) {
                    [subCity addObserver:self];
                }
            }
        }
        
        [self refreshDownloadingQueue];
        [self refreshDownloadedQueue];
        if (requestCitiesBlock) {
            requestCitiesBlock();
        }
    }];
    [asiRequest setFailedBlock:^{
        [tempRequest clearDelegatesAndCancel];
    }];
    [asiRequest startAsynchronous];
}

- (BOOL)isBaseMapInfoAvailable{
    return self.baseMapInfo && self.baseMapInfo.statusForDownload == AL_DownloadItemStatusFinished;
}

- (void)startAll{
//    [self.downloadingItems makeObjectsPerformSelector:@selector(start)];
}

- (void)resumeAll{
//    [self.downloadingItems makeObjectsPerformSelector:@selector(resume)];
}

- (void)pauseAll{
//    [self.downloadingItems makeObjectsPerformSelector:@selector(pause)];
}

- (void)stopAll{
//    [self.downloadingItems makeObjectsPerformSelector:@selector(stop)];
}

-(void)downloadItemStarted:(id<AL_DownloadItem>)downloadItem{
    //正在下载就不处理了
    if ([self.downloadingItems containsObject:downloadItem]){
        AL_CityMapInfo *city = (AL_CityMapInfo *)downloadItem;
        if (city.statusForDownload == AL_DownloadItemStatusDownloading) {
            return;
        }
    }
    
    //判断是否是基础资源，如果是，则加入下载
    if ([downloadItem isEqual:self.baseMapInfo]) {
        if (![self.downloadingItems containsObject:downloadItem]){
            [self.downloadingItems addObject:downloadItem];
            if (self.delegate && [self.delegate respondsToSelector:@selector(mapDownloadManagerDownloadQueueChanged:)]) {
                [self.delegate mapDownloadManagerDownloadQueueChanged:self];
            }
        }
        if ([self downloadingItemCount] < CONCURRENTMAXLINES) {
            [downloadItem begin];
        }
        return;
    }
    
    if (self.baseMapInfo.statusForDownload != AL_DownloadItemStatusFinished) {
        [self.baseMapInfo start];
    }
    if (![self.downloadingItems containsObject:downloadItem]){
        [self.downloadingItems addObject:downloadItem];
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapDownloadManagerDownloadQueueChanged:)]) {
            [self.delegate mapDownloadManagerDownloadQueueChanged:self];
        }
    }
    if ([self downloadingItemCount] < CONCURRENTMAXLINES) {
        [downloadItem begin];
    }
}

-(void)downloadItemBegan:(id<AL_DownloadItem>)downloadItem{
    if ([self downloadingItemCount] > CONCURRENTMAXLINES) {
        for (AL_CityMapInfo *city in self.downloadingItems) {
            if (city.statusForDownload == AL_DownloadItemStatusDownloading && ![city isEqual:downloadItem]) {
                [city stop];
                [city start];
                return;
            }
        }
    }
}

-(void)downloadItemPaused:(id<AL_DownloadItem>)downloadItem{
    if ([self downloadingItemCount] < CONCURRENTMAXLINES && self.downloadingItems.count > 0) {
        for (AL_CityMapInfo *city in self.downloadingItems) {
            if (city.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
                [city begin];
                return;
            }
        }
    }
}

-(void)downloadItemResumed:(id<AL_DownloadItem>)downloadItem{
    if ([self downloadingItemCount] < CONCURRENTMAXLINES) {
        [downloadItem start];
    }
}

-(void)downloadItemStopped:(id<AL_DownloadItem>)downloadItem{
    if ([self downloadingItemCount] < CONCURRENTMAXLINES && self.downloadingItems.count > 0) {
        for (AL_CityMapInfo *city in self.downloadingItems) {
            if (city.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
                [city begin];
                return;
            }
        }
    }
}

-(void)downloadItemFinished:(id<AL_DownloadItem>)downloadItem{
    if ([self.downloadingItems containsObject:downloadItem]) {
        [self.downloadingItems removeObject:downloadItem];
        [self refreshDownloadedQueue];
        if (self.delegate && [self.delegate respondsToSelector:@selector(mapDownloadManagerDownloadQueueChanged:)]) {
            [self.delegate mapDownloadManagerDownloadQueueChanged:self];
        }
        if ([self downloadingItemCount] < CONCURRENTMAXLINES && self.downloadingItems.count > 0) {
            for (AL_CityMapInfo *city in self.downloadingItems) {
                if (city.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
                    [city begin];
                    return;
                }
            }
        }
    }
}

-(void)downloadItemCancelled:(id<AL_DownloadItem>)downloadItem{
    if ([self.downloadingItems containsObject:downloadItem]) {
        [self.downloadingItems removeObject:downloadItem];
    }
    [self refreshDownloadedQueue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapDownloadManagerDownloadQueueChanged:)]) {
        [self.delegate mapDownloadManagerDownloadQueueChanged:self];
    }
}

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem FailedWithError:(NSError *)error{
    
}

@end
