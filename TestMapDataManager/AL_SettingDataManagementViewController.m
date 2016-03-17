//
//  AL_SettingDataManagementViewController.m
//  AlinkApp
//
//  Created by newman on 14-7-17.
//
//

#import <CoreText/CoreText.h>
#import "AL_SettingDataManagementViewController.h"
#import "AlinkTableView.h"
#import "AL_SettingDataManagementViewCell.h"
#import "Alink_BottomView.h"
#import "AL_SettingDataSeachViewController.h"
#import "AL_MapDownloadManager.h"
#import "AL_SettingDataManAllCell.h"
#import "Alink_NavBarsView.h"
#import "AL_SettingDefine.h"




@interface AL_SettingDataManagementViewController()<UITableViewDataSource,UITableViewDelegate, MapDownloadDelegate, UITextFieldDelegate>

@property (nonatomic, retain) UITextField *textFieldProvince;
@property (nonatomic, retain) Alink_BottomView *bottomView;
@property (nonatomic, retain) Alink_BottomView *allBottomView;
@property (nonatomic, retain) Alink_BottomView *downloadedBottomView;
@property (nonatomic, retain) Alink_BottomView *downloadingBottomView;
@property (nonatomic, retain) UIScrollView *mainScrollView;
@property (nonatomic, retain) UIButton *allBtn;
@property (nonatomic, retain) UIButton *downloadedBtn;
@property (nonatomic, retain) UIButton *downloadingBtn;
@property (nonatomic, retain) UILabel  *btnLineLabel;
@property (nonatomic, retain) AlinkTableView *allTableView;
@property (nonatomic, retain) AlinkTableView *downloadedTableView;
@property (nonatomic, retain) AlinkTableView *downloadingTableView;
@property (nonatomic, retain) NSMutableArray *allTableShowArray;
@property (nonatomic, retain) NSMutableArray *downloadedTableShowArray;
@property (nonatomic, retain) NSMutableArray *downloadedCityInfoArray;
@property (nonatomic, retain) NSMutableArray *shouldDownloadCityArray;
@property (nonatomic, assign) int selectedBtnIndex;
@property (nonatomic, assign) BOOL isDownloadedCanDelete;
@property (nonatomic, assign) BOOL isDownloadingCanDelete;
@property (nonatomic, assign) BOOL hasUpdateData;


//竖屏
@property (nonatomic, retain) UIView              *landscapeTapView;
@property (nonatomic, retain) Alink_NavBarsView   *portraitNavBarsView;
@property (nonatomic, assign) float               screenWith, screenHeith;
@property (nonatomic, retain) UIView              *titleView;
@property (nonatomic, retain) UIButton            *enterSearchBtn;
@property (nonatomic, retain) UIButton            *seachBtn;
@property (nonatomic, retain) UIButton            *btnDownedDelect;
@property (nonatomic, retain) UIButton            *btnDowningDelect;

@end


@implementation AL_SettingDataManagementViewController


#pragma mark - 初始化
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationAction:) name:ClearAllDataNotification object:nil];
    
    [self initDate];
    
    [self initControl];
    
    [self getDataFromNet];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _textFieldProvince.text = @"";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationAction:) name:NetWorkChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_textFieldProvince resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NetWorkChangeNotification object:nil];
}

#pragma mark
#pragma mark - 添加视图
- (void)initDate
{
    [AL_MapDownloadManager shareInstance].delegateOfMapDownload = self;
    
    _allTableShowArray = [[NSMutableArray alloc] init];
    _downloadedTableShowArray = [[NSMutableArray alloc] init];
    _downloadedCityInfoArray = [[NSMutableArray alloc] init];
    _shouldDownloadCityArray = [[NSMutableArray alloc] init];
    _isDownloadedCanDelete = NO;
    _isDownloadingCanDelete = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterDownloadingView) name:@"DataManagerEnterDownloadingView" object:nil];
}

- (void)initControl
{
    self.view.backgroundColor = [UIColor colorWithRed:17.0/255 green:23.0/255 blue:41.0/255 alpha:1.0f];
    
    _mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, LandscapeTitleHeight+42, APPHEIGHT*3, 212)];
    [self.view addSubview:_mainScrollView];
    
    //全部的菜单
    self.allBottomView = [self addBottomView:nil withType:AllBottomView withTemp:self];
    
    //顶部菜单栏
    [self addTitleView];
    
    //竖屏导航条
    [self initPortraitControl];
    
    if (NetWorkType!=0)
    {
        [self addTableView];
    }
}

- (void)getDataFromNet
{
    if (NetWorkType==0)
    {
        AT_AlertView *alertView = [AT_AlertView showAlertWithMessage:LOCALIZESTR(@"AL_Setting_NetworkAnomaly", @"AL_SettingStr")];
        [alertView dismissAfterDelay:3.0f];
        [alertView release];
        return;
    }
    
    __block AL_SettingDataManagementViewController *temp = self;
    [AT_AlertView showAlertWithRefreshViewMessage:LOCALIZESTR(@"AL_Setting_LoadData", @"AL_SettingStr")];
    [[AL_MapDownloadManager shareInstance] getCitiesListFromServer:^(NSArray *arrayOfCitiesList) {
        [AT_AlertView hideRefreshAlertWithAnimated:YES];
        if (arrayOfCitiesList)
        {
            for (NSInteger i=0;i<arrayOfCitiesList.count; i++)
            {
                [temp.allTableShowArray addObject:[NSNumber numberWithBool:NO]];
            }
            
            //获取下载省份列表
            [temp getDownloadedProvince:temp];
            
            [temp.allTableView.tableView reloadData];
            [temp.downloadedTableView.tableView reloadData];
            [temp.downloadingTableView.tableView reloadData];
            [temp checkToAutoDownload:temp];
        }
        else
        {
            AT_AlertView *alertView = [AT_AlertView showAlertWithMessage:LOCALIZESTR(@"AL_Setting_LoadDataFailure", @"AL_SettingStr")];
            [alertView dismissAfterDelay:3.0f];
            [alertView release];
        }
    } isRefresh:NO];
}

- (void)addTitleView
{
    _screenWith = _M_DeviceOrientation == 0 ? APPHEIGHT_VISION : APPWIDTH_VISION;
    _screenHeith = _M_DeviceOrientation == 0 ? APPWIDTH_VISION :APPHEIGHT_VISION;
    
    /* 顶部导航条 */
    _landscapeTapView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _screenWith, LandscapeTitleHeight)];
    _landscapeTapView.backgroundColor = [UIColor colorWithRed:25.0/255 green:45.0/255 blue:73.0/255 alpha:1.0];
    UILabel *lbTitle = [ControlCreat createLabelWithText:LOCALIZESTR(@"AL_Setting_DataManage", @"AL_SettingStr") fontSize:kSize3 textAlignment:NSTextAlignmentLeft];
    lbTitle.frame = CGRectMake(15, 0, 110, LandscapeTitleHeight);
    [_landscapeTapView addSubview:lbTitle];
    
    UILabel *line = [[UILabel alloc] initWithFrame:CGRectMake(0, lbTitle.frame.size.height, APPHEIGHT, 2)];
    line.backgroundColor = [UIColor colorWithRed:78.0/255 green:85.0/255 blue:101.0/255 alpha:1.0];
    [_landscapeTapView addSubview:line];
    [line release];
    
    [self.view addSubview:_landscapeTapView];
    [_landscapeTapView release];
    
    _selectedBtnIndex = SDMVC_AllBtnTag;
    
    _titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 23, APPHEIGHT, 42)];
    _titleView.backgroundColor = [UIColor colorWithRed:25.0/255 green:45.0/255 blue:73.0/255 alpha:1.0f];
    [self.view addSubview:_titleView];
    
    _allBtn = [self createMenuButtonWithTitle:LOCALIZESTR(@"AL_Setting_All", @"AL_SettingStr") normalImage:nil heightedImage:@"" tag:SDMVC_AllBtnTag];
    [_allBtn setFrame:CGRectMake(0, 0, _titleView.frame.size.width/3, _titleView.frame.size.height)];
    [_titleView addSubview:_allBtn];
    
    _downloadedBtn = [self createMenuButtonWithTitle:LOCALIZESTR(@"AL_Setting_HaveDowned", @"AL_SettingStr") normalImage:nil heightedImage:@"" tag:SDMVC_DownloadedBtnTag];
    [_downloadedBtn setFrame:CGRectMake(APPHEIGHT/3, _allBtn.frame.origin.y, APPHEIGHT/3, bottomViewWidth-2)];
    [_titleView addSubview:_downloadedBtn];
    
    _downloadingBtn = [self createMenuButtonWithTitle:LOCALIZESTR(@"AL_Setting_Downing", @"AL_SettingStr") normalImage:nil heightedImage:@"" tag:SDMVC_DownloadingBtnTag];
    [_downloadingBtn setFrame:CGRectMake(2*APPHEIGHT/3, _allBtn.frame.origin.y, APPHEIGHT/3, bottomViewWidth-2)];
    [_titleView addSubview:_downloadingBtn];
    
    _btnLineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _allBtn.frame.size.height-2, _allBtn.frame.size.width, 2)];
    _btnLineLabel.backgroundColor = TextBlueColor;
    [_titleView addSubview:_btnLineLabel];
    [_titleView release];
}

- (UIButton *)createMenuButtonWithTitle:(NSString *)titleT normalImage:(NSString *)normalImage heightedImage:(NSString *)heightedImage tag:(NSInteger)tagN
{
    UIButton *btnMenu = [self createButtonWithTitle:titleT normalImage:normalImage heightedImage:heightedImage tag:tagN];
    [btnMenu setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnMenu setTitleColor:TextBlueColor forState:UIControlStateHighlighted];
    btnMenu.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    
    return btnMenu;
}

/* 初始化竖屏控件 */
- (void)initPortraitControl
{
    _screenWith = _M_DeviceOrientation == 0 ? APPWIDTH_VISION : APPHEIGHT_VISION;
    _screenHeith = _M_DeviceOrientation == 0 ? APPHEIGHT_VISION:APPWIDTH_VISION;
    [self addNavBarsView];
}

