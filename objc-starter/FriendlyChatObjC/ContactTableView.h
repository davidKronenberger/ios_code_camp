//
//  ContactTableView.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

// This array includes all contacts.
@property (strong, nonatomic) NSMutableArray *_contactsForTableView;
@property (strong, nonatomic) void (^didSelectRowAtIndexPath)(NSIndexPath *indexPath);
@property (strong, nonatomic) void (^didDeselectRowAtIndexPath)(NSIndexPath *indexPath);

@end
