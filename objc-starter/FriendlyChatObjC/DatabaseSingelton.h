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

// This object saves all valid contacts of the addressbook on the device, which are also using this app.
@property (strong, nonatomic) NSMutableArray *_contactsAddressBookUsingApp;
// This array is used to get all contacts of the addressbook on the device, which have a valid email address. (Currently only gmail addresses are valid.)
@property (strong, nonatomic) NSMutableArray *_contactsAddressBook;
// A list of contacts that build a new group.
@property (strong, nonatomic) NSMutableArray *_contactsForNewGroup;

@property (strong, nonatomic) FIRDatabaseReference *_ref;

+ (id)sharedDatabase;
+ (void) addUserToGroup: (NSString *) groupId withUserId: (NSString *) userId;
+ (void) addUsersToGroup: (NSString *) groupId withUsers: (NSMutableDictionary *) userIds;
+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl;
+ (void)addContactToContactsAddressBookUsingApp:(NSString *) uid withMail:(NSString *)email withPhotoURL: (NSString *)photoURL;
+ (NSString *) getCurrentTime;

+ (void) clearCache;

@end
