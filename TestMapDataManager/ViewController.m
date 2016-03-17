//
//  ViewController.m
//  TestMapDataManager
//
//  Created by autonavi\wang.weiyang on 6/27/15.
//  Copyright (c) 2015 autonavi. All rights reserved.
//

#import "ViewController.h"
#import "AL_MapDownloadManager.h"
#import "CityItemTableViewCell.h"
#import "DownloadingItemTableViewCell.h"
#import "DownloadedItemTableViewCell.h"

#define AppWidth 320
#define AppHeight 480

typedef NS_ENUM(NSInteger, TableType) {
    TableTypeDownloading = 0,
    TableTypeDownloaded = 1,
    TableTypeCity = 2
};

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, AL_MapDownloadManagerDelegate>

@property (nonatomic, strong) UITableView *cityTableView;
@property (nonatomic, strong) UITableView *downloadingTableView;
@property (nonatomic, strong) UITableView *downloadedTableView;

@property (nonatomic, strong) UIButton *cityBtn;
@property (nonatomic, strong) UIButton *downloadingBtn;
@property (nonatomic, strong) UIButton *downloadedBtn;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) UIButton *startAllBtn;
@property (nonatomic, strong) UIButton *pauseAllBtn;

@property (nonatomic, assign) TableType tableType;

@property (nonatomic, strong) NSMutableArray *cityExpandArray;
@property (nonatomic, strong) NSMutableDictionary *downloadedExpandDictionary;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[AL_MapDownloadManager shareInstance] setDelegate:self];
    
    self.tableType = TableTypeCity;
    
    self.downloadingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadingBtn setTitle:@"下载列表" forState:UIControlStateNormal];
    [self.downloadingBtn setFrame:CGRectMake(0, 64, AppWidth / 3, 44)];
    [self.downloadingBtn addTarget:self action:@selector(downloadingBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.downloadingBtn];
    
    self.downloadedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadedBtn setTitle:@"已下载" forState:UIControlStateNormal];
    [self.downloadedBtn setFrame:CGRectMake(AppWidth / 3, 64, AppWidth / 3, 44)];
    [self.downloadedBtn addTarget:self action:@selector(downloadedBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.downloadedBtn];
    
    self.cityBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cityBtn setTitle:@"城市列表" forState:UIControlStateNormal];
    [self.cityBtn setFrame:CGRectMake(AppWidth * 2 / 3, 64, AppWidth / 3, 44)];
    [self.cityBtn addTarget:self action:@selector(cityBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.cityBtn setEnabled:NO];
    [self.view addSubview:self.cityBtn];
    
    self.downloadingTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 108, AppWidth, AppHeight - 152) style:UITableViewStylePlain];
    [self.downloadingTableView setDelegate:self];
    [self.downloadingTableView setDataSource:self];
    [self.downloadingTableView setHidden:YES];
    [self.view addSubview:self.downloadingTableView];
    
    self.downloadedTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 108, AppWidth, AppHeight - 108) style:UITableViewStylePlain];
    [self.downloadedTableView setDelegate:self];
    [self.downloadedTableView setDataSource:self];
    [self.downloadedTableView setHidden:YES];
    [self.view addSubview:self.downloadedTableView];
    
    self.cityTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 108, AppWidth, AppHeight - 108) style:UITableViewStylePlain];
    [self.cityTableView setDelegate:self];
    [self.cityTableView setDataSource:self];
    [self.view addSubview:self.cityTableView];
//    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
//    [self.deleteBtn setFrame:CGRectMake(0, AppHeight - 44, AppWidth / 3, 44)];
//    [self.deleteBtn addTarget:self action:@selector(cityBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.deleteBtn];
//    
//    self.startAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.startAllBtn setTitle:@"全部开始" forState:UIControlStateNormal];
//    [self.startAllBtn setFrame:CGRectMake(AppWidth / 3, AppHeight - 44, AppWidth / 3, 44)];
//    [self.startAllBtn addTarget:self action:@selector(cityBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.startAllBtn];
//    
//    self.pauseAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.pauseAllBtn setTitle:@"全部暂停" forState:UIControlStateNormal];
//    [self.pauseAllBtn setFrame:CGRectMake(AppWidth * 2 / 3, AppHeight - 44, AppWidth / 3, 44)];
//    [self.pauseAllBtn addTarget:self action:@selector(cityBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:self.pauseAllBtn];
    
//    [self performSelector:@selector(startDownloadBaseResource) withObject:nil afterDelay:5];
    
    
    [[AL_MapDownloadManager shareInstance] requestCities:^{
        self.cityExpandArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [AL_MapDownloadManager shareInstance].cities.count + 1; i++) {
            [self.cityExpandArray addObject:[NSNumber numberWithBool:NO]];
        }
        
        self.downloadedExpandDictionary = [[NSMutableDictionary alloc] init];
        
        [self.cityTableView reloadData];
        [self.downloadingTableView reloadData];
        [self.downloadedTableView reloadData];
    }];
}

- (IBAction)downloadingBtnPressed:(id)sender{
    self.tableType = TableTypeDownloading;
    [self.cityBtn setEnabled:YES];
    [self.downloadedBtn setEnabled:YES];
    [self.downloadingBtn setEnabled:NO];
    
    [self.cityTableView setHidden:YES];
    [self.downloadedTableView setHidden:YES];
    [self.downloadingTableView setHidden:NO];
    
    [self.downloadingTableView reloadData];
}

