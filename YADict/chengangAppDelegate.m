//
//  chengangAppDelegate.m
//  YADict
//
//  Created by 陈 钢 on 13-7-29.
//  Copyright (c) 2013年 陈 钢. All rights reserved.
//

#import "chengangAppDelegate.h"
#import <sqlite3.h>

@implementation chengangAppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    [countLabel setHidden:YES];
    
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    writeDBPath = [path stringByAppendingPathComponent:@"searchCount.sqlite3"];
    readDBPath = [[NSBundle mainBundle] pathForResource:@"dict" ofType:@"sqlite3"];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:writeDBPath]) {
        NSString * emptyDBFromApp = [[NSBundle mainBundle] pathForResource:@"searchCount" ofType:@"sqlite3"];
        NSError * error;
        [fileManager copyItemAtPath:emptyDBFromApp toPath:writeDBPath error:&error];
        if (error != nil) {
            NSLog(@"[Database:Error] %@", error);
        }
    }
    topSearchWords = [NSMutableArray arrayWithCapacity:100];
    
    [self displayTopSearchText];
    [self displayRememberedText];
    [rememberedText setAllowsEditingTextAttributes: YES];
    [rememberedText setSelectable: YES];
    [topSearchTable setDataSource:(id)self];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [topSearchWords count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString * colIdentifier = [aTableColumn identifier];
    if ([colIdentifier isEqualToString:@"English"]) {
        return [[topSearchWords objectAtIndex:rowIndex] objectAtIndex:0];
    }
    else if ([colIdentifier isEqualToString:@"Chinese"]) {
        return [[topSearchWords objectAtIndex:rowIndex] objectAtIndex:1];
    }
    else if ([colIdentifier isEqualToString:@"RememberedFlag"]){
        //NSLog(@"%@", colIdentifier);
        return [[topSearchWords objectAtIndex:rowIndex] objectAtIndex:2];
        //return [NSNumber numberWithBool:YES];
    }
    return nil;
}

- (void) displayTopSearchText {
    sqlite3 * dbh;
    if (sqlite3_open([writeDBPath UTF8String], &dbh) != SQLITE_OK) {
        sqlite3_close(dbh);
        NSLog(@"db close error\n");
        NSAssert(0, @"Failed to open SQLite");
    }
    NSString * sql = @"SELECT English,Chinese \
        FROM searchCount Where RememberedFlag isnull \
        ORDER BY searchCount DESC LIMIT 80";
    
    sqlite3_stmt * stmt;
    if (sqlite3_prepare_v2(dbh, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        [topSearchWords removeAllObjects];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString * english = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
            NSString * chinese = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];
            NSString * chineseSubstring;
            if ([chinese length] > 30) {
                chineseSubstring = [chinese substringToIndex:30];
            }
            else {
                chineseSubstring = chinese;
            }
            NSArray * oneLine = \
                [NSArray arrayWithObjects:english,chineseSubstring,[NSNumber numberWithInt:NSOffState],nil];
            [topSearchWords addObject:oneLine];
        }
        [topSearchTable reloadData];
        sqlite3_finalize(stmt);
    }
    sqlite3_close(dbh);
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    if (commandSelector == @selector(insertNewline:)) {
		// enter pressed
        [self displayResult:[searchInput stringValue]];
        [self increaseSearchCount];
		result = YES;
    }
	else if(commandSelector == @selector(moveLeft:)) {
		// left arrow pressed
		result = YES;
	}
	else if(commandSelector == @selector(moveRight:)) {
		// rigth arrow pressed
		result = YES;
	}
	else if(commandSelector == @selector(moveUp:)) {
		// up arrow pressed
		result = YES;
	}
	else if(commandSelector == @selector(moveDown:)) {
		// down arrow pressed
		result = YES;
	}
    return result;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isEqualTo:@"Dictionary"]) {
        //NSLog(@"1");
    } else if ([[tabViewItem identifier] isEqualTo:@"TopSearch"]) {
        [self displayTopSearchText];
    } else if ([[tabViewItem identifier] isEqualTo:@"Remembered"]) {
        [self displayRememberedText];
    }
}

- (IBAction)searchOnChange:(id)sender{
    [self displayResult:[searchInput stringValue]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"RememberedFlag"] ) {
        /* Maybe not useful Start */
        // UPDATE TableView
        NSArray * oldLine = [topSearchWords objectAtIndex:rowIndex];
        NSArray * newLine = [NSArray arrayWithObjects:\
                             [oldLine objectAtIndex:0], [oldLine objectAtIndex:1]\
                             , [NSNumber numberWithInt:NSOnState], nil];
        [topSearchWords replaceObjectAtIndex:0 withObject:newLine];
        [topSearchTable reloadData];
        /* Maybe not useful End */
        
        NSString * sql = [NSString stringWithFormat:\
                           @"UPDATE SearchCount SET RememberedFlag = 1 WHERE English = '%@'"\
                           , [[topSearchWords objectAtIndex:rowIndex] objectAtIndex:0]];
        //NSLog(@"%@", sql);
        [self sql_do:sql];
        [self displayTopSearchText];
    }
}

