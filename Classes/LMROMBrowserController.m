//
//  LMROMBrowserController.m
//  MeSNEmu
//
//  Created by Lucas Menge on 1/3/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#import "LMROMBrowserController.h"

#import "../SNES9XBridge/Snes9xMain.h"

#import "LMEmulatorController.h"
#import "LMSaveManager.h"
#import "LMSettingsController.h"
#include <stdlib.h>

static NSString* const LMFileOrganizationVersion = @"LMFileOrganizationVersion";
static int const LMFileOrganizationVersionNumber = 1;

@interface LMFileListItem : NSObject
{
  BOOL _hasDetails;
  NSString* _displayName;
  NSString* _displayDetails;
  NSString* _fileName;
  NSMutableArray* _imageFilePaths;
  NSDictionary* _romInfo;
}

@property BOOL hasDetails;
@property (retain) NSString* displayName;
@property (retain) NSString* displayDetails;
@property (retain) NSString* fileName;
@property (retain) NSMutableArray* imageFilePaths;
@property (retain) NSDictionary* romInfo;

+ (BOOL)isROMExtension:(NSString*)lowerCaseExtension;
@end

#pragma mark -

@implementation LMFileListItem

@synthesize hasDetails = _hasDetails;
@synthesize displayName = _displayName;
@synthesize displayDetails = _displayDetails;
@synthesize fileName = _fileName;
@synthesize imageFilePaths = _imageFilePaths;

+ (BOOL)isROMExtension:(NSString*)lowerCaseExtension
{
  if(lowerCaseExtension != nil
     && ([lowerCaseExtension compare:@"smc"] == NSOrderedSame
         || [lowerCaseExtension compare:@"sfc"] == NSOrderedSame
         || [lowerCaseExtension compare:@"zip"] == NSOrderedSame))
    return YES;
  return NO;
}

- (void)dealloc
{
  self.displayName = nil;
  self.displayDetails = nil;
  self.fileName = nil;
  self.imageFilePaths = nil;
  [super dealloc];
}

- (NSComparisonResult)compareByDisplayName:(LMFileListItem*)fileListItem
{
  return [[self.displayName uppercaseString] compare:[fileListItem.displayName uppercaseString]];
}

@end

#pragma mark -

@interface LMROMBrowserController(Privates) <UISearchDisplayDelegate>

@end

#pragma mark -

@implementation LMROMBrowserController(Privates)

