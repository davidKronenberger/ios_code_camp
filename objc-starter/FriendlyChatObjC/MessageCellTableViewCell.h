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

@property (weak, nonatomic) IBOutlet UIImageView *imageUploadView;
@property (weak, nonatomic) IBOutlet UILabel *sentBy;
@property (weak, nonatomic) IBOutlet UILabel *sentAt;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeight;

@end
