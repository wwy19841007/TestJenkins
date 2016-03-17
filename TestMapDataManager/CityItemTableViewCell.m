//
//  DownloadItemTableViewCell.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/22/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "CityItemTableViewCell.h"
#import "AL_CityMapInfo.h"

#define AppWidth 320
#define AppHeight 480

@interface CityItemTableViewCell()<AL_DownloadItemDelegate>

@end

@implementation CityItemTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.downloadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
        [self.downloadBtn setFrame:CGRectMake(AppWidth - 68, 10, 64, 24)];
        [self.downloadBtn addTarget:self action:@selector(downloadBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.downloadBtn];
    }
    return self;
}

- (void)setCity:(AL_CityMapInfo *)city{
    if (_city) {
        [_city removeObserver:self];
    }
    _city = city;
    [_city addObserver:self];
    
    switch (self.city.statusForDownload) {
        case AL_DownloadItemStatusNone: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusWaitingForDownload: {
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusDownloading: {
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusPaused: {
            [self.downloadBtn setTitle:@"恢复" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusStopped: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusDownloaded: {
            [self.downloadBtn setTitle:@"解压" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusFinished: {
            [self.downloadBtn setTitle:@"删除" forState:UIControlStateNormal];
            break;
        }
        default: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
    }
    if (_city.isHasUpdateInfo) {
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    }
    
    self.textLabel.text = [NSString stringWithFormat:@"%@ %@", _city.szName, _city.status];
    self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fM (%.1f%%)", _city.nSize / 1024.0f / 1024.0f, (double)_city.nCountOfHasDownloaded * 100 / (double)_city.nSize];
    
    if (_city.arrayOfSubCities && _city.arrayOfSubCities.count > 0) {
        [self.downloadBtn setHidden:YES];
    }else{
        [self.downloadBtn setHidden:NO];
    }
}

- (IBAction)downloadBtnPressed:(id)sender{
    if ([self.downloadBtn.titleLabel.text isEqualToString:@"下载"]) {
        [self.city start];
    } else if ([self.downloadBtn.titleLabel.text isEqualToString:@"暂停"]){
        [self.city stop];
    } else if ([self.downloadBtn.titleLabel.text isEqualToString:@"恢复"]){
        [self.city resume];
    } else if ([self.downloadBtn.titleLabel.text isEqualToString:@"解压"]){
        [self.city start];
    } else if ([self.downloadBtn.titleLabel.text isEqualToString:@"删除"]){
        [self.city cancel];
    }
}

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem downloadedBytes:(NSInteger)downloadedBytes totalBytes:(NSInteger)totalBytes{
    self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fM (%.1f%%)", self.city.nSize / 1024.0f / 1024.0f, (double)downloadedBytes * 100 / (double)totalBytes];
}

-(void)downloadItemStatusChanged:(id<AL_DownloadItem>)downloadItem{
    self.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.city.szName, self.city.status];
    switch (self.city.statusForDownload) {
        case AL_DownloadItemStatusNone: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusWaitingForDownload: {
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusDownloading: {
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusPaused: {
            [self.downloadBtn setTitle:@"恢复" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusStopped: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusDownloaded: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
        case AL_DownloadItemStatusFinished: {
            [self.downloadBtn setTitle:@"删除" forState:UIControlStateNormal];
            break;
        }
        default: {
            [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
            break;
        }
    }
}

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem FailedWithError:(NSError *)error{
    
}

- (void)dealloc{
    [_city removeObserver:self];
}

@end