- (void)LM_moveLegacyFilesToDocumentsFolder
{
  NSFileManager* fm = [NSFileManager defaultManager];
  // SRAM
  NSString* sramPath = [_romPath stringByAppendingPathComponent:@"SRAM"];
  if([sramPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* sramList = [fm contentsOfDirectoryAtPath:sramPath error:nil];
    for(NSString* file in sramList)
      [fm moveItemAtPath:[sramPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:sramPath error:nil];
  }
  // Saves
  NSString* savesPath = [LMSaveManager legacy_pathForSaveStates];
  if([savesPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* savesList = [fm contentsOfDirectoryAtPath:savesPath error:nil];
    for(NSString* file in savesList)
      [fm moveItemAtPath:[savesPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:savesPath error:nil];
  }
  
  // Running Saves
  NSString* runningSavesPath = [LMSaveManager legacy_pathForRunningStates];
  if([runningSavesPath compare:_romPath] != NSOrderedSame)
  {
    NSArray* runningSavesList = [fm contentsOfDirectoryAtPath:runningSavesPath error:nil];
    for(NSString* file in runningSavesList)
      [fm moveItemAtPath:[runningSavesPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:file] error:nil];
    [fm removeItemAtPath:runningSavesPath error:nil];
  }
  
  // renaming saves .### to .###.frz
  NSArray* fileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
  for(NSString* file in fileList)
  {
    NSString* extension = [file pathExtension];
    if([extension length] == 3)
    {
      unichar char0 = [extension characterAtIndex:0];
      unichar char1 = [extension characterAtIndex:1];
      unichar char2 = [extension characterAtIndex:2];
      if(char0 >= '0' && char0 <= '9'
         && char1 >= '0' && char1 <= '9'
         && char2 >= '0' && char2 <= '9')
      {
        [fm moveItemAtPath:[_romPath stringByAppendingPathComponent:file] toPath:[_romPath stringByAppendingPathComponent:[file stringByAppendingPathExtension:@"frz"]] error:nil];
      }
    }
  }
  
  [[NSUserDefaults standardUserDefaults] setInteger:LMFileOrganizationVersionNumber forKey:LMFileOrganizationVersion];
}

- (NSArray*)LM_relatedFilesForROMNamed:(NSString*)romName
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSArray* filesList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
  NSMutableArray* list = [NSMutableArray array];
  NSString* romNameWithoutExtension = [romName stringByDeletingPathExtension];
  for(NSString* file in filesList)
  {
    if([file rangeOfString:romNameWithoutExtension].location == 0)
    {
      NSString* extension = [[file pathExtension] lowercaseString];
      if([LMFileListItem isROMExtension:extension] == YES)
        [list addObject:file];
      else if([extension compare:@"srm"] == NSOrderedSame)
        [list addObject:file];
      else if([extension compare:@"frz"] == NSOrderedSame)
        [list addObject:file];
    }
  }
  return [[list copy] autorelease];
}

- (void)LM_reloadROMList:(BOOL)updateTable
{
  if([[NSUserDefaults standardUserDefaults] integerForKey:LMFileOrganizationVersion] != LMFileOrganizationVersionNumber)
    [self LM_moveLegacyFilesToDocumentsFolder];
  
  BOOL searching = self.searchDisplayController.isActive;
  NSString* filterString = self.searchDisplayController.searchBar.text;
  
  NSFileManager* fm = [NSFileManager defaultManager];
  
  // copy all ROMs from the Inbox to the documents folder
  NSString* inboxPath = [_romPath stringByAppendingPathComponent:@"Inbox"];
  NSArray* filesInInbox = [fm contentsOfDirectoryAtPath:inboxPath error:nil];
  for(NSString* file in filesInInbox)
  {
    NSString* sourcePath = [inboxPath stringByAppendingPathComponent:file];
    NSString* targetPath = [_romPath stringByAppendingPathComponent:file];
    // avoid overwriting existing files
    int i = 1;
    while([fm fileExistsAtPath:targetPath] == YES)
    {
      targetPath = [[[targetPath stringByDeletingPathExtension] stringByAppendingFormat:@" %i", i] stringByAppendingPathExtension:[sourcePath pathExtension]];
      i++;
    }
    // actually move item
    [fm moveItemAtPath:sourcePath toPath:targetPath error:nil];
  }
  [fm removeItemAtPath:inboxPath error:nil];
  
  // list all ROMs in the documents folder
  BOOL isROMDetail = (_detailsItem != nil);
  NSArray* tempItemList = nil;
  NSMutableArray* tempSectionTitles = nil;
  NSMutableArray* tempSectionMarkers = nil;
  if(isROMDetail == NO)
  {
    // listing all ROMs
    NSArray* proposedFileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
    NSMutableArray* onlyROMsItemList = [NSMutableArray array];
    for(NSString* file in proposedFileList)
    {
      NSString* extension = [[file pathExtension] lowercaseString];
      if([LMFileListItem isROMExtension:extension] == YES)
      {
        LMFileListItem* item = [[LMFileListItem alloc] init];
        item.displayName = [file stringByDeletingPathExtension];
        item.fileName = file;
        item.displayDetails = @"-";
        item.imageFilePaths = [NSMutableArray array];
        NSString* sramPath = [_sramPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"srm"]];
        if([fm fileExistsAtPath:sramPath] == YES)
          item.hasDetails = YES;
        for(NSString* file2 in proposedFileList)
        {
          NSString* extension2 = [[file2 pathExtension] lowercaseString];
          if([file2 hasPrefix:[item.displayName stringByAppendingString:@"."]] && [extension2 compare:@"frz"] == NSOrderedSame)
          {
            item.hasDetails = YES;
            int slot = [[[file2 stringByDeletingPathExtension] pathExtension] integerValue];
            if (slot == 0)
            {
              NSDictionary *attribute = [fm attributesOfItemAtPath:[_romPath stringByAppendingPathComponent:file2] error:nil];
              NSDate *mdate = [attribute objectForKey:NSFileModificationDate];
              NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
              [dateFormatter setDateStyle:NSDateFormatterShortStyle];
              [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
              
              BOOL(^isSameDay)(NSDate*,NSDate*) = ^BOOL(NSDate*date1,NSDate*date2){
                NSCalendar* calendar = [NSCalendar currentCalendar];
                NSDateComponents* c1 = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date1];
                NSDateComponents* c2 = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date2];
                return ([c1 year] == [c2 year] && [c1 month] == [c2 month] && [c1 day] == [c2 day]);
              };
              if(isSameDay([NSDate date],mdate) ||
                 isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400],mdate))
              {
                dateFormatter.doesRelativeDateFormatting = YES;
                item.displayDetails = [dateFormatter stringFromDate:mdate];
              }
              else if(isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*2],mdate))
              {
                dateFormatter.doesRelativeDateFormatting = YES;
                [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
                item.displayDetails = [dateFormatter stringFromDate:mdate];
              }
              else if(isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*3],mdate) ||
                      isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*4],mdate) ||
                      isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*5],mdate) ||
                      isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*6],mdate) ||
                      isSameDay([NSDate dateWithTimeIntervalSinceNow:-86400*7],mdate))
              {
                [dateFormatter setDateFormat:@"EEEE"];
                item.displayDetails = [dateFormatter stringFromDate:mdate];
              }
              else
              {
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
                item.displayDetails = [dateFormatter stringFromDate:mdate];
              }
              
              NSString* imagePath = [_romPath stringByAppendingPathComponent:[[file2 stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
              if([fm fileExistsAtPath:imagePath] == YES)
              {
                [item.imageFilePaths addObject:imagePath];
              }
              break;
            }
          }
        }
        [onlyROMsItemList addObject:item];
        [item release];
      }
    }
    proposedFileList = [onlyROMsItemList sortedArrayUsingSelector:@selector(compareByDisplayName:)];
    
    // sort symbols first
    NSMutableArray* symbolsList = [NSMutableArray array];
    NSMutableArray* alphabetList = [NSMutableArray array];
    for(LMFileListItem* file in proposedFileList)
    {
      unichar firstLetter = [[file.displayName uppercaseString] characterAtIndex:0];
      if(firstLetter < 'A' || firstLetter > 'Z')
        [symbolsList addObject:file];
      else
        [alphabetList addObject:file];
    }
    [symbolsList addObjectsFromArray:alphabetList];
    proposedFileList = symbolsList;
    
    // build sections and real file names
    NSMutableArray* tempRomList = [NSMutableArray array];
    tempSectionTitles = [NSMutableArray array];
    tempSectionMarkers = [NSMutableArray array];
    unichar lastChar = '\0';
    for(LMFileListItem* file in proposedFileList)
    {
      if(searching == YES && [file.fileName rangeOfString:filterString options:NSCaseInsensitiveSearch].location == NSNotFound)
        continue;
      
      unichar firstLetter = [[file.displayName uppercaseString] characterAtIndex:0];
      if(firstLetter < 'A' || firstLetter > 'Z')
        firstLetter = '#';
      if(firstLetter != lastChar)
      {
        lastChar = firstLetter;
        [tempSectionTitles addObject:[NSString stringWithCharacters:&lastChar length:1]];
        [tempSectionMarkers addObject:[NSNumber numberWithInt:[tempRomList count]]];
      }
      [tempRomList addObject:file];
    }
    tempItemList = tempRomList;
  }
  else
  {
    NSMutableArray* itemsList = [NSMutableArray array];
    tempSectionTitles = [NSMutableArray array];
    tempSectionMarkers = [NSMutableArray array];
    // rom item
    NSString* romPath = [_romPath stringByAppendingPathComponent:_detailsItem.fileName];
    if([fm fileExistsAtPath:romPath] == YES)
    {
      [tempSectionTitles addObject:NSLocalizedString(@"CARTRIDGE_FILES", nil)];
      [tempSectionMarkers addObject:[NSNumber numberWithInt:[itemsList count]]];
      LMFileListItem* romData = [[LMFileListItem alloc] init];
      romData.fileName = _detailsItem.fileName;
      romData.displayName = [NSString stringWithFormat:
                             @"%@, %@, %@, %@, %@",
                             _detailsItem.romInfo[@"Cart Name"],
                             //_detailsItem.romInfo[@"Contents"],
                             _detailsItem.romInfo[@"Size (calculated)"],
                             _detailsItem.romInfo[@"Revision"],
                             _detailsItem.romInfo[@"Licensee"],
                             _detailsItem.romInfo[@"Region"]];
      [itemsList addObject:romData];
      [romData release];
      
    }
    // sram
    NSString* sramPath = [_sramPath stringByAppendingPathComponent:[[_detailsItem.fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"srm"]];
    if([fm fileExistsAtPath:sramPath] == YES)
    {
      LMFileListItem* sramItem = [[LMFileListItem alloc] init];
      sramItem.displayName = NSLocalizedString(@"SRAM_FILE", nil);
      sramItem.fileName = [sramPath lastPathComponent];
      sramItem.displayDetails = sramItem.fileName;
      sramItem.imageFilePaths = [NSMutableArray array];
      [itemsList addObject:sramItem];
      [sramItem release];
    }
    // saves
    BOOL hasSaves = NO;
    NSArray* proposedFileList = [fm contentsOfDirectoryAtPath:_romPath error:nil];
    for(NSString* file in proposedFileList)
    {
      NSString* extension = [[file pathExtension] lowercaseString];
      if([file hasPrefix:[_detailsItem.displayName stringByAppendingString:@"."]] && [extension compare:@"frz"] == NSOrderedSame)
      {
        if(hasSaves == NO)
        {
          [tempSectionTitles addObject:NSLocalizedString(@"SAVE_POINTS", nil)];
          [tempSectionMarkers addObject:[NSNumber numberWithInt:[itemsList count]]];
          hasSaves = YES;
        }
        LMFileListItem* saveItem = [[LMFileListItem alloc] init];
        saveItem.imageFilePaths = [NSMutableArray array];
        int slot = [[[file stringByDeletingPathExtension] pathExtension] integerValue];
        if(slot == 0)
          saveItem.displayName = NSLocalizedString(@"LAST_PLAYED_SPOT", nil);
        else if (slot<=999)
          saveItem.displayName = [NSString stringWithFormat:NSLocalizedString(@"SAVE_FILE_SLOT_%i", nil), slot];
        else {
          NSDate* date = [[NSDate alloc] initWithTimeIntervalSince1970:slot];
          saveItem.displayName = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
          [date release];
        }
        
        saveItem.fileName = file;
        saveItem.displayDetails = saveItem.fileName;
        NSString* imagePath = [_romPath stringByAppendingPathComponent:[[file stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        if([fm fileExistsAtPath:imagePath] == YES)
        {
          [saveItem.imageFilePaths addObject:imagePath];
          if (![_detailsItem.imageFilePaths containsObject:imagePath]) {
            [_detailsItem.imageFilePaths addObject:imagePath];
          }
        }
        [itemsList addObject:saveItem];
        [saveItem release];
      }
    }
    
    tempItemList = itemsList;
  }
  
  if(searching == YES)
  {
    [_filteredRomList release];
    _filteredRomList = [tempItemList copy];
    [_filteredSectionTitles release];
    _filteredSectionTitles = [tempSectionTitles copy];
    [_filteredSectionMarkers release];
    _filteredSectionMarkers = [tempSectionMarkers copy];
  }
  else
  {
    [_romList release];
    _romList = [tempItemList copy];
    [_sectionTitles release];
    _sectionTitles = [tempSectionTitles copy];
    [_sectionMarkers release];
    _sectionMarkers = [tempSectionMarkers copy];
    if(updateTable == YES)
      [self.tableView reloadData];
  }
}

- (void)LM_settingsTapped
{
  LMSettingsController* c = [[LMSettingsController alloc] init];
  UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:c];
  n.modalPresentationStyle = UIModalPresentationFormSheet;
  [self presentViewController:n animated:YES completion:nil];
  [c release];
  [n release];
}

- (LMFileListItem*)LM_romItemForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath
{
  int index = indexPath.row;
  if(tableView == self.searchDisplayController.searchResultsTableView)
  {
    index += [[_filteredSectionMarkers objectAtIndex:indexPath.section] intValue];
    return [_filteredRomList objectAtIndex:index];
  }
  else
  {
    index += [[_sectionMarkers objectAtIndex:indexPath.section] intValue];
    return [_romList objectAtIndex:index];
  }
}

#pragma mark UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
  [self LM_reloadROMList:NO];
  return YES;
}

@end

#pragma mark -

@implementation LMROMBrowserController

@synthesize detailsItem = _detailsItem;

@end

#pragma mark -

@implementation LMROMBrowserController(UITableViewController)

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
  if(_detailsItem != nil)
    return nil;
  
  NSMutableArray *ary = [NSMutableArray array];
  [ary addObject:UITableViewIndexSearch];
  
  if(tableView == self.searchDisplayController.searchResultsTableView)
    [ary addObjectsFromArray:_filteredSectionTitles];
  else
    [ary addObjectsFromArray:_sectionTitles];
  
  return ary;
}

- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
  if (index == 0) {
    CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
    [tableView scrollRectToVisible:searchBarFrame animated:NO];
    return -1;
  }
  
  return index;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
  // Return the number of sections.
  if(tableView == self.searchDisplayController.searchResultsTableView)
    return [_filteredSectionTitles count];
  else
    return [_sectionTitles count];
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  if(tableView == self.searchDisplayController.searchResultsTableView)
    return [_filteredSectionTitles objectAtIndex:section];
  else
    return [_sectionTitles objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  int sectionStart, sectionEnd;
  if(tableView == self.searchDisplayController.searchResultsTableView)
  {
    sectionStart = [[_filteredSectionMarkers objectAtIndex:section] intValue];
    sectionEnd = [_filteredRomList count];
    if(section < [_filteredSectionMarkers count]-1)
      sectionEnd = [[_filteredSectionMarkers objectAtIndex:(section+1)] intValue];
  }
  else
  {
    sectionStart = [[_sectionMarkers objectAtIndex:section] intValue];
    sectionEnd = [_romList count];
    if(section < [_sectionMarkers count]-1)
      sectionEnd = [[_sectionMarkers objectAtIndex:(section+1)] intValue];
  }
  
  return sectionEnd-sectionStart;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  cell.textLabel.text = item.displayName;
  cell.detailTextLabel.text = item.displayDetails;
  cell.accessoryType = UITableViewCellAccessoryNone;
	
  if([item.imageFilePaths count]>0) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      UIImage* image = [UIImage imageWithContentsOfFile:[item.imageFilePaths objectAtIndex:0]];
      dispatch_async(dispatch_get_main_queue(), ^{
        cell.imageView.image = image;
        [cell setNeedsLayout];
      });
    });
  } else {
    cell.imageView.image = nil;
  }
  
  return cell;
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
  LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  if(_detailsItem == nil)
    emulator.romFileName = item.fileName;
  else
  {
    emulator.romFileName = _detailsItem.fileName;
    NSString* extension = [[item.fileName pathExtension] lowercaseString];
    if([LMFileListItem isROMExtension:extension] == YES)
    {
      // do nothing here either
    }
    else if([extension compare:@"srm"] == NSOrderedSame)
    {
      // do nothing here
    }
    else if([extension compare:@"frz"] == NSOrderedSame)
    {
      // load the selected save state
      emulator.initialSaveFileName = item.fileName;
    }
  }
  //[self.searchDisplayController setActive:NO];
  [self.navigationController presentViewController:emulator animated:YES completion:nil];
  [emulator release];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(_detailsItem == nil) {
    LMROMBrowserController* detailsBrowser = [[LMROMBrowserController alloc] initWithStyle:UITableViewStyleGrouped];
    LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
    detailsBrowser.detailsItem = item;
    
    const char* originalString = [item.fileName UTF8String];
    char* romFileNameCString = (char*)calloc(strlen(originalString)+1, sizeof(char));
    strcpy(romFileNameCString, originalString);
    originalString = nil;

    char* romInfoCString = (char*)calloc(1024, sizeof(char));
    SIMakeRomInfoText(romFileNameCString, romInfoCString);

    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    NSArray* lines = [[NSString stringWithCString:romInfoCString encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
      NSArray *values = [line componentsSeparatedByString:@": "];
      [dic setObject:[[values objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
              forKey:[[values objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    item.romInfo = [dic copy];
    
    [self.navigationController pushViewController:detailsBrowser animated:YES];
    [detailsBrowser release];
  }
  else {
    [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
  }
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  if(editingStyle == UITableViewCellEditingStyleDelete)
  {
    // Delete the row from the data source
    int amount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
    NSString* extension = [[item.fileName pathExtension] lowercaseString];
    [[NSFileManager defaultManager] removeItemAtPath:[_romPath stringByAppendingPathComponent:item.fileName] error:nil];
    if ([extension compare:@"frz"] == NSOrderedSame && [item.imageFilePaths count]>0) {
      [[NSFileManager defaultManager] removeItemAtPath:[item.imageFilePaths objectAtIndex:0] error:nil];
    }
    [self LM_reloadROMList:NO];
    
    BOOL isROMDetail = (_detailsItem != nil);
    if(isROMDetail == YES)
    {
      if([_romList count] == 0
         || (indexPath.section == 0 && indexPath.row == 0))
      {
        [self.navigationController popViewControllerAnimated:YES];
        return;
      }
    }
    if(amount == 1)
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    else
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  LMFileListItem* item = [self LM_romItemForTableView:tableView indexPath:indexPath];
  if(_detailsItem == nil) {
    return 70.0;
  }
  else {
    if([item.imageFilePaths count]>0) {
      return 80.0;
    } else {
      return 44.0;
    }
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 34.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if(_detailsItem == nil) {
    UIView *view = [[[UIView alloc] init] autorelease];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 320, 34.0)];
    [label setText:[self tableView: tableView titleForHeaderInSection: section]];
    [label setFont:[UIFont boldSystemFontOfSize:14]];
    [label setTextColor:[UIColor grayColor]];
    [view setBackgroundColor:[UIColor colorWithWhite:250/255.0 alpha:1.0]];
    [view addSubview:label];
    [label release];
    return view;
  }
  return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(_detailsItem != nil) {
    if (!(indexPath.row==0 && indexPath.section==0)) {
      return UITableViewCellEditingStyleDelete;
    }
  }
  return UITableViewCellEditingStyleNone;
}

@end

#pragma mark -

@interface LMROMBrowserListCell : UITableViewCell
@end

@implementation LMROMBrowserListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
  if (self) {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    CGFloat border = 1.0;
    CGFloat radius = 4.0;
    button.frame = CGRectMake(0, 0, 56, 26);
    button.tag = 100;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(button.frame.size.width, button.frame.size.height), NO, button.currentImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.0].CGColor);
    CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);
    CGContextSetLineWidth(context, border);
    
    CGRect rrect = CGRectMake(0, 0, button.frame.size.width, button.frame.size.height);
    CGFloat minx = CGRectGetMinX(rrect)+(border/2), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect)-(border/2);
    CGFloat miny = CGRectGetMinY(rrect)+(border/2), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect)-(border/2);
    
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextFillPath(context);
    [button setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(button.frame.size.width, button.frame.size.height), NO, button.currentImage.scale);
    CGContextRef context2 = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context2, self.tintColor.CGColor);
    CGContextSetStrokeColorWithColor(context2, self.tintColor.CGColor);
    CGContextSetLineWidth(context2, border);
    
    CGContextMoveToPoint(context2, minx, midy);
    CGContextAddArcToPoint(context2, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context2, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context2, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context2, minx, maxy, minx, midy, radius);
    CGContextClosePath(context2);
    CGContextDrawPath(context2, kCGPathFillStroke);
    CGContextFillPath(context2);
    [button setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateHighlighted];
    UIGraphicsEndImageContext();
    
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [button setTitleColor:self.tintColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button setTitle:NSLocalizedString(@"PLAY", nil) forState:UIControlStateNormal];
    [button setTitle:NSLocalizedString(@"PLAY", nil) forState:UIControlStateHighlighted];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(2, 0, 0, 0)];
    
    [button addTarget:self action:@selector(onTapPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:button];
    
    UILabel* label = [[[UILabel alloc] init] autorelease];
    label.tag = 101;
    label.text = NSLocalizedString(@"LAST_PLAYED_SPOT", nil);
    label.frame = CGRectMake(0, 0, 60, 16);
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor grayColor];
    [self addSubview:label];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  CGSize size = self.contentView.frame.size;
  UIButton* button = (UIButton*)[self viewWithTag:100];
  UILabel* label = (UILabel*)[self viewWithTag:101];
  
  button.frame = (CGRect){size.width-button.frame.size.width-10, 22, button.frame.size};
  self.imageView.frame = CGRectMake(16, 10, 57, 50);
  self.imageView.backgroundColor = [UIColor whiteColor];
  [self.textLabel setFont:[UIFont systemFontOfSize:14]];
  [self.textLabel setTextColor:[UIColor blackColor]];
  
  [self.detailTextLabel setFont:[UIFont systemFontOfSize:12]];
  [self.detailTextLabel setTextColor:self.tintColor];
  [self.detailTextLabel setTextAlignment:NSTextAlignmentLeft];
  self.textLabel.frame = CGRectMake(84, 10, size.width-80-10-(size.width-button.frame.origin.x), 30);
  [label sizeToFit];
  label.frame = CGRectMake(84, 40, label.frame.size.width, 16);
  self.detailTextLabel.frame = CGRectMake(84+label.frame.size.width+5, 40, self.textLabel.frame.size.width-(label.frame.size.width+5), 16);
  self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  self.backgroundColor = [UIColor clearColor];
  self.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
}

