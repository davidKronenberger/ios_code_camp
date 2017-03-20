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

// This delegate will be used to tell the listeners when a new message comes in or a new group was created.
@protocol DatabaseDelegate <NSObject>
@optional
- (void) getNewGroup;
- (void) getNewMessage: (FIRDataSnapshot *) message forGroupId: (NSString *) groupId;
@end

@interface DatabaseSingelton : NSObject

// This object saves all valid contacts of the addressbook on the device, which are also using this app.
@property (strong, nonatomic) NSMutableArray * contactsAddressBookUsingApp;
// This array is used to get all contacts of the addressbook on the device, which have a valid email address. (Currently only gmail addresses are valid.)
@property (strong, nonatomic) NSMutableArray * contactsAddressBook;
// This array includes all groups where the user is participating.
@property (strong, nonatomic) NSMutableArray * groups;

// A list of ref handlers
@property (strong, nonatomic) NSMutableArray * refHandlers;
// Define DatabaseDelegate as delegate
@property (nonatomic, weak) id <DatabaseDelegate> delegate;
// If we select a contact in the groups overview we save it here. It will be used for the chat.
@property (strong, nonatomic) Contact * selectedContact;

// The firebase reference to get data.
@property (strong, nonatomic) FIRDatabaseReference * ref;
// The firebase storage reference for get images.
@property (nonatomic, strong) FIRStorageReference * storageRef;

// The database singleton getter.
+ (id) sharedDatabase;

// Updates the user in firebase with the given properties.
+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl;

// Creates a group with the specified name and as participants the included contacts.
+ (void) createGroup : (NSString *) name withContacts: (NSMutableArray<Contact *> *) contacts;

// Starts the loading procedure.
+ (void) startLoading;

// Resets the singleton and removes all observers.
+ (void) resetDatabase;

// Sends the data as message with the current user as sender, the time when it will be sent and the avatar of the current user to firebase.
+ (void) sendMessage: (NSDictionary *) data;

@end
