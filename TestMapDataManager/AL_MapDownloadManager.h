//
//  AL_MapDownloadManager.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AL_TypesOfResourceAndMapData.h"
#import "AL_DownloadItem.h"
#import "AL_BaseResource.h"

#define CONCURRENTMAXLINES  1 //允许同时下载的最大条数

@class AL_MapDownloadManager;


@protocol AL_MapDownloadManagerDelegate <NSObject>

@optional
- (void)mapDownloadManagerDownloadQueueChanged:(AL_MapDownloadManager *)mapDownloadManager;

/**
 *  当网络发生变化的时候，程序会先停止所有下载，如果返回结果为真，则继续下载
 *
 *  @return 如果是真，则继续下载
 */
- (BOOL)shouldMapDownloadManagerResumedForNetworkChange:(AL_MapDownloadManager *)mapDownloadManager;

@end

@interface AL_MapDownloadManager : NSObject

@property (nonatomic, assign) id<AL_MapDownloadManagerDelegate> delegate;

@property (nonatomic, strong) NSString *mapVersion;

@property (nonatomic, strong) NSString *engineVersion;

@property (nonatomic, strong) NSArray *cities;

/**
 *  等待下载，正在下载或者下载后解压中的数据
 */
@property (nonatomic, strong, readonly) NSMutableArray *downloadingItems;

@property (nonatomic, strong, readonly) NSMutableArray *downloadedItems;

@property (nonatomic, strong) AL_BaseResource *baseMapInfo;

+ (instancetype)shareInstance;

- (void)requestCities:(void (^)(void))requestCitiesBlock;

/**
 *  判断基础数据是否存在
 */
- (BOOL)isBaseMapInfoAvailable;

- (void)startAll;

/**
 *  resume与start不同之处在于，不启动stop的记录
 */
- (void)resumeAll;

- (void)pauseAll;

- (void)stopAll;

@end