/* 竖屏导航条 */
- (void)addNavBarsView
{
    NSArray *leftRightBtnArray = @[@"icn_NaviBack.png", @"btn_菜单栏-回车位.png"];
    //    NSArray *midArray = @[@"icn_顶栏_垃圾桶_B.png"];
    _portraitNavBarsView = [[Alink_NavBarsView alloc] initTitle:LOCALIZESTR(@"AL_Setting_DataManage", @"AL_SettingStr") withFrame:CGRectMake(0, APP_STATEBAR_H, _screenWith, NAVICTR_V) backGroundImage:@"BG_NaviBar_bg.png" leftAndRightBtnArray:leftRightBtnArray middleBtnArray:nil leftAndRightBtnWidth:70];
    __block AL_SettingDataManagementViewController *temp = self;
    [_portraitNavBarsView setLeftBtnBlock:^(){
        [temp popWithTemp:temp];
    } rightBtnBlock:^(){
        [temp popToRootWithTemp:temp];
    } midBtnBlock:^(int index){
        NSLog(@"inde :%d",index);
    }];
    _portraitNavBarsView.leftBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 40);
    _portraitNavBarsView.rightBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    [self.view addSubview:_portraitNavBarsView];
    [_portraitNavBarsView release];
    
    _btnDownedDelect = [ControlCreat createButtonWithTitle:nil normalImage:nil heightedImage:nil tag:SDMVC_DownedDeleteBtnTag];
    [_btnDownedDelect setFrame:CGRectMake(_portraitNavBarsView.frame.size.width - 85, 1, 30, _portraitNavBarsView.frame.size.height - 1)];
    [_btnDownedDelect addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
    [_btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateSelected];
    _btnDownedDelect.hidden = YES;
    [_portraitNavBarsView addSubview:_btnDownedDelect];
    
    _btnDowningDelect = [ControlCreat createButtonWithTitle:nil normalImage:nil heightedImage:nil tag:SDMVC_DowningDeleteBtnTag];
    [_btnDowningDelect setFrame:CGRectMake(_portraitNavBarsView.frame.size.width - 85, 1, 30, _portraitNavBarsView.frame.size.height - 1)];
    [_btnDowningDelect addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
    [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateSelected];
    _btnDowningDelect.hidden = YES;
    [_portraitNavBarsView addSubview:_btnDowningDelect];
}

- (void)addTableView
{
    _allTableView = [[AlinkTableView alloc] initWithFrame:CGRectMake(0, 6, APPWIDTH_VISION-10, APPWIDTH-LandscapeTitleHeight-_bottomView.frame.size.height-_titleView.frame.size.height-6)];
    _allTableView.tableView.dataSource = self;
    _allTableView.tableView.delegate = self;
    _allTableView.tableView.backgroundColor = [UIColor clearColor];
    _allTableView.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_mainScrollView addSubview:_allTableView];
    
    _downloadedTableView = [[AlinkTableView alloc] initWithFrame:CGRectMake(APPHEIGHT, 6, APPHEIGHT-10, _allTableView.frame.size.height)];
    _downloadedTableView.tableView.dataSource = self;
    _downloadedTableView.tableView.delegate = self;
    _downloadedTableView.tableView.backgroundColor = [UIColor clearColor];
    _downloadedTableView.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_mainScrollView addSubview:_downloadedTableView];
    
    _downloadingTableView = [[AlinkTableView alloc] initWithFrame:CGRectMake(2*APPHEIGHT, 6, APPHEIGHT-10, _allTableView.frame.size.height)];
    _downloadingTableView.tableView.dataSource = self;
    _downloadingTableView.tableView.delegate = self;
    _downloadingTableView.tableView.backgroundColor = [UIColor clearColor];
    _downloadingTableView.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_mainScrollView addSubview:_downloadingTableView];
}


#pragma mark
#pragma mark - 视图控制

