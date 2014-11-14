//
//  LMROMBrowserController.h
//  MeSNEmu
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMFileListItem;

@interface LMROMBrowserController : UIViewController <UITableViewDelegate,UITableViewDataSource,UISearchDisplayDelegate>
{
  UITableViewStyle tableViewStyle;
  UITableView* _tableView;
  
  LMFileListItem* _detailsItem;
  NSString* _romPath;
  NSString* _sramPath;
  
  NSArray* _romList;
  NSArray* _sectionTitles;
  NSArray* _sectionMarkers;
  
  NSArray* _filteredRomList;
  NSArray* _filteredSectionTitles;
  NSArray* _filteredSectionMarkers;
}

@property (nonatomic, retain) UITableView *tableView;
@property (retain) LMFileListItem* detailsItem;

- (id)initWithStyle:(UITableViewStyle)theStyle;

@end
