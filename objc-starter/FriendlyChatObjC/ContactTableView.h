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
@property (strong, nonatomic) NSMutableArray * contactsForTableView;
// These two blocks will be used to tell the view controller that a selection or deselction were recognized.
@property (strong, nonatomic) void (^didSelectRowAtIndexPath)(NSIndexPath *indexPath);
@property (strong, nonatomic) void (^didDeselectRowAtIndexPath)(NSIndexPath *indexPath);

@end
