//
//  DownloadedItemTableViewCell.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/23/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "DownloadedItemTableViewCell.h"
#import "AL_CityMapInfo.h"

#define AppWidth 320
#define AppHeight 480

@interface DownloadedItemTableViewCell()<AL_DownloadItemDelegate>

@end

@implementation DownloadedItemTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [self.deleteBtn setFrame:CGRectMake(AppWidth - 68, 10, 64, 24)];
        [self.deleteBtn addTarget:self action:@selector(deleteBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.deleteBtn];
    }
    return self;
}

- (void)setCity:(AL_CityMapInfo *)city{
    _city = city;
    
    self.textLabel.text = _city.szName;
    
    if (_city.arrayOfSubCities && _city.arrayOfSubCities.count > 0) {
        [self.deleteBtn setHidden:YES];
    }else{
        [self.deleteBtn setHidden:NO];
    }
}

- (IBAction)deleteBtnPressed:(id)sender{
    [self.city cancel];
}

@end
