//
//  ContactTableViewCell.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 16.03.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *lastMessage;

@end
