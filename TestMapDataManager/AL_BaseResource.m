//
//  AL_BaseResource.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/28/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "AL_BaseResource.h"
#import "tmpDefines.h"
#import "ZipArchive.h"

#define BACKGROUNDTASKIDENTIFIER 10241024
#define CITYCODEDICT @"cityCode"
#define STATUSDICT @"status"
#define VERSIONDICT @"version"
#define MAPVERSIONDICT @"mapversion"

@interface AL_BaseResource()

@end

@implementation AL_BaseResource
+(JSONKeyMapper*)keyMapper
{
    return [[JSONKeyMapper alloc] initWithDictionary:@{
                                                       @"adcode": @"szCityCode",
                                                       @"all_size": @"nSize",
                                                       @"all_unzipsize": @"nAllSize",
                                                       @"all_url": @"szUrl",
                                                       @"add_size": @"nAddSize",
                                                       @"add_unzipsize": @"nAddAllSize",
                                                       @"add_url": @"szAddUrl",
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
        self.observers = (NSMutableArray<AL_DownloadItemDelegate> *)[[NSMutableArray alloc] init];
        self.isDownloaded = NO;
    }
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err{
    self = [super initWithDictionary:[dict objectForKey:@"baseres"] error:err];
    if (self) {
        //基础资源
        NSString *szZipName = [self.szUrl lastPathComponent];
        
        self.szCityCode = @"0";
        self.szPathOnDevice =  _M_Path_Doc_Gps_;
        self.szpathOfTemp =  [NSString stringWithFormat:@"%@/%@.temp", _M_MapDataManager_TempPath, szZipName];
        self.szPathofDownload = [NSString stringWithFormat:@"%@/%@", document_path, szZipName];
        self.mapNewVersion = [dict objectForKey:@"mapv"];
        
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
        
        //还原历史版本和之前的下载状态，可能出现之前下载的版本和新更新的版本不一致的情况，对于之前已经加入等待序列但是还未开始下载的任务，保存状态
        NSString *cityUserDefaultCode = [NSString stringWithFormat:@"%@UDDETAIL", self.szCityCode];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]) {
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode];
            self.dataVersion = [dict objectForKey:VERSIONDICT];
            self.mapVersion = [dict objectForKey:MAPVERSIONDICT];
            self.statusForDownload = [[dict objectForKey:STATUSDICT] integerValue];
            if (self.statusForDownload == AL_DownloadItemStatusWaitingForDownload ||
                self.statusForDownload == AL_DownloadItemStatusDownloading ||
                self.statusForDownload == AL_DownloadItemStatusPaused ||
                self.statusForDownload == AL_DownloadItemStatusStopped) {
                self.statusForDownload = AL_DownloadItemStatusStopped;
            }
        }else{
            self.dataVersion = self.dataNewVersion;
            self.mapVersion = self.mapNewVersion;
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
                    self.mapVersion = self.mapNewVersion;
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

-(BOOL)compareForUpdate{
    if (self.dataVersion == nil || self.dataVersion.length == 0 || self.dataNewVersion == nil || self.dataNewVersion.length == 0) {
        return NO;
    }
    
    NSArray *oldVersionArray = [self.mapVersion componentsSeparatedByString:@"."];
    NSInteger oldBigVersion = [[oldVersionArray firstObject] integerValue];
    NSInteger oldSmallVersion = [[oldVersionArray lastObject] integerValue];
    NSArray *newVersionArray = [self.mapNewVersion componentsSeparatedByString:@"."];
    NSInteger newBigVersion = [[newVersionArray firstObject] integerValue];
    NSInteger newSmallVersion = [[newVersionArray lastObject] integerValue];
    if ((oldBigVersion < newBigVersion) || (oldBigVersion == newBigVersion && oldSmallVersion < newSmallVersion)) {
        self.updateType = 1;
        return YES;
    }
    
    if ([self.dataVersion integerValue] < [self.dataNewVersion integerValue]) {
        self.updateType = 0;
        return YES;
    }
    return NO;
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
        [cityDictionary setObject:self.dataVersion forKey:VERSIONDICT];
        [cityDictionary setObject:self.mapVersion forKey:MAPVERSIONDICT];
        [[NSUserDefaults standardUserDefaults] setObject:cityDictionary forKey:cityUserDefaultCode];
    }else{
        NSMutableDictionary *cityDictionary = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:cityUserDefaultCode]];
        [cityDictionary setObject:[NSString stringWithFormat:@"%ld", self.statusForDownload] forKey:STATUSDICT];
        [[NSUserDefaults standardUserDefaults] setObject:cityDictionary forKey:cityUserDefaultCode];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
