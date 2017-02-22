//
//  MessageCellTableViewCell.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 21.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCellTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *message;

@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@end
