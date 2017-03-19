//
//  Contact.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 21.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Firebase;

@interface Contact : NSObject

@property (nonatomic, copy) NSString * userId;
@property (nonatomic, copy) NSString * groupId;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSObject * image;
@property (nonatomic, copy) NSString * email;

@property (nonatomic, strong) NSMutableArray <FIRDataSnapshot *> * messages;

@property (nonatomic) BOOL isPrivate;

// Updates the messages of the contact with the help of a firebase snapshot.
- (void) setMessagesWithDataSnapShot: (FIRDataSnapshot *) messages;

// Gets the last message text of the contact as string.
- (NSString *) getLastMessageText;

@end
