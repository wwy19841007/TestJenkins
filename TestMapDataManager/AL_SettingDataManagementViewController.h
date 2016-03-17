//
//  AL_SettingDataManagementViewController.h
//  AlinkApp
//
//  Created by newman on 14-7-17.
//
//

#import <UIKit/UIKit.h>
#import "AlinkViewController.h"

typedef NS_ENUM(NSUInteger, AL_SettingDataManagementViewControllerEnum)
{
    SDMVC_AllBtnTag = 100,
    SDMVC_DownloadedBtnTag,
    SDMVC_DownloadingBtnTag,
    SDMVC_CollectEditBtnTag,
    SDMVC_BottomViewTag,
    SDMVC_EnterSearchViewTag,
    SDMVC_SearchBtnTag,
    SDMVC_DownedDeleteBtnTag,
    SDMVC_DowningDeleteBtnTag,
};

typedef NS_ENUM(NSUInteger, BottomViewEnum)
{
    AllBottomView = 10,
    DownloadedBottomView,
    DownloadingBottomView,
};

#define TextBlueColor       [UIColor colorWithRed:73.0/255 green:169.0/255 blue:249.0/255 alpha:1.0f]
#define MenuTextColor       [UIColor colorWithRed:56.0/255 green:173.0/255 blue:217.0/255 alpha:1.0f]
#define MenuSelectTextColor [UIColor colorWithRed:56.0/255 green:173.0/255 blue:217.0/255 alpha:1.0f]


@interface AL_SettingDataManagementViewController : AlinkViewController

@property (nonatomic, copy) NSString *str;

@property (nonatomic, copy) NSString *adminToDownload;

@property (nonatomic, assign) BOOL isNeedToDownloadBaseData;

@end









