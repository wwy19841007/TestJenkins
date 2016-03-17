//
//  AL_CityMapInfo.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  strongright (c) 2015 autonavi. All rights reserved.
//

#import "BaseObject.h"
#import "AL_DownloadItem.h"

@protocol AL_CityMapInfo <NSObject>

@end

@interface AL_CityMapInfo : BaseObject<AL_DownloadItem>

@property (nonatomic, strong) NSMutableArray<AL_DownloadItemDelegate> *observers;

- (void)addObserver:(id<AL_DownloadItemDelegate>)observer;
- (void)removeObserver:(id<AL_DownloadItemDelegate>)observer;

-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err;

@property (nonatomic, strong) NSString*                       szCityCode;///< 城市编码，基础资源的编码为0

@property (nonatomic, strong) NSString*                       szEnName;///< 英文名

@property (nonatomic, strong) NSString*                       szName;///< 中文名

@property (nonatomic, strong) NSString*                       szTwName;///< 繁体名

@property (nonatomic, strong) NSString*                       dataVersion;///< 数据版本,用于判断更新

@property (nonatomic, strong) NSString*                       dataNewVersion;///< 新数据版本,用于判断更新

@property (nonatomic, assign) NSInteger                       updateType;///< 0表示全量更新，1表示增量更新

@property (nonatomic, assign) NSInteger                       nSize;///< 数据大小

@property (nonatomic, assign) NSInteger                       nAllSize;///< 解压大小

@property (nonatomic, strong) NSString*                       szUrl;///< 数据下载地址

@property (nonatomic, assign) AL_CityMapInfo*                 upperCity;///< 上级城市

@property (nonatomic, strong) NSMutableArray<AL_CityMapInfo>* arrayOfSubCities;///< 下级城市数组

@property (nonatomic, assign) BOOL                            isHasUpdateInfo;///< 是否有更新，通过dataVersion判断，有更新的数据只能是已下载的数据。

@property (nonatomic, assign) AL_DownloadItemStatus           statusForDownload;///< 下载状态

@property (nonatomic, assign) BOOL                            isDownloaded;///< 下载状态

@property (nonatomic, assign) BOOL                            isProvince;///< 有下级城市的时候是省份

@property (nonatomic, strong) NSString*                       szPathOnDevice;///< 在手机上的目录

@property (nonatomic, strong) NSString*                       szpathOfTemp;///< 下载的临时目录

@property (nonatomic, strong) NSString*                       szPathofDownload;///< 下载完成后存放的目录

@property (nonatomic, assign) BOOL                            isError;///< 是否有错误

@property (nonatomic, assign) NSInteger                       nCountOfHasDownloaded;///< 已下载的数据大小

+(void)setBaseUrl:(NSString *)baseUrl;

-(NSArray *)downloadedCities;

-(void)start;

-(void)begin;

/**
 *  暂停可能是由网络状态变更导致的停止，与stop类似，但是状态标志不一样
 */
-(void)pause;

-(void)resume;

-(void)stop;

-(void)cancel;

-(NSString *)status;

@end
