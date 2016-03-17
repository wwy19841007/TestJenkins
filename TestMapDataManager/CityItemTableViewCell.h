//
//  DownloadItemTableViewCell.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/22/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AL_CityMapInfo;

@interface CityItemTableViewCell : UITableViewCell

@property (nonatomic, strong) AL_CityMapInfo *city;

@property (nonatomic, strong) UIButton *downloadBtn;

@end
