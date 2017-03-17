//
//  DatabaseSingelton.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <foundation/Foundation.h>
#import "Contact.h"

@import Firebase;

@protocol DatabaseDelegate <NSObject>
@optional
- (void)getNewGroup;
- (void)getNewMessageForGroupId: (NSString *) groupId;
@end

@interface DatabaseSingelton : NSObject {
    NSMutableArray *_contacts;
}

// This object saves all valid contacts of the addressbook on the device, which are also using this app.
@property (strong, nonatomic) NSMutableArray *_contactsAddressBookUsingApp;
// This array is used to get all contacts of the addressbook on the device, which have a valid email address. (Currently only gmail addresses are valid.)
@property (strong, nonatomic) NSMutableArray *_contactsAddressBook;
// A list of contacts that build a new group.
@property (strong, nonatomic) NSMutableArray *_contactsForNewGroup;
// This array includes all groups where the user is participating.
@property (strong, nonatomic) NSMutableArray *_contactsForTableView;
// A list of ref handlers
@property (strong, nonatomic) NSMutableArray *_refHandlers;
// Define DatabaseDelegate as delegate
@property (nonatomic, weak) id <DatabaseDelegate> delegate;

@property (strong, nonatomic) Contact *_selectedContact;
@property (strong, nonatomic) FIRDatabaseReference *_ref;

+ (id)sharedDatabase;
+ (void) addUserToGroup: (NSString *) groupId withUserId: (NSString *) userId;
+ (void) addUsersToGroup: (NSString *) groupId withUsers: (NSMutableDictionary *) userIds;
+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl;
+ (void) addContactToContactsAddressBookUsingApp:(NSString *) uid withMail:(NSString *)email withPhotoURL: (NSString *)photoURL;
+ (NSString *) getCurrentTime;
+ (BOOL) refHandlerAllreadyExists:(NSString *) refHandle;
+ (void) addRefHandler: (NSString *) refHandle;
+ (void) updateContact: (Contact *) contact withMessage:(FIRDataSnapshot*) message;
+ (void) startLoading;


+ (void) clearCache;

@end
