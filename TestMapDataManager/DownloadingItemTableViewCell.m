//
//  DownloadItemTableViewCell.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/23/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "DownloadingItemTableViewCell.h"
#import "AL_CityMapInfo.h"

#define AppWidth 320
#define AppHeight 480

@interface DownloadingItemTableViewCell()<AL_DownloadItemDelegate>

@end

@implementation DownloadingItemTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.downloadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.downloadBtn setTitle:@"开始" forState:UIControlStateNormal];
        [self.downloadBtn setFrame:CGRectMake(AppWidth - 172, 10, 48, 24)];
        [self.downloadBtn addTarget:self action:@selector(downloadBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.downloadBtn];
        
        self.stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.stopBtn setTitle:@"停止" forState:UIControlStateNormal];
        [self.stopBtn setFrame:CGRectMake(AppWidth - 120, 10, 48, 24)];
        [self.stopBtn addTarget:self action:@selector(stopBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.stopBtn];
        
        self.deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [self.deleteBtn setFrame:CGRectMake(AppWidth - 68, 10, 64, 24)];
        [self.deleteBtn addTarget:self action:@selector(deleteBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteBtn];
    }
    return self;
}

- (void)setCity:(AL_CityMapInfo *)city{
    if (_city) {
        [_city removeObserver:self];
    }
    _city = city;
    [_city addObserver:self];
    
    [self refreshStatus];
    self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fM (%.1f%%)", _city.nSize / 1024.0f / 1024.0f, (double)_city.nCountOfHasDownloaded * 100 / (double)_city.nSize];
}

- (IBAction)downloadBtnPressed:(id)sender{
    if (self.city.statusForDownload == AL_DownloadItemStatusWaitingForDownload) {
        [self.city begin];
    }else{
        [self.city start];
    }
}

- (IBAction)stopBtnPressed:(id)sender{
    [self.city stop];
}

- (IBAction)deleteBtnPressed:(id)sender{
    [self.city cancel];
}

- (void)refreshStatus{
    self.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.city.szName, self.city.status];
    switch (self.city.statusForDownload) {
        case AL_DownloadItemStatusNone: {
            break;
        }
        case AL_DownloadItemStatusWaitingForDownload: {
            [self.downloadBtn setEnabled:YES];
            [self.stopBtn setEnabled:YES];
            break;
        }
        case AL_DownloadItemStatusDownloading: {
            [self.downloadBtn setEnabled:NO];
            [self.stopBtn setEnabled:YES];
            break;
        }
        case AL_DownloadItemStatusPaused: {
            [self.downloadBtn setEnabled:YES];
            [self.stopBtn setEnabled:NO];
            break;
        }
        case AL_DownloadItemStatusStopped: {
            [self.downloadBtn setEnabled:YES];
            [self.stopBtn setEnabled:NO];
            break;
        }
        case AL_DownloadItemStatusDownloaded: {
            [self.downloadBtn setEnabled:NO];
            [self.stopBtn setEnabled:NO];
            break;
        }
        case AL_DownloadItemStatusFinished: {
//            [self.textLabel setText:@""];
//            [self.detailTextLabel setText:@""];
//            [self.downloadBtn setTitle:@"" forState:UIControlStateNormal];
//            [self.deleteBtn setTitle:@"" forState:UIControlStateNormal];
//            [self.stopBtn setTitle:@"" forState:UIControlStateNormal];
            break;
        }
        default: {
            [self.downloadBtn setEnabled:YES];
            [self.stopBtn setEnabled:YES];
            break;
        }
    }
}

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem downloadedBytes:(NSInteger)downloadedBytes totalBytes:(NSInteger)totalBytes{
    self.detailTextLabel.text = [NSString stringWithFormat:@"%.1fM (%.1f%%)", self.city.nSize / 1024.0f / 1024.0f, (double)downloadedBytes * 100 / (double)totalBytes];
}

-(void)downloadItemStatusChanged:(id<AL_DownloadItem>)downloadItem{
    [self refreshStatus];
}

-(void)downloadItem:(id<AL_DownloadItem>)downloadItem FailedWithError:(NSError *)error{
    
}

- (void)dealloc{
    if ([_city.observers containsObject:self]) {
        [_city removeObserver:self];
    }
}

@end
