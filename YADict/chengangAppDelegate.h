//
//  chengangAppDelegate.h
//  YADict
//
//  Created by 陈 钢 on 13-7-29.
//  Copyright (c) 2013年 陈 钢. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface chengangAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField * searchResult;
    IBOutlet NSTextField * searchInput;
    IBOutlet NSTextField * topSearchText;
    IBOutlet NSTextField * rememberedText;
    IBOutlet NSTextField * countLabel;
    IBOutlet NSMutableArray * topSearchWords;
    IBOutlet NSTableView * topSearchTable;
    IBOutlet NSButtonCell * rememeberedCheckbox;
    NSString * readDBPath;
    NSString * writeDBPath;
    NSMutableString * nowEnglish;
    NSMutableString * nowChinese;
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)searchOnChange:(id)sender;

@end
