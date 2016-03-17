//
//  tmpDefines.h
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#ifndef TestMapDataManager_tmpDefines_h
#define TestMapDataManager_tmpDefines_h

// 程序目录之下
#define _M_BasePath_NaviData            @"data"
#define _M_BasePath_NaviResource        @"navi"
#define _M_BasePath_NaviDownload        @"data/download"
#define _M_BasePath_NaviTTS             @"navi/TTS"
#define _M_BasePath_NaviConfig          [YYNaviFileOperate getBaseResourcePath]


/*
 @ 根据设备不同，设置不同的程序运行路径(/Documents/navi/640*960)
 */
#define _M_Path_NaviConfig                 [NSString stringWithFormat:@"%@/Documents/%@/%@", NSHomeDirectory(),_M_BasePath_NaviResource, _M_BasePath_NaviConfig]
/*
 @ 数据路径(/Documents/data)
 */
#define _M_Path_Doc_Gps_                    [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), _M_BasePath_NaviData]

#define _M_Path_MainBundle_Gps_             [NSString stringWithFormat:@"%@/%@",_M_Path_Resource_Download_Uncompress_, _M_BasePath_NaviData]

#define _M_Path_Doc_Data_Chn_                [NSString stringWithFormat:@"%@/Documents/%@/%@", NSHomeDirectory(), _M_BasePath_NaviData,@"chn"]

/*
 @ Download(/Documents/navi/download)
 */
#define _M_Path_Doc_Download_               [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), _M_BasePath_NaviDownload]

//#define _M_Path_MainBundle_Download_      [[[GDGlobalFunction GDBundleForResource] bundlePath] stringByAppendingString:@"/Download"]

#define _M_Path_MainBundle_Download_        [NSString stringWithFormat:@"%@/%@",_M_Path_Resource_Download_Uncompress_, _M_BasePath_NaviDownload]

/*
 @ 资源路径(/Documents/navi)
 */
#define _M_Path_Doc_Res                     [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(),_M_BasePath_NaviResource]

//#define _M_Path_MainBundle_Res            ([NSString stringWithFormat:@"%@/%@", [[GDGlobalFunction GDBundleForResource] bundlePath], _M_BasePath_NaviConfig])

#define _M_Path_MainBundle_Res              [NSString stringWithFormat:@"%@/%@",_M_Path_Resource_Download_Uncompress_,_M_BasePath_NaviResource]

// 通用资源路径
//#define _M_Path_Common_Res                  [NSString stringWithFormat:@"%@/BaseResource/navi/GNaviRes",_M_Path_Resource_Download_Uncompress_])

//
#define _M_Path_MultiCityData_          [NSHomeDirectory() stringByAppendingString:@"/Documents"]



#define oldPreferenceFilePath           [NSHomeDirectory() stringByAppendingString:@"/Documents/NaviSetting.plist"]
#define preferenceFilePath              [NSHomeDirectory() stringByAppendingString:@"/Documents/NaviSettingModel.plist"]

#define document_path                   [NSHomeDirectory() stringByAppendingString:@"/Documents"]
#define sn_path                         [[NSHomeDirectory() stringByAppendingString:@"/Documents/GPS/sn.dat"] UTF8String]
#define mapVersion_path                 [[NSHomeDirectory() stringByAppendingString:@"/Documents/GPS/map_v.dat"] UTF8String]
#define guideRoute_path                 [NSHomeDirectory() stringByAppendingString:@"/Documents/path/"]
#define route_path                      [NSHomeDirectory() stringByAppendingString:@"/Documents/path.dat"]
#define account_path                    [NSHomeDirectory() stringByAppendingString:@"/Documents/accountInfo.plist"]

#define GNaviData_Directory             [NSHomeDirectory() stringByAppendingString:@"/Documents/GNaviData"]
//#define GpsRecordDirectory             [NSHomeDirectory() stringByAppendingString:@"/Documents/GNaviData/gps"]
#define CommonPOI_Directory             [NSHomeDirectory() stringByAppendingString:@"/Documents/GNaviData/address/commonPOI.plist"]
// 网络下载临时文件夹
#define _M_MapDataManager_TempPath      [NSHomeDirectory() stringByAppendingString:@"/Documents/NaviTemp"]
// GPS回放需要的文件
#define _M_PATH_GPS_REPLAY_             [NSHomeDirectory() stringByAppendingString:@"/Documents/gps.loc"]
// ETA语音播报
#define _M_Path_ETA_BROADCAST_WAVE_     [NSHomeDirectory() stringByAppendingString:@"/Documents/NaviTemp/eatwav.wav"]
// AdAreaList
#define _M_Path_LocalAreaInfos_             [NSString stringWithFormat:@"%@/Documents/navi/localAreaInfos.plist", NSHomeDirectory()]
// ETA 设置
#define PathOfDestAlertInfo             [NSHomeDirectory() stringByAppendingString:@"/Documents/NaviTemp/DestAlertInfo.plist"]

/*
 * 关于资源文件
 */
#define _M_Path_Resource_Download_                  ([NSString stringWithFormat:@"%@/resource.gdzip", _M_MapDataManager_TempPath])
#define _M_Path_Resource_Download_Temp_             ([NSString stringWithFormat:@"%@/resource.gdzipTemp", _M_MapDataManager_TempPath])
#define _M_Path_Resource_Download_Uncompress_       ([NSString stringWithFormat:@"%@/resourceDic", _M_MapDataManager_TempPath])

#define _M_Path_Has_UnpressedResource               ([NSString stringWithFormat:@"%@/resourceDic", _M_MapDataManager_TempPath])















#endif
