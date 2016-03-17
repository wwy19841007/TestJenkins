//
//  AL_DownloadItem.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/30/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol AL_DownloadItem;

/**
 *  下载状态
 */
typedef NS_ENUM(NSInteger, AL_DownloadItemStatus)
{
    AL_DownloadItemStatusNone = 0,                  ///< 还没下载
    AL_DownloadItemStatusWaitingForDownload = 1,    ///< 等待下载
    AL_DownloadItemStatusDownloading = 2,           ///< 正在下载
    AL_DownloadItemStatusPaused = 3,                ///< 暂停下载
    AL_DownloadItemStatusStopped = 4,               ///< 停止下载
    AL_DownloadItemStatusDownloaded = 5,            ///< 数据下载完成，需要解压
    AL_DownloadItemStatusFinished = 6,              ///< 已经下载完成
};

@protocol AL_DownloadItemDelegate <NSObject>

@optional
-(void)downloadItem:(id<AL_DownloadItem>)downloadItem downloadedBytes:(NSInteger)downloadedBytes totalBytes:(NSInteger)totalBytes;

-(void)downloadItemStatusChanged:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem FailedWithError:(NSError *)error;

-(void)downloadItemStarted:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemBegan:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemPaused:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemResumed:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemStopped:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemFinished:(id<AL_DownloadItem>)downloadItem;

-(void)downloadItemCancelled:(id<AL_DownloadItem>)downloadItem;

@end

@protocol AL_DownloadItem <NSObject>

/**
 *  下载状态
 */
@property (nonatomic, assign) AL_DownloadItemStatus statusForDownload;

-(void)start;

-(void)begin;

/**
 *  暂停可能是由网络状态变更导致的停止，与stop类似，但是状态标志不一样
 */
-(void)pause;

-(void)resume;

-(void)stop;

-(void)cancel;

@end