//调整横屏控件坐标和图片
-(void)changeLandscapeControlFrameWithImage
{
    _titleView.frame = CGRectMake(0, 23, APPWIDTH_VISION, 42);
    [_allBtn setFrame:CGRectMake(0, 0, _titleView.frame.size.width/3, _titleView.frame.size.height)];
    [_downloadedBtn setFrame:CGRectMake(APPWIDTH_VISION/3, _allBtn.frame.origin.y, APPWIDTH_VISION/3, bottomViewWidth-2)];
    [_downloadingBtn setFrame:CGRectMake(2*APPWIDTH_VISION/3, _allBtn.frame.origin.y, APPWIDTH_VISION/3, bottomViewWidth-2)];
    
    [_btnLineLabel setFrame:CGRectMake((self.selectedBtnIndex - SDMVC_AllBtnTag) * _allBtn.frame.size.width, _allBtn.frame.size.height-2, _allBtn.frame.size.width, 2)];
    
    _mainScrollView.frame = CGRectMake(0, LandscapeTitleHeight+42, APPWIDTH_VISION, APPHEIGHT_VISION - (LandscapeTitleHeight+42));
    [_allTableView setFrame:CGRectMake(0, 6, APPWIDTH_VISION,  APPWIDTH-LandscapeTitleHeight-_bottomView.frame.size.height-_titleView.frame.size.height-6)];
    [_allTableView hiddenRightBar:NO];
    
    [_downloadedTableView setFrame:CGRectMake(APPWIDTH_VISION, 6, APPWIDTH_VISION, _allTableView.frame.size.height)];
    [_downloadedTableView hiddenRightBar:NO];
    
    [_downloadingTableView setFrame:CGRectMake(2*APPHEIGHT, 6, APPWIDTH_VISION,_allTableView.frame.size.height)];
    [_downloadingTableView hiddenRightBar:NO];
    
    [_allTableView.tableView reloadData];
    [_downloadedTableView.tableView reloadData];
    [_downloadingTableView.tableView reloadData];
    
    switch (_selectedBtnIndex) {
        case SDMVC_AllBtnTag:
        {
            self.allBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
            self.downloadedBottomView == nil ? (0) : (self.downloadedBottomView.hidden = YES);
            self.downloadingBottomView == nil ? (0) : (self.downloadingBottomView .hidden = YES);
            [_mainScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
            break;
        }
        case SDMVC_DownloadedBtnTag:
        {
            self.downloadedBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
            self.allBottomView == nil ? (0) : (self.allBottomView.hidden = YES);
            self.downloadingBottomView == nil ? (0) : (self.downloadingBottomView .hidden = YES);
            [_mainScrollView setContentOffset:CGPointMake(APPHEIGHT, 0) animated:NO];
            break;
        }
        case SDMVC_DownloadingBtnTag:
        {
            self.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
            self.allBottomView == nil ? (0) : (self.allBottomView.hidden = YES);
            self.downloadedBottomView == nil ? (0) : (self.downloadedBottomView .hidden = YES);
            [_mainScrollView setContentOffset:CGPointMake(2*APPHEIGHT, 0) animated:NO];
            break;
        }
        default:
            break;
    }
}

//调整竖屏控件坐标和图片
-(void)changePortraitControlFrameWithImage
{
    _titleView.frame = CGRectMake(0, APP_STATEBAR_H + NAVICTR_V, APPWIDTH_VISION, 42);
    [_allBtn setFrame:CGRectMake(0, 0, _titleView.frame.size.width/3, _titleView.frame.size.height)];
    [_downloadedBtn setFrame:CGRectMake(APPWIDTH_VISION/3, _allBtn.frame.origin.y, APPWIDTH_VISION/3, bottomViewWidth-2)];
    [_downloadingBtn setFrame:CGRectMake(2*APPWIDTH_VISION/3, _allBtn.frame.origin.y, APPWIDTH_VISION/3, bottomViewWidth-2)];
    
    [_btnLineLabel setFrame:CGRectMake((self.selectedBtnIndex - SDMVC_AllBtnTag) * _allBtn.frame.size.width, _allBtn.frame.size.height-2, _allBtn.frame.size.width, 2)];
    
    
    _mainScrollView.frame = CGRectMake(0, APP_STATEBAR_H + NAVICTR_V+42, APPWIDTH_VISION, APPHEIGHT_VISION - (LandscapeTitleHeight+42));
    [_allTableView setFrame:CGRectMake(0, 6, APPWIDTH_VISION,  APPHEIGHT_VISION - (APP_STATEBAR_H + NAVICTR_V+42)-6)];
    [_allTableView hiddenRightBar:YES];
    
    [_downloadedTableView setFrame:CGRectMake(APPHEIGHT_VISION, 6, APPWIDTH_VISION, _allTableView.frame.size.height)];
    [_downloadedTableView hiddenRightBar:YES];
    
    [_downloadingTableView setFrame:CGRectMake(2*APPHEIGHT_VISION, 6, APPWIDTH_VISION, _allTableView.frame.size.height)];
    [_downloadingTableView hiddenRightBar:YES];
    
    
    [_allTableView.tableView reloadData];
    [_downloadedTableView.tableView reloadData];
    [_downloadingTableView.tableView reloadData];
    
    switch (_selectedBtnIndex) {
        case SDMVC_AllBtnTag:
        {
            [_mainScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
            break;
        }
        case SDMVC_DownloadedBtnTag:
        {
            [_mainScrollView setContentOffset:CGPointMake(APPHEIGHT_VISION, 0) animated:NO];
            _btnDowningDelect.hidden = YES;
            _btnDownedDelect.hidden = NO;
            break;
        }
        case SDMVC_DownloadingBtnTag:
        {
            [_mainScrollView setContentOffset:CGPointMake(2*APPHEIGHT_VISION, 0) animated:NO];
            _btnDowningDelect.hidden = NO;
            _btnDownedDelect.hidden = YES;
            break;
        }
        default:
            break;
    }
    
    if (_allBottomView)         { _allBottomView.hidden = YES; }
    if (_downloadedBottomView)  { _downloadedBottomView.hidden = YES; }
    if (_downloadingBottomView) { _downloadingBottomView.hidden = YES; }
    if (_bottomView)            { _bottomView.hidden = YES; }
}

//改变控制文本
-(void)changeControlText
{
}

//横屏逻辑处理
- (void)landscapeLogic
{
    _bottomView.hidden = NO;
    _landscapeTapView.hidden = NO;
    _portraitNavBarsView.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

//竖屏逻辑处理
- (void)portraitLogic
{
    _landscapeTapView.hidden = YES;
    _portraitNavBarsView.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if (IOS_7) { // 判断是否是IOS7
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    }
}

#pragma mark
#pragma mark 通知处理
- (void)notificationAction:(NSNotification *)notify
{
    if ([notify.name isEqualToString:NetWorkChangeNotification])
    {
        if (NetWorkType==0)
        {
            [_downloadingTableView.tableView reloadData];
        }
    }
    else if ([notify.name isEqualToString:ClearAllDataNotification])
    {
        [[AL_MapDownloadManager shareInstance] getCitiesListFromServer:^(NSArray *arrayOfCitiesList) {} isRefresh:YES];
        
        [_downloadingTableView.tableView reloadData];
        
        [_downloadedTableShowArray removeAllObjects];
        [_downloadedTableView.tableView reloadData];
        
        [_allTableView.tableView reloadData];
    }
}


#pragma mark-
#pragma mark按钮事件
- (void)buttonAction:(id)sender
{
    UIButton* button = (UIButton*)sender;
    int nTag = (int)button.tag;
    switch (nTag)
    {
        case SDMVC_AllBtnTag:
        {
            if (_selectedBtnIndex == SDMVC_AllBtnTag)
            {
                return;
            }
            else
            {
                [_allTableView.tableView reloadData];
                self.allBottomView = [self addBottomView:nil  withType:AllBottomView withTemp:self];
                self.allBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
                self.downloadedBottomView == nil ? (0) : (self.downloadedBottomView.hidden = YES);
                self.downloadingBottomView == nil ? (0) : (self.downloadingBottomView .hidden = YES);
                [_mainScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
                [_allBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
                [_downloadedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_downloadingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_btnLineLabel setFrame:CGRectMake(0, _btnLineLabel.frame.origin.y, _btnLineLabel.frame.size.width, _btnLineLabel.frame.size.height)];
            }
            _selectedBtnIndex = SDMVC_AllBtnTag;
            _btnDownedDelect.hidden = YES;
            _btnDowningDelect.hidden = YES;
        }
            break;
            
        case SDMVC_DownloadedBtnTag:
        {
            if (_selectedBtnIndex==SDMVC_DownloadedBtnTag)
            {
                return;
            }
            else
            {
                [_textFieldProvince resignFirstResponder];
                
                if (_isDownloadedCanDelete)
                {
                    self.downloadedBottomView = [self addBottomView:@[LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr"),LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr")] withType:DownloadedBottomView withTemp:self];
                }
                else
                {
                    self.downloadedBottomView = [self addBottomView:@[LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr"),LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr")] withType:DownloadedBottomView withTemp:self];
                }
                _btnDownedDelect.hidden = NO;
                _btnDowningDelect.hidden = YES;
                self.downloadedBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
                self.allBottomView == nil ? (0) : (self.allBottomView.hidden = YES);
                self.downloadingBottomView == nil ? (0) : (self.downloadingBottomView .hidden = YES);
                
                [_mainScrollView setContentOffset:CGPointMake(APPHEIGHT, 0) animated:NO];
                [_allBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_downloadedBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
                [_downloadingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_btnLineLabel setFrame:CGRectMake(_btnLineLabel.frame.size.width, _btnLineLabel.frame.origin.y, _btnLineLabel.frame.size.width, _btnLineLabel.frame.size.height)];
            }
            _selectedBtnIndex = SDMVC_DownloadedBtnTag;
        }
            break;
            
        case SDMVC_DownloadingBtnTag:
        {
            [_textFieldProvince resignFirstResponder];
            
            if (_selectedBtnIndex==SDMVC_DownloadingBtnTag)
            {
                return;
            }
            else
            {
                if (_isDownloadingCanDelete)
                {
                    self.downloadingBottomView = [self addBottomView:@[@"",LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr")] withType:DownloadingBottomView withTemp:self];
                }
                else
                {
                    self.downloadingBottomView = [self addBottomView:@[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")] withType:DownloadingBottomView withTemp:self];
                }
                _btnDownedDelect.hidden =  YES;
               _btnDowningDelect.hidden = NO;
                if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
                {
                    [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶_C.png"] forState:UIControlStateNormal];
                    _btnDowningDelect.userInteractionEnabled = NO;
                }
                else
                {
                    [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
                    _btnDowningDelect.userInteractionEnabled = YES;
                }
                
                self.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
                self.allBottomView == nil ? (0) : (self.allBottomView.hidden = YES);
                self.downloadedBottomView == nil ? (0) : (self.downloadedBottomView .hidden = YES);
                [_mainScrollView setContentOffset:CGPointMake(2*APPHEIGHT, 0) animated:NO];
                [_allBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_downloadedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [_downloadingBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
                [_btnLineLabel setFrame:CGRectMake(_btnLineLabel.frame.size.width*2, _btnLineLabel.frame.origin.y, _btnLineLabel.frame.size.width, _btnLineLabel.frame.size.height)];
            }
            _selectedBtnIndex = SDMVC_DownloadingBtnTag;
        }
            break;
            
        case SDMVC_SearchBtnTag:
        {
            if (_textFieldProvince.text.length==0)
            {
                AT_AlertView *alert = [AT_AlertView showAlertWithMessage:@"请输入城市名称！"];
                [alert dismissAfterDelay:3.0f];
            }
            else
            {
                AL_SettingDataSeachViewController *viewController = [[AL_SettingDataSeachViewController alloc] init];
                [viewController setSearchStr:_textFieldProvince.text];
                [self.navigationController pushViewController:viewController animated:YES];
                [viewController release];
                
                [_textFieldProvince resignFirstResponder];
            }
        }
            break;
            
        case SDMVC_DownedDeleteBtnTag:
        {
            [self downloadedDeleteBtnActionWithTemp:self];
        }
            break;
            
        case  SDMVC_DowningDeleteBtnTag:
        {
            if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count!=0)
            {
                [self downloadingDeleteBtnActionWithTemp:self];
            }
        }
            break;
            
        default:
            break;
    }
}


#pragma mark
#pragma mark UITableViewDeleagte,UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if([tableView isEqual:_allTableView.tableView])
    {
        if ([AL_MapDownloadManager shareInstance].arrayCitiesListFromServer.count!=0)
        {
            return [AL_MapDownloadManager shareInstance].arrayCitiesListFromServer.count+1;
        }
        else
        {
            return 0;
        }
    }
    else if ([tableView isEqual:_downloadedTableView.tableView])
    {
        return _downloadedCityInfoArray.count;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([AL_MapDownloadManager shareInstance].arrayCitiesListFromServer.count==0) { return 0; }
    
    if ([tableView isEqual:_allTableView.tableView])
    {
        if (section==0)
        {
            return 1;
        }
        else
        {
            if ([[_allTableShowArray objectAtIndex:section-1] boolValue])
            {
                AL_CityMapInfo *provinceInfo = (AL_CityMapInfo*)[[AL_MapDownloadManager shareInstance].arrayCitiesListFromServer objectAtIndex:section-1];
                if (provinceInfo.isProvince)
                {
                    return provinceInfo.arrayOfSubCities.count+1;
                }
                else
                {
                    return 1;
                }
            }
            else
            {
                return 1;
            }
        }
    }
    else if ([tableView isEqual:_downloadedTableView.tableView])
    {
        if (section==_downloadedCityInfoArray.count)
        {
            return 1;
        }
        else
        {
            if (_downloadedTableShowArray.count>0 && [[_downloadedTableShowArray objectAtIndex:section] boolValue])
            {
                AL_CityMapInfo *provinceInfo = (AL_CityMapInfo*)[_downloadedCityInfoArray objectAtIndex:section];
                if (provinceInfo.isProvince)
                {
                    return provinceInfo.arrayOfSubCities.count+1;
                }
                else
                {
                    return 1;
                }
            }
            else
            {
                return 1;
            }
        }
    }
    else
    {
        return [AL_MapDownloadManager shareInstance].arrayDownloadingList.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kHeight5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block AL_SettingDataManagementViewController *temp = self;
    
    if ([tableView isEqual:_allTableView.tableView])
    {
        if (indexPath.section==0)
        {
            static NSString *reuseIdetify = @"cell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdetify];
            if (!cell)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdetify] autorelease] ;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = [UIColor clearColor];
                
                _textFieldProvince = [[UITextField alloc] initWithFrame:CGRectMake(0, (kHeight5-40)/2, cell.contentView.frame.size.width - 90, 40)];
                _textFieldProvince.leftViewMode = UITextFieldViewModeAlways;
                _textFieldProvince.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                UIImageView  *leftView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 13, 40, 25)] autorelease];
                leftView.contentMode = UIViewContentModeCenter;
                leftView.image = [UIImage imageNamed:@"Icon_Search_TextField_Search.png"];
                _textFieldProvince.leftView = leftView;
                _textFieldProvince.layer.cornerRadius = 5.0f;
                _textFieldProvince.backgroundColor = [UIColor lightGrayColor];
                _textFieldProvince.placeholder = LOCALIZESTR(@"AL_Setting_SearchCity", @"AL_SettingStr");
                _textFieldProvince.textAlignment = NSTextAlignmentLeft;
                _textFieldProvince.returnKeyType = UIReturnKeySearch;
                _textFieldProvince.delegate = self;
                _textFieldProvince.font = [UIFont systemFontOfSize:18.0f];
                _textFieldProvince.clearsOnBeginEditing = YES;
                _textFieldProvince.clearButtonMode = UITextFieldViewModeWhileEditing;
                [cell.contentView addSubview:_textFieldProvince];
                
                _seachBtn = [self createButtonWithTitle:LOCALIZESTR(@"AL_Setting_Search", @"AL_SettingStr") normalImage:@"" heightedImage:nil tag:SDMVC_SearchBtnTag];
                [_seachBtn setFrame:CGRectMake(_textFieldProvince.frame.origin.x+_textFieldProvince.frame.size.width+5, 0, 80, kHeight5)];
                [_seachBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
                _seachBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
                [cell.contentView addSubview:_seachBtn];
            }
            
            _textFieldProvince.frame = CGRectMake(5, (kHeight5-40)/2,  _allTableView.tableView.frame.size.width - 90, 40);
            _enterSearchBtn.frame = _textFieldProvince.frame;
            [_seachBtn setFrame:CGRectMake(_textFieldProvince.frame.origin.x+_textFieldProvince.frame.size.width+5, 0, 80, kHeight5)];
            
            return cell;
        }
        else
        {
            static NSString *reuseIdetify = @"AL_SettingDataManAllCell";
            AL_SettingDataManAllCell *cell = (AL_SettingDataManAllCell*)[tableView dequeueReusableCellWithIdentifier:reuseIdetify];
            if (!cell)
            {
                cell = [[[AL_SettingDataManAllCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdetify cellWidth:_allTableView.tableView.frame.size.width cellHeight:kHeight5] autorelease] ;;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = [UIColor clearColor];
            }
            
            __block AL_CityMapInfo *provinceInfo = (AL_CityMapInfo*)[[AL_MapDownloadManager shareInstance].arrayCitiesListFromServer objectAtIndex:indexPath.section-1];
            if (indexPath.row==0)
            {
                BOOL hasDownloaded = NO;
                if (provinceInfo.statusForDownload==MDS_HAS_DOWNLOADED)
                {
                    hasDownloaded = YES;
                }
                
                __block BOOL isOpened = NO;
                if ([[_allTableShowArray objectAtIndex:indexPath.section-1] boolValue])
                {
                    isOpened = YES;
                }
                
                __block BOOL hasSubCity = NO;
                if (provinceInfo.arrayOfSubCities)
                {
                    if (provinceInfo.arrayOfSubCities.count>0)
                    {
                        hasSubCity = YES;
                    }
                }
                
                cell.downloadBtnClickBlock = ^{
                    if (hasSubCity)
                    {
                        if (isOpened)
                        {
                            [temp.allTableShowArray replaceObjectAtIndex:indexPath.section-1 withObject:[NSNumber numberWithBool:NO]];
                            [temp.allTableView.tableView reloadData];
                        }
                        else
                        {
                            [temp.allTableShowArray replaceObjectAtIndex:indexPath.section-1 withObject:[NSNumber numberWithBool:YES]];
                            [temp.allTableView.tableView reloadData];
                            NSInteger totalPreviousRow = 0;
                            for (NSInteger i=0; i<indexPath.section; i++)
                            {
                                totalPreviousRow += [_allTableView.tableView numberOfRowsInSection:i];
                            }
                            [temp.allTableView.tableView setContentOffset:CGPointMake(0, totalPreviousRow*kHeight5)];
                        }
                    }
                    else
                    {
                        [temp allTableViewDownloadCity:provinceInfo withTemp:temp];
                    }
                };
                
                NSString *sizeStr;
                if (provinceInfo.nSize<1024*1024)
                {
                    sizeStr = [NSString stringWithFormat:@"%0.1fKB", (1.0*provinceInfo.nSize)/1024];
                }
                else
                {
                    sizeStr = [NSString stringWithFormat:@"%0.1fM", (1.0*provinceInfo.nSize)/(1024*1024)];
                }
                NSMutableAttributedString *attriString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@", provinceInfo.szName, sizeStr]] autorelease];
                
                [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, provinceInfo.szName.length)];
                
                [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:113.0/255 green:119.0/255 blue:120.0/255 alpha:1.0f] range:NSMakeRange(provinceInfo.szName.length, sizeStr.length+2)];
                
                UIFont *baseFont = [UIFont boldSystemFontOfSize:20];
                [attriString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, provinceInfo.szName.length)];
                UIFont *baseFont1 = [UIFont boldSystemFontOfSize:14];
                [attriString addAttribute:NSFontAttributeName value:baseFont1 range:NSMakeRange(provinceInfo.szName.length, sizeStr.length+2)];
                
                [cell setTitle:attriString isSubCitys:NO hasSubCity:hasSubCity hasDownloaded:hasDownloaded isDownLoadPause:YES hasUpdate:provinceInfo.isHasUpdateInfo isOpened:isOpened];
            }
            else
            {
                __block AL_CityMapInfo *cityInfo = (AL_CityMapInfo*)[provinceInfo.arrayOfSubCities objectAtIndex:indexPath.row-1];
                __block BOOL hasDownloaded = NO;
                if (cityInfo.statusForDownload==MDS_HAS_DOWNLOADED)
                {
                    hasDownloaded = YES;
                }
                
                cell.downloadBtnClickBlock = ^{
                    if (!hasDownloaded || cityInfo.isHasUpdateInfo)
                    {
                        [temp allTableViewDownloadCity:cityInfo withTemp:temp];
                    }
                };
                
                NSString *sizeStr;
                if (cityInfo.nSize<1024*1024)
                {
                    sizeStr = [NSString stringWithFormat:@"%0.1fKB", (1.0*cityInfo.nSize)/1024];
                }
                else
                {
                    sizeStr = [NSString stringWithFormat:@"%0.1fM", (1.0*cityInfo.nSize)/(1024*1024)];
                }
                
                if ([cityInfo.szCityCode rangeOfString:@"0000"].length>0)
                {
                    sizeStr = @"";
                }
                
                NSMutableAttributedString *attriString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@", cityInfo.szName, sizeStr]] autorelease];
                
                [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, cityInfo.szName.length)];
                
                [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:113.0/255 green:119.0/255 blue:120.0/255 alpha:1.0f] range:NSMakeRange(cityInfo.szName.length, sizeStr.length+2)];
                
                UIFont *baseFont = [UIFont boldSystemFontOfSize:20];
                [attriString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, cityInfo.szName.length)];
                UIFont *baseFont1 = [UIFont boldSystemFontOfSize:14];
                [attriString addAttribute:NSFontAttributeName value:baseFont1 range:NSMakeRange(cityInfo.szName.length, sizeStr.length+2)];
                
                [cell setTitle:attriString isSubCitys:YES hasSubCity:NO hasDownloaded:hasDownloaded isDownLoadPause:YES hasUpdate:cityInfo.isHasUpdateInfo isOpened:NO];
            }
            
            return cell;
        }
    }
    else if ([tableView isEqual:_downloadedTableView.tableView])
    {
        static NSString *reuseIdetify = @"AL_SettingDataManAllCell";
        AL_SettingDataManAllCell *cell = (AL_SettingDataManAllCell*)[tableView dequeueReusableCellWithIdentifier:reuseIdetify];
        if (!cell)
        {
            cell = [[[AL_SettingDataManAllCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdetify cellWidth:_allTableView.tableView.frame.size.width cellHeight:kHeight5] autorelease] ;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
        }
        
        __block AL_CityMapInfo *provinceInfo = [_downloadedCityInfoArray objectAtIndex:indexPath.section];
        if (indexPath.row==0)
        {
            __block BOOL isOpened = NO;
            if ([[_downloadedTableShowArray objectAtIndex:indexPath.section] boolValue])
            {
                isOpened = YES;
            }
            
            __block BOOL hasSubCity = NO;
            if (provinceInfo.arrayOfSubCities)
            {
                if (provinceInfo.arrayOfSubCities.count>0)
                {
                    hasSubCity = YES;
                }
            }
            
            cell.downloadBtnClickBlock = ^{
                if (hasSubCity)
                {
                    if (isOpened)
                    {
                        [temp.downloadedTableShowArray replaceObjectAtIndex:indexPath.section withObject:[NSNumber numberWithBool:NO]];
                        [temp.downloadedTableView.tableView reloadData];
                    }
                    else
                    {
                        [temp.downloadedTableShowArray replaceObjectAtIndex:indexPath.section withObject:[NSNumber numberWithBool:YES]];
                        [temp.downloadedTableView.tableView reloadData];
                    }
                }
                else
                {
                    if (temp.isDownloadedCanDelete)
                    {
                        [temp deleteDownloadedCity:provinceInfo withTemp:temp withIndex:indexPath.section];
                    }
                    else
                    {
                        if (provinceInfo.isHasUpdateInfo)
                        {
                            NSLog(@"下载更新");
                            [temp allTableViewDownloadCity:provinceInfo withTemp:temp];
                        }
                    }
                }
            };
            
            NSString *sizeStr;
            if (provinceInfo.nSize<1024*1024)
            {
                sizeStr = [NSString stringWithFormat:@"%0.1fKB", (1.0*provinceInfo.nSize)/1024];
            }
            else
            {
                sizeStr = [NSString stringWithFormat:@"%0.1fM", (1.0*provinceInfo.nSize)/(1024*1024)];
            }
            NSMutableAttributedString *attriString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@", provinceInfo.szName, sizeStr]] autorelease];
            
            [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, provinceInfo.szName.length)];
            
            [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:113.0/255 green:119.0/255 blue:120.0/255 alpha:1.0f] range:NSMakeRange(provinceInfo.szName.length, sizeStr.length+2)];
            
            UIFont *baseFont = [UIFont boldSystemFontOfSize:20];
            [attriString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, provinceInfo.szName.length)];
            UIFont *baseFont1 = [UIFont boldSystemFontOfSize:14];
            [attriString addAttribute:NSFontAttributeName value:baseFont1 range:NSMakeRange(provinceInfo.szName.length, sizeStr.length+2)];
            
            if ([provinceInfo.szCityCode isEqualToString:@"0"])
            {
                [cell setTitle12:attriString isSubCitys:NO hasSubCity:hasSubCity hasDownloaded:provinceInfo.isHasUpdateInfo isDownLoadPause:YES hasUpdate:provinceInfo.isHasUpdateInfo isOpened:isOpened isDeleting:_isDownloadedCanDelete isBaseData:YES];
            }
            else
            {
                [cell setTitle12:attriString isSubCitys:NO hasSubCity:hasSubCity hasDownloaded:provinceInfo.isHasUpdateInfo isDownLoadPause:YES hasUpdate:provinceInfo.isHasUpdateInfo isOpened:isOpened isDeleting:_isDownloadedCanDelete isBaseData:NO];
            }
        }
        else
        {
            __block AL_CityMapInfo *cityInfo = (AL_CityMapInfo*)[provinceInfo.arrayOfSubCities objectAtIndex:indexPath.row-1];
            __block BOOL hasDownloaded = NO;
            if (cityInfo.statusForDownload==MDS_HAS_DOWNLOADED)
            {
                hasDownloaded = YES;
            }
            
            cell.downloadBtnClickBlock = ^{
                if (temp.isDownloadedCanDelete)
                {
                    [temp deleteDownloadedCity:cityInfo withTemp:temp withIndex:indexPath.section];
                }
                else
                {
                    if (cityInfo.isHasUpdateInfo)
                    {
                        NSLog(@"下载更新");
                        [temp allTableViewDownloadCity:cityInfo withTemp:temp];
                    }
                }
            };
            
            NSString *sizeStr;
            if (cityInfo.nSize<1024*1024)
            {
                sizeStr = [NSString stringWithFormat:@"%0.1fKB", (1.0*cityInfo.nSize)/1024];
            }
            else
            {
                sizeStr = [NSString stringWithFormat:@"%0.1fM", (1.0*cityInfo.nSize)/(1024*1024)];
            }
            NSMutableAttributedString *attriString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@", cityInfo.szName, sizeStr]] autorelease];
            
            [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, cityInfo.szName.length)];
            
            [attriString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:113.0/255 green:119.0/255 blue:120.0/255 alpha:1.0f] range:NSMakeRange(cityInfo.szName.length, sizeStr.length+2)];
            
            UIFont *baseFont = [UIFont boldSystemFontOfSize:20];
            [attriString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, cityInfo.szName.length)];
            UIFont *baseFont1 = [UIFont boldSystemFontOfSize:14];
            [attriString addAttribute:NSFontAttributeName value:baseFont1 range:NSMakeRange(cityInfo.szName.length, sizeStr.length+2)];
            
            [cell setTitle12:attriString isSubCitys:YES hasSubCity:NO hasDownloaded:hasDownloaded isDownLoadPause:YES hasUpdate:cityInfo.isHasUpdateInfo isOpened:NO isDeleting:_isDownloadedCanDelete isBaseData:NO];
            
        }
        
        return cell;
    }
    else
    {
        static NSString *reuseIdetify = @"AL_SettingDataManagementViewCell";
        AL_SettingDataManagementViewCell *cell = (AL_SettingDataManagementViewCell*)[tableView dequeueReusableCellWithIdentifier:reuseIdetify];
        if (!cell)
        {
            cell = [[[AL_SettingDataManagementViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdetify cellWidth:_downloadingTableView.tableView.frame.size.width cellHeight:kHeight5] autorelease] ;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
        }
        
        AL_CityMapInfo *cityInfo = (AL_CityMapInfo*)[[AL_MapDownloadManager shareInstance].arrayDownloadingList objectAtIndex:indexPath.row];
        
        NSString *sizeStr;
        if (cityInfo.nSize<1024*1024)
        {
            sizeStr = [NSString stringWithFormat:@"%0.1fKB", (1.0*cityInfo.nSize)/1024];
        }
        else
        {
            sizeStr = [NSString stringWithFormat:@"%0.1fM", (1.0*cityInfo.nSize)/(1024*1024)];
        }
        
        NSMutableAttributedString *attriString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@", cityInfo.szName, sizeStr]] autorelease];
        UIFont *baseFont = [UIFont boldSystemFontOfSize:kSize2];
        [attriString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, cityInfo.szName.length)];
        UIFont *baseFont1 = [UIFont boldSystemFontOfSize:kSize6];
        [attriString addAttribute:NSFontAttributeName value:baseFont1 range:NSMakeRange(cityInfo.szName.length, sizeStr.length+2)];
        
        int controlStatus = SMD_ISDOWNLOADING;
        if (cityInfo.statusForDownload==MDS_IS_DOWNLOADING)
        {
            controlStatus = SMD_ISDOWNLOADING;
        }
        else if (cityInfo.statusForDownload==MDS_WAIT_FOR_DOWNLOADING)
        {
            controlStatus = SMD_WAIT_FOR_DOWNLOADING;
        }
        else
        {
            controlStatus = SMD_PASUE;
        }
        if (_isDownloadingCanDelete)
        {
            controlStatus = SMD_Delete;
        }
        [cell setDownloadCityName:attriString controlStatus:controlStatus];
        
        NSString *percentStr = [NSString stringWithFormat:@"%0.2f",cityInfo.nCountOfHasDownloaded*1.0/cityInfo.nSize];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cityInfo.szPathofDownload])
        {
            percentStr = @"1";
        }
        else if (![[NSFileManager defaultManager] fileExistsAtPath:cityInfo.szpathOfTemp])
        {
            percentStr = @"0";
        }
        else
        {
            percentStr = [NSString stringWithFormat:@"%0.2f",cityInfo.nCountOfHasDownloaded*1.0/cityInfo.nSize];
        }
        
        [cell setDownloadPercent:[percentStr floatValue] isPause:controlStatus];
        
        __block AL_CityMapInfo *tempCityInfo = cityInfo;
        cell.downloadBlock = ^{
            if (temp.isDownloadingCanDelete)
            {
                [temp deleteDownloadingCity:tempCityInfo withTemp:temp];
            }
            else
            {
                [temp downloadingTableViewDownloadCity:tempCityInfo withTemp:temp];
            }
        };
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:_allTableView.tableView])
    {
        if (indexPath.section!=0)
        {
            if (indexPath.row==0)
            {
                AL_CityMapInfo *provinceInfo = (AL_CityMapInfo*)[[AL_MapDownloadManager shareInstance].arrayCitiesListFromServer objectAtIndex:indexPath.section-1];
                if (provinceInfo.arrayOfSubCities)
                {
                    if (provinceInfo.arrayOfSubCities.count>0)
                    {
                        if ([[_allTableShowArray objectAtIndex:indexPath.section-1] boolValue])
                        {
                            [_allTableShowArray replaceObjectAtIndex:indexPath.section-1 withObject:[NSNumber numberWithBool:NO]];
                            [_allTableView.tableView reloadData];
                        }
                        else
                        {
                            [_allTableShowArray replaceObjectAtIndex:indexPath.section-1 withObject:[NSNumber numberWithBool:YES]];
                            [_allTableView.tableView reloadData];
                            NSInteger totalPreviousRow = 0;
                            for (NSInteger i=0; i<indexPath.section; i++)
                            {
                                totalPreviousRow += [_allTableView.tableView numberOfRowsInSection:i];
                            }
                            
                            [_allTableView.tableView setContentOffset:CGPointMake(0, totalPreviousRow*kHeight5)];
                        }
                    }
                }
            }
        }
    }
    else if ([tableView isEqual:_downloadedTableView.tableView])
    {
        if (indexPath.section!=_downloadedCityInfoArray.count)
        {
            if (indexPath.row==0)
            {
                AL_CityMapInfo *provinceInfo = (AL_CityMapInfo*)[_downloadedCityInfoArray objectAtIndex:indexPath.section];
                if (provinceInfo.arrayOfSubCities)
                {
                    if (provinceInfo.arrayOfSubCities.count>0)
                    {
                        if ([[_downloadedTableShowArray objectAtIndex:indexPath.section] boolValue])
                        {
                            [_downloadedTableShowArray replaceObjectAtIndex:indexPath.section withObject:[NSNumber numberWithBool:NO]];
                            [_downloadedTableView.tableView reloadData];
                        }
                        else
                        {
                            [_downloadedTableShowArray replaceObjectAtIndex:indexPath.section withObject:[NSNumber numberWithBool:YES]];
                            [_downloadedTableView.tableView reloadData];
                        }
                    }
                }
            }
        }
    }
    else
    {
    }
}