- (IBAction)downloadedBtnPressed:(id)sender{
    self.tableType = TableTypeDownloaded;
    [self.cityBtn setEnabled:YES];
    [self.downloadedBtn setEnabled:NO];
    [self.downloadingBtn setEnabled:YES];
    
    [self.cityTableView setHidden:YES];
    [self.downloadedTableView setHidden:NO];
    [self.downloadingTableView setHidden:YES];
    
    [self.downloadedTableView reloadData];
}

- (IBAction)cityBtnPressed:(id)sender{
    self.tableType = TableTypeCity;
    [self.cityBtn setEnabled:NO];
    [self.downloadedBtn setEnabled:YES];
    [self.downloadingBtn setEnabled:YES];
    
    [self.cityTableView setHidden:NO];
    [self.downloadedTableView setHidden:YES];
    [self.downloadingTableView setHidden:YES];
    
    [self.cityTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.tableType == TableTypeDownloading) {
        return 1;
    } else if (self.tableType == TableTypeDownloaded){
        return [AL_MapDownloadManager shareInstance].downloadedItems.count;
    } else if (self.tableType == TableTypeCity){
        return [AL_MapDownloadManager shareInstance].cities.count + 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.tableType == TableTypeDownloading) {
        return [AL_MapDownloadManager shareInstance].downloadingItems.count;
    } else if (self.tableType == TableTypeDownloaded){
        AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].downloadedItems objectAtIndex:section];
        NSNumber *expandNum = [self.downloadedExpandDictionary objectForKey:city.szCityCode];
        if (expandNum == nil || [expandNum integerValue] == 0) {
            [self.downloadedExpandDictionary setObject:@0 forKey:city.szCityCode];
            return 1;
        }
        if (city.downloadedCities.count > 0) {
            return city.downloadedCities.count + 1;
        }else{
            return 1;
        }
    } else if (self.tableType == TableTypeCity){
        BOOL isExpand = [[self.cityExpandArray objectAtIndex:section] boolValue];
        if (isExpand) {
            AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].cities objectAtIndex:section - 1];
            return city.arrayOfSubCities.count + 1;
        }else{
            return 1;
        }
    }
    return 0;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger row = [indexPath row];
    if (row == 0) {
        return 0;
    }else{
        if (self.tableType == TableTypeDownloading) {
            return 0;
        }else{
            return 2;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.tableType == TableTypeDownloading) {
        static NSString *cellIdentifier = @"downloadingcell";
        DownloadingItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(!cell){
            cell = [[DownloadingItemTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].downloadingItems objectAtIndex:[indexPath row]];
        [cell setCity:city];
        return cell;
    } else if (self.tableType == TableTypeDownloaded){
        static NSString *cellIdentifier = @"downloadedcell";
        DownloadedItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(!cell){
            cell = [[DownloadedItemTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].downloadedItems objectAtIndex:[indexPath section]];
        if ([indexPath section] == 0) {
            [cell setCity:city];
        }else{
            if ([indexPath row] == 0) {
                [cell setCity:city];
                return cell;
            }else{
                AL_CityMapInfo *subCity = [city.downloadedCities objectAtIndex:([indexPath row] - 1)];
                
                [cell setCity:subCity];
                return cell;
            }
        }
        return cell;
    } else if (self.tableType == TableTypeCity){
        static NSString *cellIdentifier = @"citycell";
        //首先根据标识去缓存池取
        CityItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        //如果缓存池没有到则重新创建并放到缓存池中
        if(!cell){
            cell = [[CityItemTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        if ([indexPath section] == 0) {
            AL_CityMapInfo *city = [AL_MapDownloadManager shareInstance].baseMapInfo;
            
            [cell setCity:city];
            return cell;
        }else{
            AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].cities objectAtIndex:([indexPath section] - 1)];
            
            if ([indexPath row] == 0) {
                [cell setCity:city];
                return cell;
            }else{
                AL_CityMapInfo *subCity = [city.arrayOfSubCities objectAtIndex:([indexPath row] - 1)];
                
                [cell setCity:subCity];
                return cell;
            }
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.tableType == TableTypeDownloading) {
        
    } else if (self.tableType == TableTypeDownloaded){
        if ([indexPath section] > 0 && [indexPath row] == 0) {
            AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].downloadedItems objectAtIndex:([indexPath section])];
            
            NSNumber *expandNum = [self.downloadedExpandDictionary objectForKey:city.szCityCode];
            if (city.downloadedCities.count > 0) {
                if (expandNum == nil || [expandNum integerValue] == 0) {
                    [self.downloadedExpandDictionary setObject:@1 forKey:city.szCityCode];
                }else{
                    [self.downloadedExpandDictionary setObject:@0 forKey:city.szCityCode];
                }
                [tableView reloadData];
            }
        }
    } else if (self.tableType == TableTypeCity){
        if ([indexPath section] > 0 && [indexPath row] == 0) {
            AL_CityMapInfo *city = [[AL_MapDownloadManager shareInstance].cities objectAtIndex:([indexPath section] - 1)];
            BOOL isExpand = [[self.cityExpandArray objectAtIndex:[indexPath section]] boolValue];
            if (city.arrayOfSubCities && city.arrayOfSubCities.count > 0) {
                [self.cityExpandArray replaceObjectAtIndex:[indexPath section] withObject:[NSNumber numberWithBool:!isExpand]];
                [tableView reloadData];
            }
        }
    }
}

- (void)mapDownloadManagerDownloadQueueChanged:(AL_MapDownloadManager *)mapDownloadManager{
    if (self.tableType == TableTypeDownloading) {
        [self.downloadingTableView reloadData];
    } else if (self.tableType == TableTypeDownloaded) {
        [self.downloadedTableView reloadData];
    } else if (self.tableType == TableTypeCity) {
        
    }
}

@end