- (void) displayResult:(NSString *) searchString {
    //NSLog(@"%@\n", searchString);
    sqlite3 * dbh;
    //if (sqlite3_open([readDBPath UTF8String], &dbh) != SQLITE_OK) {
    if (sqlite3_open_v2([readDBPath UTF8String], &dbh, SQLITE_OPEN_READONLY, NULL) != SQLITE_OK) {
        sqlite3_close(dbh);
        NSLog(@"db close error\n");
        NSAssert(0, @"Failed to open SQLite");
    }
    NSString * sql = [NSString stringWithFormat: \
                      @"SELECT English,Chinese FROM dictData WHERE English >= '%@' ORDER BY English LIMIT 3"\
                      , searchString];
    
    sqlite3_stmt * stmt;
    BOOL firstLine = YES;
    if (sqlite3_prepare_v2(dbh, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        NSMutableString * showText = [NSMutableString stringWithString:@""];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString * english = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
            NSString * chinese = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];
            if (firstLine) {
                firstLine = NO;
                nowEnglish = [english copy];
                nowChinese = [chinese copy];
            }
            [showText appendFormat:@"%@ :\n %@\n\n", english, chinese];
        }
        [searchResult setStringValue:showText];
        sqlite3_finalize(stmt);
    }
    sqlite3_close(dbh);
}

- (void) displayRememberedText {
    sqlite3 * dbh;
    if (sqlite3_open([writeDBPath UTF8String], &dbh) != SQLITE_OK) {
        sqlite3_close(dbh);
        NSLog(@"db close error\n");
        NSAssert(0, @"Failed to open SQLite");
    }
    NSString * sql = @"SELECT English \
        FROM searchCount Where RememberedFlag = 1 \
        ORDER BY searchCount DESC LIMIT 100";
    
    sqlite3_stmt * stmt;
    if (sqlite3_prepare_v2(dbh, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        NSMutableString * showText = [NSMutableString stringWithString:@""];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString * english = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
            //NSString * httpUrl = [NSString stringWithFormat:@"http://blog.yikuyiku.com/q?=%@", english];
            //[showText appendFormat:@"<span style=\"font-size:14px;\"><a href=\"%@\">%@</a></span> ", httpUrl, english];
            //[showText appendFormat:@"<span style=\"font-size:13px;\">%@</span> ", english];
            [showText appendFormat:@"%@  ", english];
        }
        //NSAttributedString * html = [[NSAttributedString alloc] initWithHTML:[showText dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
        //[rememberedText setAttributedStringValue:html];
        [rememberedText setStringValue:showText];
        sqlite3_finalize(stmt);
    }
    sqlite3_close(dbh);
}

- (BOOL) increaseSearchCount {
    if (nowEnglish == nil || [nowEnglish isEqualToString:@""]) {
        return NO;
    }
    
    
    [countLabel setStringValue:[NSString stringWithFormat:@"%@ +1",nowEnglish]];
    
    [countLabel setHidden:NO];
    [countLabel setAlphaValue:1.0];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1.0];
    [[countLabel animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
    
    
    NSString * sql1 = [NSString stringWithFormat:\
                       @"INSERT OR IGNORE INTO SearchCount (English, Chinese, SearchCount) VALUES ('%@', '%@', 0);"\
                       , nowEnglish, nowChinese];
    NSString * sql2 = [NSString stringWithFormat:\
                       @"UPDATE SearchCount SET SearchCount = SearchCount + 1 WHERE English = '%@';"\
                       , nowEnglish];
    
    [self sql_do:sql1];
    [self sql_do:sql2];
    [searchInput selectText:self];
    return YES;
}

- (BOOL) sql_do:(NSString *) sql {
    if (sql == nil || [sql isEqualToString:@""]) {
        return NO;
    }
    
    sqlite3 * dbh;
    sqlite3_stmt * stmt;
    
    if (sqlite3_open([writeDBPath UTF8String], &dbh) != SQLITE_OK) {
        sqlite3_close(dbh);
        NSLog(@"db open error\n");
        return NO;
    }
    
    if (sqlite3_prepare_v2(dbh, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        if( sqlite3_step(stmt) != SQLITE_DONE){
            NSLog(@"Error while updating. '%s'", sqlite3_errmsg(dbh));
            return NO;
        }
        return YES;
    }
    
    return NO;
}

@end
