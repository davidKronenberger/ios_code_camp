//
//  AvatarImageView.m
//  FriendlyChatObjC
//
//  Created by fmv on 20/03/2017.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "AvatarImageView.h"

@implementation AvatarImageView

- (void) layoutSubviews {
    // Turn the Imageview into a circle with the help of invisible corners.
    self.layer.cornerRadius = self.frame.size.height / 2;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0;
    self.layer.borderColor = [[UIColor blackColor] CGColor];
}

@end
