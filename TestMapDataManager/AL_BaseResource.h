//
//  AL_BaseResource.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 7/28/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "AL_CityMapInfo.h"

@interface AL_BaseResource : AL_CityMapInfo

-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err;

@property (nonatomic, assign) NSInteger                       nAddSize;///< 数据大小

@property (nonatomic, assign) NSInteger                       nAddAllSize;///< 解压大小

@property (nonatomic, strong) NSString*                       szAddUrl;///< 数据下载地址

@property (nonatomic, strong) NSString*                       mapVersion;///< 地图基础数据版本,用于判断更新

@property (nonatomic, strong) NSString*                       mapNewVersion;///< 新地图基础数据版本,用于判断更新

@end