- (UIEdgeInsets)layoutMargins
{
  return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)onTapPlayButton:(id)sender
{
  if ([(id <UITableViewDelegate>)[(UITableView *)self.superview.superview delegate] respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
    [(id <UITableViewDelegate>)[(UITableView *)self.superview.superview delegate] tableView:(UITableView *)self.superview.superview
                                         accessoryButtonTappedForRowWithIndexPath:[(UITableView *)self.superview.superview indexPathForCell:self]];
  }
}

@end

#pragma mark -

@interface LMROMImageView : UIImageView
{
  BOOL isFadeAnimating;
}
- (void)startFadeAnimating;
- (void)stopFadeAnimating;

@end

@implementation LMROMImageView

- (void)startFadeAnimating:(NSNumber*)index
{
  if ([self.animationImages count]>0) {
    if ([index intValue]>0) {
      CATransition* transition = [CATransition animation];
      transition.duration = 2.0f;
      transition.type = kCATransitionFade;
      transition.removedOnCompletion = YES;
      [self.layer addAnimation:transition forKey:nil];
    }
    int n = ([self.animationImages count]<=[index intValue]) ? 0 : [index intValue];
    self.image = [self.animationImages objectAtIndex:n];
    if ([self.animationImages count]>1 && isFadeAnimating) {
      [self performSelector:@selector(startFadeAnimating:)
                 withObject:[NSNumber numberWithInt:n+1]
                 afterDelay:self.animationDuration/([self.animationImages count]-1)];
    }
  }
}

- (void)startFadeAnimating
{
  isFadeAnimating = YES;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  if ([self.animationImages count]>0) {
    [self startFadeAnimating:@0];
  }
}

- (void)stopFadeAnimating
{
  isFadeAnimating = NO;
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end

#pragma mark -

@implementation LMROMBrowserController(UIViewController)

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if(self)
  {
    // Custom initialization
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
#ifdef LM_LOADING_SCREENSHOTS
  return;
#endif
  
  if(_detailsItem == nil)
  {
    self.title = NSLocalizedString(@"ROMS", nil);
    
    UISearchBar* searchbar = [[UISearchBar alloc] init];
    [searchbar sizeToFit];
    [searchbar setSearchBarStyle:UISearchBarStyleMinimal];
    self.tableView.tableHeaderView = searchbar;
    [searchbar release];
    UISearchDisplayController* searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchbar contentsController:self];
    searchController.delegate = self;
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
    [self.tableView registerClass:[LMROMBrowserListCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView setBackgroundView:[UIView new]];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor colorWithWhite:255/255.0 alpha:0.5];
    self.tableView.sectionIndexTrackingBackgroundColor = [UIColor colorWithWhite:245/255.0 alpha:1.0];
    self.searchDisplayController.searchResultsTableView.separatorInset = UIEdgeInsetsZero;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
    footer.backgroundColor = [UIColor clearColor];
    footer.textColor = [UIColor grayColor];
    footer.font = [UIFont systemFontOfSize:18];
    footer.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = footer;
    [footer release];
  }
  else
  {
    UINavigationBar* navigationbar = (UINavigationBar*)[self.navigationController.navigationBar viewWithTag:1000];
    if (navigationbar==nil) {
      UINavigationBar* navigationbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, -100, self.navigationController.navigationBar.frame.size.width, 100)];
      navigationbar.tag = 1000;
      navigationbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth;
      navigationbar.backgroundColor = [UIColor clearColor];
      
      LMROMImageView* imageview = [[LMROMImageView alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, 100)];
      imageview.tag = 1001;
      imageview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      imageview.contentMode = UIViewContentModeScaleAspectFill;
      imageview.clipsToBounds = YES;
      imageview.layer.magnificationFilter = kCAFilterNearest;
      [navigationbar addSubview:imageview];
      [imageview release];
      
      UIImageView* gradientimageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, 100)];
      gradientimageview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      gradientimageview.contentMode = UIViewContentModeScaleAspectFill;
      gradientimageview.clipsToBounds = YES;
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(gradientimageview.frame.size.width, gradientimageview.frame.size.height), NO, gradientimageview.image.scale);
      CAGradientLayer *gradient = [CAGradientLayer layer];
      UIColor *startColor = [UIColor colorWithWhite:0 alpha:0];
      UIColor *endColor = [UIColor colorWithWhite:0 alpha:0.6];
      gradient.frame = CGRectMake(0, 0, gradientimageview.frame.size.width, gradientimageview.frame.size.height);
      gradient.colors = @[(id)startColor.CGColor,(id)endColor.CGColor];
      gradient.startPoint = CGPointMake(0.0f, 1.0f);
      gradient.endPoint = CGPointMake(1.0f, 1.0f);
      [gradientimageview.layer insertSublayer:gradient atIndex:0];
      [gradientimageview.layer renderInContext:UIGraphicsGetCurrentContext()];
      gradientimageview.image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      [gradient removeFromSuperlayer];
      [navigationbar addSubview:gradientimageview];
      [gradientimageview release];
      
      UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.navigationController.navigationBar.frame.size.width-20, 80)];
      label.tag = 1002;
      label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      label.font = [UIFont fontWithName:@"Helvetica-Bold" size:22];
      label.textColor = [UIColor whiteColor];
      label.textAlignment = NSTextAlignmentRight;
      label.numberOfLines = 2;
      [navigationbar addSubview:label];
      [label release];
      
      [self.navigationController.navigationBar insertSubview:navigationbar atIndex:0];
      [navigationbar release];
    }
    self.tableView.contentInset = UIEdgeInsetsMake(100, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(100, 0, 0, 0);
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
  }
  
  self.clearsSelectionOnViewWillAppear = NO;
  
  UIBarButtonItem* settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(LM_settingsTapped)];
  self.navigationItem.rightBarButtonItem = settingsButton;
  [settingsButton release];
  
  if(_romList != nil)
  {
    [_romList release];
    _romList = nil;
  }
  
  // documents folder
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* documentsPath = [paths objectAtIndex:0];
  
  // set it for the ROMs
  _romPath = [documentsPath copy];
  SISetSystemPath([_romPath UTF8String]);
  // and set it for SRAM
  _sramPath = [_romPath copy];
  SISetSRAMPath([_sramPath UTF8String]);
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
  [self LM_reloadROMList:YES];
  if(indexPath) {
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    dispatch_after(0, dispatch_get_main_queue(), ^{
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
  }
  
  if(_detailsItem == nil) {
    [(UILabel*)self.tableView.tableFooterView setText:[NSString stringWithFormat:@"%d %@",[_romList count], NSLocalizedString(@"ROMS", nil)]];
  }
  
  UINavigationBar* navigationbar = (UINavigationBar*)[self.navigationController.navigationBar viewWithTag:1000];
  if (navigationbar) {
    if(_detailsItem == nil) {
      LMROMImageView* imageview = (LMROMImageView*)[navigationbar viewWithTag:1001];
      [imageview stopFadeAnimating];
      
      [UIView animateWithDuration:0.3
                       animations:^{
                         navigationbar.frame = (CGRect){0, -navigationbar.frame.size.height-1, navigationbar.frame.size};
                       }];
    }
    else {
      UILabel* label = (UILabel*)[navigationbar viewWithTag:1002];
      LMROMImageView* imageview = (LMROMImageView*)[navigationbar viewWithTag:1001];
      
      NSShadow *shadow = [[NSShadow alloc] init];
      shadow.shadowOffset = CGSizeMake(0, 0.6f);
      shadow.shadowColor = [UIColor colorWithWhite:0 alpha:0.4];
      shadow.shadowBlurRadius = 3.0f;
      label.attributedText = [[NSAttributedString alloc] initWithString:_detailsItem.displayName
                                                             attributes:@{NSForegroundColorAttributeName:label.textColor,
                                                                          NSShadowAttributeName:shadow,
                                                                          NSKernAttributeName:@-1.0,
                                                                          NSFontAttributeName:label.font}];
      
      if([_detailsItem.imageFilePaths count]>0) {
        NSMutableArray *imagelist = [NSMutableArray array];
        for (id imagePath in _detailsItem.imageFilePaths) {
          UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
          CGImageRef cliped = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(arc4random_uniform(256-60), arc4random_uniform(224-60), 60, 60));
          [imagelist addObject:[UIImage imageWithCGImage:cliped]];
          CGImageRelease(cliped);
        }
        imageview.animationImages = imagelist;
        imageview.animationDuration = ([imagelist count]-1)*6;
        [imageview startFadeAnimating];
      } else {
        imageview.image = nil;
      }
      
      [UIView animateWithDuration:0.3
                       animations:^{
                         navigationbar.frame = (CGRect){0, self.navigationController.navigationBar.frame.size.height, navigationbar.frame.size};
                       }];
    }
  }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
  if(_detailsItem != nil) {
    UINavigationBar* navigationbar = (UINavigationBar*)[self.navigationController.navigationBar viewWithTag:1000];
    navigationbar.frame = (CGRect){0, self.navigationController.navigationBar.frame.size.height, navigationbar.frame.size};
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  if(_detailsItem != nil) {
    UINavigationBar* navigationbar = (UINavigationBar*)[self.navigationController.navigationBar viewWithTag:1000];
    LMROMImageView* imageview = (LMROMImageView*)[navigationbar viewWithTag:1001];
    [imageview stopFadeAnimating];
  }
}

- (BOOL)prefersStatusBarHidden
{
  return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  else
    return YES;
}

@end

#pragma mark -

@implementation LMROMBrowserController(NSObject)

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  //[self.searchDisplayController release];
  
  [_romList release];
  _romList = nil;
  [_sectionTitles release];
  _sectionTitles = nil;
  [_sectionMarkers release];
  _sectionMarkers = nil;
  
  [_filteredRomList release];
  _filteredRomList = nil;
  [_filteredSectionTitles release];
  _filteredSectionTitles = nil;
  [_filteredSectionMarkers release];
  _filteredSectionMarkers = nil;
  
  self.detailsItem = nil;
  [_romPath release];
  _romPath = nil;
  [_sramPath release];
  _sramPath = nil;
  
  [super dealloc];
}

@end