#pragma mark
#pragma mark MapDownloadDelegate

-(void)mapDownloadSuccess:(AL_CityMapInfo *)cityinfo
{
    [self getDownloadedProvince:self];
    
    [_downloadingTableView.tableView reloadData];
    [_downloadedTableView.tableView reloadData];
    [_allTableView.tableView reloadData];
    
    if (_selectedBtnIndex==SDMVC_DownloadingBtnTag)
    {
        if (self.downloadingBottomView)
        {
            [self.downloadingBottomView removeFromSuperview];
            self.downloadingBottomView = nil;
        }
        self.downloadingBottomView = [self addBottomView:@[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")] withType:DownloadingBottomView withTemp:self];
        if (_M_DeviceOrientation==0) { self.downloadingBottomView.hidden = YES; }
        else {self.downloadingBottomView.hidden = NO;}
    }
    else if (_selectedBtnIndex==SDMVC_DownloadedBtnTag)
    {
        [self.downloadedBottomView setMiddleBtnAtIndex:0 userInteractEnable:YES textColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
        if (_M_DeviceOrientation==0) { self.downloadedBottomView.hidden = YES; }
        else {self.downloadedBottomView.hidden = NO;}
    }
    
    if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶_C.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = NO;
    }
    else
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = YES;
    }
    
    NSLog(@"下载完成");
}

-(void)mapDownloadFail:(AL_CityMapInfo *)cityinfo
{
    [[AL_MapDownloadManager shareInstance] pauseDataDownload:cityinfo];
    [_downloadingTableView.tableView reloadData];
    if (_selectedBtnIndex==SDMVC_DownloadingBtnTag)
    {
        self.downloadingBottomView = [self addBottomView:@[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")] withType:DownloadingBottomView withTemp:self];
        self.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
    }
    
    _btnDowningDelect.hidden = _M_DeviceOrientation == 0 ? NO : YES;
    if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶_C.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = NO;
    }
    else
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = YES;
    }
    NSLog(@"下载失败");
    
    NSString *alertMessage = [NSString stringWithFormat:@"%@下载失败，请重新下载",cityinfo.szName];
    AT_AlertView *alertView = [AT_AlertView showAlertWithMessage:alertMessage];
    [alertView dismissAfterDelay:3.0f];
}


- (void)mapDownloadUnpressfail:(AL_CityMapInfo *)cityinfo
{
    NSLog(@"解压失败");
    AT_AlertView *alertView = [AT_AlertView showAlertWithMessage:@"文件解压错误，请重新下载"];
    [alertView dismissAfterDelay:3.0f];
    self.downloadingBottomView = [self addBottomView:@[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")] withType:DownloadingBottomView withTemp:self];
    _btnDowningDelect.hidden = _M_DeviceOrientation == 0 ? NO : YES;
    if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶_C.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = NO;
    }
    else
    {
        [_btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
        _btnDowningDelect.userInteractionEnabled = YES;
    }
    self.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
}

-(void)mapDownloadReceiveData:(AL_CityMapInfo *)cityinfo
{
    [_downloadingTableView.tableView reloadData];
}


#pragma mark
#pragma mark 内部方法

//底栏添加
- (Alink_BottomView *)addBottomView:(NSArray *)middleBtnArray withType:(int)bottomViewType withTemp:(AL_SettingDataManagementViewController *)temp
{
    temp.screenWith = _M_DeviceOrientation == 0 ? APPHEIGHT_VISION : APPWIDTH_VISION;
    temp.screenHeith = _M_DeviceOrientation == 0 ? APPWIDTH_VISION :APPHEIGHT_VISION;
    
    if (temp.bottomView)
    {
        temp.bottomView = nil;
        [temp.bottomView removeFromSuperview];
    }
    temp.bottomView = [[[Alink_BottomView alloc] init] autorelease];
    
    __block AL_SettingDataManagementViewController *weakSelf = temp;
    
    NSArray *leftRightBtnArray = @[@"btn_menu_return.png",@"btn_menu_enter.png"];
    [temp.bottomView initWithFrame:CGRectMake(0, 0, temp.screenWith, bottomViewWidth) backGroundImage:@"BG_bottomBar_bg.png" leftAndRightBtnArray:leftRightBtnArray middleBtnArray:middleBtnArray leftAndRightBtnWidth:bottomViewHeight seperateLineImage:nil];
    [temp.bottomView setLeftBtnBlock:^(){
        [weakSelf popWithTemp:weakSelf];}
                       rightBtnBlock:^(){ [weakSelf popToRootWithTemp:weakSelf];}
                         midBtnBlock:^(int index){
                             if (bottomViewType==DownloadedBottomView)
                             {
                                 if ([AL_MapDownloadManager shareInstance].arrayDownloadedList.count!=0)
                                 {
                                     if (index==0)
                                     {
                                         [weakSelf downloadedDeleteBtnActionWithTemp:weakSelf];
                                     }
                                     else
                                     {
//                                         AT_AlertView *alert = [AT_AlertView showAlertWithMessage:@"当前没有更新"];
//                                         [alert dismissAfterDelay:3.0f];
                                         
                                         for (AL_CityMapInfo *downloadedTempCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
                                         {
                                             if (downloadedTempCityInfo.isHasUpdateInfo)
                                             {
                                                 [weakSelf allTableViewDownloadCity:downloadedTempCityInfo withTemp:weakSelf];
                                             }
                                         }
                                     }
                                 }
                             }
                             else
                             {
                                 if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count!=0)
                                 {
                                     if (index==1)
                                     {
                                         [weakSelf downloadingDeleteBtnActionWithTemp:weakSelf];
                                     }
                                 }
                             }
                         }];
    [temp.bottomView setFrame:CGRectMake(0, temp.screenHeith - bottomViewWidth, temp.screenWith, bottomViewWidth)];
    [temp.view addSubview:temp.bottomView];
    
    [temp.bottomView.leftBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_return_B.png"] forState:UIControlStateHighlighted];
    [temp.bottomView.rightBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_enter_B.png"] forState:UIControlStateHighlighted];
    
    
    if (middleBtnArray)
    {
        if (bottomViewType==DownloadingBottomView&&[AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
        {
            [temp.bottomView setMiddleBtnTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] normalImage:nil selectBackImage:nil];
        }
        else if (bottomViewType==DownloadedBottomView)
        {
            [temp.bottomView setMiddleBtnAtIndex:0 userInteractEnable:YES textColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
            BOOL downloadedHasUpdate = NO;
            for (AL_CityMapInfo *downloadTempCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
            {
                if (downloadTempCityInfo.isHasUpdateInfo)
                {
                    downloadedHasUpdate = YES;
                    break;
                }
            }
            
            if (downloadedHasUpdate)
            {
                [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:YES textColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
            }
            else
            {
                [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:NO textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] normalImage:nil selectBackImage:nil];
            }
            
            if ([[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==1 || [[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==0)
            {
                if ([[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==1)
                {
                    AL_CityMapInfo *tempCityInfo = [[[AL_MapDownloadManager shareInstance] arrayDownloadedList] objectAtIndex:0];
                    if ([tempCityInfo.szCityCode isEqualToString:@"0"])
                    {
                        [temp.bottomView setMiddleBtnAtIndex:0 userInteractEnable:NO textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:nil normalImage:nil selectBackImage:nil];
                    }
                }
                else
                {
                    [temp.bottomView setMiddleBtnAtIndex:0 userInteractEnable:NO textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:nil normalImage:nil selectBackImage:nil];
                }
            }
        }
        else
        {
            [temp.bottomView setMiddleBtnTextColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
        }
    }
    
    return temp.bottomView;
}

/**
 *  进入正在下载列表所要进行的操作
 */
- (void)enterDownloadingView:(AL_SettingDataManagementViewController *)temp
{
    if (temp.bottomView)
    {
        [temp.bottomView removeFromSuperview];
        temp.bottomView = nil;
    }

    temp.bottomView = [[[Alink_BottomView alloc] init] autorelease];
    NSArray *leftRightBtnArray = @[@"btn_menu_return.png",@"btn_menu_enter.png"];
    NSArray *midArray = @[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")];
    if (temp.isDownloadingCanDelete)
    {
        midArray = @[@"",LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr")];
    }
    [temp.bottomView initWithFrame:CGRectMake(0, 320-44, 568, 44) backGroundImage:@"BG_bottomBar_bg.png" leftAndRightBtnArray:leftRightBtnArray middleBtnArray:midArray leftAndRightBtnWidth:86 seperateLineImage:nil];
    [temp.bottomView setLeftBtnBlock:^(){
        [temp popWithTemp:temp];}
                   rightBtnBlock:^(){ [temp popToRootWithTemp:temp]; }
                     midBtnBlock:^(int index){
                         if (index==1)
                         {
                             [temp downloadingDeleteBtnActionWithTemp:temp];
                         }
                     }];
    
    [temp.bottomView.leftBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_return_B.png"] forState:UIControlStateHighlighted];
    [temp.bottomView.rightBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_enter_B.png"] forState:UIControlStateHighlighted];
    [temp.bottomView setFrame:CGRectMake(0, APPWIDTH-bottomViewWidth, APPHEIGHT, bottomViewWidth)];
    
    [temp.view addSubview:temp.bottomView];
    [temp.bottomView setMiddleBtnTextColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
    
    temp.downloadingBottomView = temp.bottomView;
    temp.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
    
    [temp.mainScrollView setContentOffset:CGPointMake(2*APPHEIGHT, 0) animated:NO];
    [temp.allBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [temp.downloadedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [temp.downloadingBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
    [temp.btnLineLabel setFrame:CGRectMake(temp.btnLineLabel.frame.size.width*2, temp.btnLineLabel.frame.origin.y, temp.btnLineLabel.frame.size.width, temp.btnLineLabel.frame.size.height)];
    temp.selectedBtnIndex = SDMVC_DownloadingBtnTag;
    
    temp.btnDowningDelect.hidden = _M_DeviceOrientation == 0 ? NO : YES;
    temp.btnDowningDelect.userInteractionEnabled = YES;
    [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
    temp.btnDownedDelect.hidden = YES;
    
    temp.isDownloadingCanDelete = !temp.isDownloadingCanDelete;
    [temp downloadingDeleteBtnActionWithTemp:temp];
}

//跟上一个方法一样。
- (void)enterDownloadingView
{
    __block AL_SettingDataManagementViewController *temp = self;
    if (self.bottomView)
    {
        [self.bottomView removeFromSuperview];
        self.bottomView = nil;
    }
    self.bottomView = [[[Alink_BottomView alloc] init] autorelease];
    
    NSArray *leftRightBtnArray = @[@"btn_menu_return.png",@"btn_menu_enter.png"];
    NSArray *midArray = @[@"",LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr")];
    if (_isDownloadingCanDelete)
    {
        midArray = @[@"",LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr")];
    }
    [self.bottomView initWithFrame:CGRectMake(0, APPWIDTH-bottomViewWidth, APPHEIGHT, bottomViewWidth) backGroundImage:@"BG_bottomBar_bg.png" leftAndRightBtnArray:leftRightBtnArray middleBtnArray:midArray leftAndRightBtnWidth:bottomViewHeight seperateLineImage:nil];
    [self.bottomView setLeftBtnBlock:^(){
        [temp popWithTemp:temp];}
                       rightBtnBlock:^(){ [temp popToRootWithTemp:temp]; }
                         midBtnBlock:^(int index){
                             if (index==1)
                             {
                                 [temp downloadingDeleteBtnActionWithTemp:temp];
                             }
                         }];
    
    [self.bottomView.leftBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_return_B.png"] forState:UIControlStateHighlighted];
    [self.bottomView.rightBtn setBackgroundImage:[UIImage imageNamed:@"btn_menu_enter_B.png"] forState:UIControlStateHighlighted];
    [self.bottomView setFrame:CGRectMake(0, APPWIDTH-bottomViewWidth, APPHEIGHT, bottomViewWidth)];

    [self.view addSubview:self.bottomView];
    
    [self.bottomView setMiddleBtnTextColor:[UIColor colorWithRed:56.0/255 green:173.0/255 blue:217.0/255 alpha:1.0f] selectedTextColor:[UIColor colorWithRed:56.0/255 green:173.0/255 blue:217.0/255 alpha:1.0f] normalImage:nil selectBackImage:nil];
    self.downloadingBottomView =  self.bottomView;
    self.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
    
    [self.mainScrollView setContentOffset:CGPointMake(2*APPHEIGHT, 0) animated:NO];
    [_allBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_downloadedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_downloadingBtn setTitleColor:TextBlueColor forState:UIControlStateNormal];
    [_btnLineLabel setFrame:CGRectMake(_btnLineLabel.frame.size.width*2, _btnLineLabel.frame.origin.y, _btnLineLabel.frame.size.width, _btnLineLabel.frame.size.height)];
    self.selectedBtnIndex = SDMVC_DownloadingBtnTag;
    
    self.btnDowningDelect.hidden = _M_DeviceOrientation == 0 ? NO : YES;
    self.btnDowningDelect.userInteractionEnabled = YES;
    [self.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
    self.btnDownedDelect.hidden = YES;
    
    self.isDownloadingCanDelete = !self.isDownloadingCanDelete;
    [self downloadingDeleteBtnActionWithTemp:self];
}

//正在下载，点击删除按钮
- (void)downloadingDeleteBtnActionWithTemp:(AL_SettingDataManagementViewController *)temp
{
    if (!temp.isDownloadingCanDelete)
    {
        [[AL_MapDownloadManager shareInstance] pauseAllDownloading];
        
        temp.isDownloadingCanDelete = YES;
        [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateHighlighted];
        [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateNormal];
        
        [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr") textColor:MenuTextColor selectedTextColor:MenuSelectTextColor normalImage:nil selectBackImage:nil];
    }
    else
    {
        temp.isDownloadingCanDelete = NO;
        [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
        [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateHighlighted];
        
        [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr") textColor:MenuTextColor selectedTextColor:MenuSelectTextColor normalImage:nil selectBackImage:nil];
    }
    
    [temp.downloadingTableView.tableView reloadData];
}

//已下载点击删除按钮
- (void)downloadedDeleteBtnActionWithTemp:(AL_SettingDataManagementViewController *)temp
{
    if(!temp.isDownloadedCanDelete)
    {
        for (NSInteger i=0; i<temp.downloadedTableShowArray.count; i++)
        {
            if (![[temp.downloadedTableShowArray objectAtIndex:i] boolValue])
            {
                [temp.downloadedTableShowArray replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];
            }
        }
        
        temp.isDownloadedCanDelete = YES;
        
        [temp.bottomView setMiddleBtnAtIndex:0 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_Finish", @"AL_SettingStr") textColor:MenuTextColor selectedTextColor:MenuSelectTextColor normalImage:nil selectBackImage:nil];
        BOOL downloadedHasUpdate = NO;
        for (AL_CityMapInfo *downloadedTempCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
        {
            if (downloadedTempCityInfo.isHasUpdateInfo)
            {
                downloadedHasUpdate = YES;
                break;
            }
        }
        if (downloadedHasUpdate)
        {
            [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr") textColor:MenuTextColor  selectedTextColor:MenuTextColor  normalImage:nil selectBackImage:nil];
        }
        else
        {
            [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:NO text:LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr") textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f]  selectedTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f]  normalImage:nil selectBackImage:nil];
        }
        
        
        [temp.btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateHighlighted];
        [temp.btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateNormal];
    }
    else
    {
        for (NSInteger i=0; i<temp.downloadedTableShowArray.count; i++)
        {
            if ([[temp.downloadedTableShowArray objectAtIndex:i] boolValue])
            {
                [temp.downloadedTableShowArray replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
            }
        }
        
        temp.isDownloadedCanDelete = NO;
        
        [temp.bottomView setMiddleBtnAtIndex:0 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr") textColor:MenuTextColor selectedTextColor:MenuTextColor normalImage:nil selectBackImage:nil];
        BOOL downloadedHasUpdate = NO;
        for (AL_CityMapInfo *downloadedTempCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
        {
            if (downloadedTempCityInfo.isHasUpdateInfo)
            {
                downloadedHasUpdate = YES;
                break;
            }
        }
        if (downloadedHasUpdate)
        {
            [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:YES text:LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr") textColor:MenuTextColor  selectedTextColor:MenuTextColor  normalImage:nil selectBackImage:nil];
        }
        else
        {
            [temp.bottomView setMiddleBtnAtIndex:1 userInteractEnable:NO text:LOCALIZESTR(@"AL_Setting_AllUpdate", @"AL_SettingStr") textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f]  selectedTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f]  normalImage:nil selectBackImage:nil];
        }
        
        [temp.btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶.png"] forState:UIControlStateNormal];
        [temp.btnDownedDelect setImage:[UIImage imageNamed:@"icn_顶栏_打钩.png"] forState:UIControlStateHighlighted];
    }
    
    [temp.downloadedTableView.tableView reloadData];
}

//全部页面，点击下载
- (void)allTableViewDownloadCity:(AL_CityMapInfo *)cityInfo withTemp:(AL_SettingDataManagementViewController *)temp
{
    [temp.shouldDownloadCityArray removeAllObjects];
    
    BOOL isInDownlodingList = NO;
    for (AL_CityMapInfo *downloadingCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadingList)
    {
        if ([downloadingCityInfo.szCityCode isEqualToString:cityInfo.szCityCode])
        {
            isInDownlodingList = YES;
        }
    }
    
    if (!isInDownlodingList)
    {
        if ([cityInfo.szCityCode rangeOfString:@"0000"].length>0)//下载全省或者下载直辖市
        {
            AL_CityMapInfo *provinceInfo;
            for (AL_CityMapInfo *tempCityInfo in [AL_MapDownloadManager shareInstance].arrayCitiesListFromServer)
            {
                if ([tempCityInfo.szCityCode isEqualToString:cityInfo.szCityCode])
                {
                    provinceInfo = tempCityInfo;
                    break;
                }
            }
            
            if (provinceInfo.arrayOfSubCities && provinceInfo.arrayOfSubCities.count>0)
            {
                for (AL_CityMapInfo *tempCityInfo in provinceInfo.arrayOfSubCities)
                {
                    if (tempCityInfo.statusForDownload==MDS_NO_DOWNLOADED || cityInfo.isHasUpdateInfo==YES)
                    {
                        if ([tempCityInfo.szCityCode rangeOfString:@"0000"].length==0)
                        {
                            [temp.shouldDownloadCityArray addObject:tempCityInfo];
                        }
                    }
                }
            }
            else
            {
                if (cityInfo.statusForDownload==MDS_NO_DOWNLOADED || cityInfo.isHasUpdateInfo==YES)
                {
                    [temp.shouldDownloadCityArray addObject:cityInfo];
                }
            }
        }
        else//下载某个城市或者基础资源
        {
            if (cityInfo.statusForDownload==MDS_NO_DOWNLOADED || cityInfo.isHasUpdateInfo==YES)
            {
                [temp.shouldDownloadCityArray addObject:cityInfo];
            }
        }
    }

    BOOL shouldDownload = NO;
    if (temp.shouldDownloadCityArray.count>0)
    {
        shouldDownload = YES;
    }
    
    if (NetWorkType==1 && shouldDownload)
    {
        AT_AlertView *alert = [AT_AlertView showAlertWithMessage:LOCALIZESTR(@"AL_Setting_UserWifi", @"AL_SettingStr") cancelTitle:LOCALIZESTR(@"AL_Setting_OK", @"AL_SettingStr")  otherTitle:LOCALIZESTR(@"AL_Setting_Cancel", @"AL_SettingStr")  completion:^(BOOL cancelled, NSInteger buttonIndex) {
            if (buttonIndex==0)
            {
                NSLog(@"开始下载...");
                [temp enterDownloadingView:temp];
                
                for (AL_CityMapInfo *tempCityInfo in temp.shouldDownloadCityArray)
                {
                    [[AL_MapDownloadManager shareInstance] downLoadCityData:tempCityInfo];
                }
                
                if (temp.isDownloadingCanDelete)
                {
                    for (AL_CityMapInfo *tempCityInfo in temp.shouldDownloadCityArray)
                    {
                        [[AL_MapDownloadManager shareInstance] pauseDataDownload:tempCityInfo];
                    }
                }
                [temp.downloadingTableView.tableView reloadData];
            }
        }];
         
        [alert release];
    }
    else if (NetWorkType==0 && shouldDownload)
    {
        AT_AlertView *alert = [AT_AlertView showAlertWithMessage:@"网络连接失败，请检查网络连接"];
        [alert dismissAfterDelay:3.0f];
    }
    else if (shouldDownload)
    {
        NSLog(@"开始下载...");
        [temp enterDownloadingView:temp];

        for (AL_CityMapInfo *tempCityInfo in temp.shouldDownloadCityArray)
        {
            [[AL_MapDownloadManager shareInstance] downLoadCityData:tempCityInfo];
        }
        
        if (temp.isDownloadingCanDelete)
        {
            for (AL_CityMapInfo *tempCityInfo in temp.shouldDownloadCityArray)
            {
                [[AL_MapDownloadManager shareInstance] pauseDataDownload:tempCityInfo];
            }
        }
        [temp.downloadingTableView.tableView reloadData];
    }
    else
    {
        [temp enterDownloadingView:temp];
    }
}


//正在下载点击下载
- (void)downloadingTableViewDownloadCity:(AL_CityMapInfo *)cityInfo withTemp:(AL_SettingDataManagementViewController *)temp
{
    if (NetWorkType==1)
    {
        if (cityInfo.statusForDownload==MDS_IS_DOWNLOADING)
        {
            [[AL_MapDownloadManager shareInstance] pauseDataDownload:cityInfo];
            [temp.downloadingTableView.tableView reloadData];
        }
        else
        {
            AT_AlertView *alert = [AT_AlertView showAlertWithMessage:LOCALIZESTR(@"AL_Setting_UserWifi", @"AL_SettingStr") cancelTitle:LOCALIZESTR(@"AL_Setting_OK", @"AL_SettingStr")  otherTitle:LOCALIZESTR(@"AL_Setting_Cancel", @"AL_SettingStr")  completion:^(BOOL cancelled, NSInteger buttonIndex) {
                if (buttonIndex==0)
                {
                    [[AL_MapDownloadManager shareInstance] downLoadCityData:cityInfo];
                    [temp.downloadingTableView.tableView reloadData];
                }
            }];
             
            [alert release];
        }
    }
    else if (NetWorkType==0)
    {
        AT_AlertView *alert = [AT_AlertView showAlertWithMessage:@"网络连接失败，请检查网络连接"];
        [alert dismissAfterDelay:3.0f];
    }
    else
    {
        if (cityInfo.statusForDownload==MDS_IS_DOWNLOADING)
        {
            [[AL_MapDownloadManager shareInstance] pauseDataDownload:cityInfo];
            [temp.downloadingTableView.tableView reloadData];
        }
        else
        {
            [[AL_MapDownloadManager shareInstance] downLoadCityData:cityInfo];
            [temp.downloadingTableView.tableView reloadData];
        }
    }
}

/**
 *  获取已下载省份列表
 */
- (void)getDownloadedProvince:(AL_SettingDataManagementViewController *)temp
{
    NSMutableArray *downloadedArray = [NSMutableArray array];
    NSMutableArray *tempArrayCitiesListFromServer = [[[NSMutableArray alloc]initWithArray:[AL_MapDownloadManager shareInstance].arrayCitiesListFromServer copyItems:YES] autorelease];
    
    for (AL_CityMapInfo *cityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
    {
        AL_CityMapInfo *baseCityInfo = [tempArrayCitiesListFromServer firstObject];
        if ([cityInfo.szCityCode isEqualToString:baseCityInfo.szCityCode])
        {
            [downloadedArray addObject:cityInfo];
        }
        else
        {
            if (cityInfo.szCityCode.length>3)
            {
                NSString *subCityCode = [cityInfo.szCityCode substringWithRange:NSMakeRange(0, 2)];
                for (AL_CityMapInfo *provinceInfo in tempArrayCitiesListFromServer)
                {
                    if (provinceInfo.szCityCode.length>=3)
                    {
                        NSString *subProvinceCode = [provinceInfo.szCityCode substringWithRange:NSMakeRange(0, 2)];
                        if ([subCityCode isEqualToString:subProvinceCode])
                        {
                            [downloadedArray addObject:provinceInfo];
                            
                            break;
                        }
                    }
                }
            }
        }
    }

    NSSet *set = [NSSet setWithArray:downloadedArray];
    
    [temp.downloadedTableShowArray removeAllObjects];
    [temp.downloadedCityInfoArray removeAllObjects];
    
    temp.downloadedCityInfoArray = [[set allObjects] mutableCopy];
    for (AL_CityMapInfo *cityInfo in temp.downloadedCityInfoArray)
    {
        if (cityInfo.isProvince)
        {
            [cityInfo.arrayOfSubCities removeAllObjects];
            NSString *provinceCode = [cityInfo.szCityCode substringWithRange:NSMakeRange(0, 2)];
            
            for (AL_CityMapInfo *tempCityInfo in [AL_MapDownloadManager shareInstance].arrayDownloadedList)
            {
                if (tempCityInfo.szCityCode.length>3)
                {
                    NSString *cityCode = [tempCityInfo.szCityCode substringWithRange:NSMakeRange(0, 2)];
                    if ([cityCode isEqualToString:provinceCode])
                    {
                        if ([tempCityInfo.szCityCode rangeOfString:@"0000"].length==0)
                        {
                            [cityInfo.arrayOfSubCities addObject:tempCityInfo];
                        }
                    }
                }
            }
            
            float downloadedTotalSize = 0;
            BOOL downloadedCityHasUpdate = NO;
            for (AL_CityMapInfo * tempCityInfo in cityInfo.arrayOfSubCities)
            {
                downloadedTotalSize += tempCityInfo.nSize;
                if (tempCityInfo.isHasUpdateInfo)
                {
                    downloadedCityHasUpdate = YES;
                }
            }
            cityInfo.nSize = downloadedTotalSize;
            cityInfo.isHasUpdateInfo = downloadedCityHasUpdate;
        }
    }
    
    for (NSInteger i=0; i<temp.downloadedCityInfoArray.count+1; i++)
    {
        [temp.downloadedTableShowArray addObject:[NSNumber numberWithBool:NO]];
    }
    
    
    for (AL_CityMapInfo *tempCityInfo in temp.downloadedCityInfoArray)
    {
        if (tempCityInfo.isProvince)
        {
            [temp sortByHeaderChracter:tempCityInfo.arrayOfSubCities];
        }
    }
}

/**
 *  删除已下载数据
 */
- (void)deleteDownloadedCity:(AL_CityMapInfo *)cityInfo withTemp:(AL_SettingDataManagementViewController *)temp withIndex:(NSInteger)indexSection
{
    [[AL_MapDownloadManager shareInstance] deleteDownloadData:cityInfo];
    
    BOOL shouldBreak = NO;
    for (AL_CityMapInfo *tempProvinceInfo in temp.downloadedCityInfoArray)
    {
        if ([cityInfo.szCityCode isEqualToString:tempProvinceInfo.szCityCode])
        {
            [temp.downloadedCityInfoArray removeObject:tempProvinceInfo];
            break;
        }
        else
        {
            if (tempProvinceInfo.isProvince)
            {
                for (AL_CityMapInfo *tempCityInfo in tempProvinceInfo.arrayOfSubCities)
                {
                    if ([tempCityInfo.szCityCode isEqualToString:cityInfo.szCityCode])
                    {
                        [tempProvinceInfo.arrayOfSubCities removeObject:tempCityInfo];
                        
                        
                        if (tempProvinceInfo.arrayOfSubCities.count==0)
                        {
                            [temp.downloadedCityInfoArray removeObject:tempProvinceInfo];
                            [temp.downloadedTableShowArray removeObjectAtIndex:indexSection];
                        }
                        else
                        {
                            BOOL tempProHasUpdate = NO;
                            for (AL_CityMapInfo *tempSubCiInfo in tempProvinceInfo.arrayOfSubCities)
                            {
                                if (tempSubCiInfo.isHasUpdateInfo)
                                {
                                    tempProHasUpdate = YES;
                                    break;
                                }
                            }
                            tempProvinceInfo.isHasUpdateInfo = tempProHasUpdate;
                        }
                        
                        shouldBreak = YES;
                        break;
                    }
                }
            }
        }
        
        if (shouldBreak)
        {
            break;
        }
    }
    

    [temp.downloadedTableView.tableView reloadData];
    
    
    if ([[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==1 || [[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==0)
    {
        if ([[AL_MapDownloadManager shareInstance] arrayDownloadedList].count==1)
        {
            AL_CityMapInfo *tempCityInfo = [[[AL_MapDownloadManager shareInstance] arrayDownloadedList] objectAtIndex:0];
            if ([tempCityInfo.szCityCode isEqualToString:@"0"])
            {
                [temp.downloadedBottomView setMiddleBtnAtIndex:0 userInteractEnable:NO text:@"删除" textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:nil normalImage:nil selectBackImage:nil];
            }
        }
        else
        {
            [temp.downloadedBottomView setMiddleBtnAtIndex:0 userInteractEnable:NO text:@"删除" textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:nil normalImage:nil selectBackImage:nil];
        }
    }
}

/**
 *  删除正在下载的数据
 */
- (void)deleteDownloadingCity:(AL_CityMapInfo *)cityInfo withTemp:(AL_SettingDataManagementViewController *)temp
{
    [[AL_MapDownloadManager shareInstance] deleteDownloadData:cityInfo];

    [temp.downloadingTableView.tableView reloadData];
    
    if ([AL_MapDownloadManager shareInstance].arrayDownloadingList.count==0)
    {
        temp.isDownloadingCanDelete = NO;
        
        [temp.downloadingBottomView setMiddleBtnAtIndex:1 userInteractEnable:NO text:LOCALIZESTR(@"AL_Setting_Delete", @"AL_SettingStr") textColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] selectedTextColor:[UIColor colorWithRed:141.0/255 green:141.0/255 blue:139.0/255 alpha:1.0f] normalImage:nil selectBackImage:nil];
        temp.downloadingBottomView.hidden = _M_DeviceOrientation == 0 ? YES : NO;
        
        temp.btnDowningDelect.hidden = NO;
        [temp.btnDowningDelect setImage:[UIImage imageNamed:@"icn_顶栏_垃圾桶_C.png"] forState:UIControlStateNormal];
        temp.btnDowningDelect.userInteractionEnabled = NO;
    }
}

/**
 *  中文排序
 */
- (void)sortByHeaderChracter:(NSMutableArray *)newArray
{
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"szEnName"ascending:YES]];
    [newArray sortUsingDescriptors:sortDescriptors];
}

- (void)popWithTemp:(AL_SettingDataManagementViewController *)temp
{
    if (temp.isNeedToDownloadBaseData && [[AL_MapDownloadManager shareInstance] isHasBaseMapData])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PopFromDataManagermentViewController" object:nil];
    }
    [temp.navigationController popViewControllerAnimated:YES];
}

- (void)popToRootWithTemp:(AL_SettingDataManagementViewController *)temp
{
    if (temp.isNeedToDownloadBaseData && [[AL_MapDownloadManager shareInstance] isHasBaseMapData])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PopFromDataManagermentViewController" object:nil];
        [temp.navigationController popViewControllerAnimated:YES];
    }
    else if (temp.isNeedToDownloadBaseData)
    {
        [temp.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [temp.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)checkToAutoDownload:(AL_SettingDataManagementViewController *)temp
{
    if (![[AL_MapDownloadManager shareInstance] isHasBaseMapData])
    {
        temp.adminToDownload = @"0";
    }
    
    if (temp.adminToDownload)
    {
        AL_CityMapInfo* currentCityInfo = nil;
        NSArray* arrayOfCities = [AL_MapDownloadManager shareInstance].arrayCitiesListFromServer;
        for (AL_CityMapInfo* cityInfo in arrayOfCities)
        {
            if ([cityInfo.szCityCode isEqualToString:temp.adminToDownload])
            {
                currentCityInfo = cityInfo;
                break;
            }
            else if (cityInfo.arrayOfSubCities!=nil)
            {
                for (AL_CityMapInfo* subCityInfo in cityInfo.arrayOfSubCities)
                {
                    if ([subCityInfo.szCityCode isEqualToString:temp.adminToDownload])
                    {
                        currentCityInfo = subCityInfo;
                        break;
                    }
                }
                if (currentCityInfo!=nil)
                {
                    break;
                }
            }
        }
        if (currentCityInfo!=nil)
        {
            [temp allTableViewDownloadCity:currentCityInfo withTemp:temp];
        }
    }
}

#pragma mark
#pragma mark TextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self performSelector:@selector(replaceTextFieldText) withObject:nil afterDelay:0.1f];
    return YES;
}

- (void)replaceTextFieldText
{
    NSString *text = _textFieldProvince.text;
    if (_textFieldProvince.text.length>16)
    {
        NSString *tempStr = [text substringWithRange:NSMakeRange(0, 15)];
        _textFieldProvince.text = [NSString stringWithFormat:@"%@%@",tempStr,[text substringWithRange:NSMakeRange(16, 1)]];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_textFieldProvince.text.length>0)
    {
        AL_SettingDataSeachViewController *viewController = [[AL_SettingDataSeachViewController alloc] init];
        [viewController setSearchStr:_textFieldProvince.text];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }
    else
    {
        AT_AlertView *alert = [AT_AlertView showAlertWithMessage:@"请输入城市名称！"];
        [alert dismissAfterDelay:3.0f];
    }
    
    [textField resignFirstResponder];
    
    return YES;
}



#pragma mark - 内存
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    RELEASEOBJECT(_allTableView);
    RELEASEOBJECT(_downloadingTableView);
    RELEASEOBJECT(_downloadedTableView);
    RELEASEOBJECT(_textFieldProvince);
    RELEASEOBJECT(_btnLineLabel);
    
    RELEASEOBJECT(_mainScrollView);
    RELEASEOBJECT(_allTableShowArray);
    RELEASEOBJECT(_downloadedTableShowArray);
    RELEASEOBJECT(_downloadedCityInfoArray);
    RELEASEOBJECT(_shouldDownloadCityArray);
    
    [super dealloc];
}







@end
