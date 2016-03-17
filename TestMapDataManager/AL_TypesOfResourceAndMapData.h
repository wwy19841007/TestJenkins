//
//  AL_TypesOfResourceAndMapData.h
//  AlinkApp
//
//  Created by liyuhang on 14-10-8.
//
//

#ifndef AlinkApp_AL_TypesOfResourceAndMapData_h
#define AlinkApp_AL_TypesOfResourceAndMapData_h

//


/*
 * versions
 */
#define VersionMap      @"V27.2.030005.0014"
/************************************/

// 地图数据下载地址配置
// 渠道号 （19004测试使用，Rlease版本41501）
// 编译本地（41502， 19），客户版本（41501 20）
#define Syscode             @"41501"
// 资源号
#define ResourceVersion     @"20"
// 数据下载地址
#define _URL_MAP_DOWNLOAD_CHECK_CITIES_LIST(screenResolution)   \
[NSString stringWithFormat:@"http://ctest.mapabc.com:8086/nis/mapUpdate?os=%@&model=%@&imei=%@&userid=&mapversion=%@&pid=2&resolution=%@&syscode=%@&apkversion=%@",[[UIDevice currentDevice] systemVersion],[[UIDevice currentDevice] model],[[UIDevice currentDevice] identifierForVendor].UUIDString,VersionMap,screenResolution,Syscode,ResourceVersion]

/************************************/


//忽略的更新版本
#define IgnoreUpdateVersion @"IgnoreUpdateVersion"


/************************************/


#endif
