//
//  DatabaseSingelton.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <foundation/Foundation.h>

@import Firebase;

@interface DatabaseSingelton : NSObject {
    NSMutableArray *_contacts;
}

// In this object the contacts are saved, which will shown in the table view.
@property (strong, nonatomic) NSMutableArray *_contacts;

@property (strong, nonatomic) NSMutableArray *_contactsForGroup;

@property (strong, nonatomic) FIRDatabaseReference *_ref;

+ (id)sharedDatabase;
+ (void) addUserToGroup: (NSString *) groupId withUserId: (NSString *) userId;
+ (void) addUserToGroup: (NSString *) groupId withUsers: (NSMutableDictionary *) userId;
+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl;
+ (NSString *) getCurrentTime;

@end