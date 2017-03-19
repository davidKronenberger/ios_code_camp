//
//  DatabaseSingelton.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "DatabaseSingelton.h"
#import "Contact.h"
#import "Constants.h"
#import <Contacts/Contacts.h>

@implementation DatabaseSingelton

// The singleton object.
static DatabaseSingelton * sharedDatabase = nil;

// Synthesise LoadDelegate delegate
@synthesize delegate;

#pragma mark Configuration and Initialisation

// Initialisation of the singleton object.
+ (id) sharedDatabase {
    if (sharedDatabase == nil) {
        sharedDatabase = [[self alloc] init];
            
        [sharedDatabase clearCache];
            
        [sharedDatabase configureReferences];
    }
    
    return sharedDatabase;
}


// Clear the two lists that stores all contacts.
- (void) clearCache {
    sharedDatabase.contactsAddressBook         = [[NSMutableArray alloc] init];
    sharedDatabase.contactsAddressBookUsingApp = [[NSMutableArray alloc] init];
    sharedDatabase.groups                      = [[NSMutableArray alloc] init];
}

// Initialise the referendces to firebase database and the storage.
- (void) configureReferences {
    // Initialise the list of alle reference handlers.
    sharedDatabase.refHandlers = [[NSMutableArray alloc] init];
    
    // Initialise database reference.
    sharedDatabase.ref = [[FIRDatabase database] reference];
    
    // Initialise storage reference.
    NSString * storageUrl = [FIRApp defaultApp].options.storageBucket;
    sharedDatabase.storageRef = [[FIRStorage storage] referenceForURL: [NSString stringWithFormat: @"gs://%@", storageUrl]];
}

// Resets the singleton and removes all observers.
+ (void) resetDatabase {
    [sharedDatabase clearCache];
 
    [sharedDatabase.ref removeAllObservers];
    
    sharedDatabase = nil;
}

#pragma mark - User Helper

// Updates the user in firebase with the given properties.
+ (void) updateUser: (NSString *) userID
       withUsername: (NSString *) username
          withEmail: (NSString *) email
       withPhotoURL: (NSURL *) photourl {
    // Create an user.
    NSMutableDictionary * user = [[NSMutableDictionary alloc] init];
    
    // Fill it with data.
    user[@"email"]    = email;
    user[@"username"] = username;
    user[@"photoURL"] = photourl.absoluteString;
    
    // And set it on the user id.
    [[[sharedDatabase.ref child: @"users"] child: userID] setValue: user];
}

#pragma mark - Reference Handler Helper

// Check if the reference hanlder exists in the list of all reference handlers.
- (BOOL) refHandlerAllreadyExists: (NSString *) refHandle {
    for (NSString * handler in sharedDatabase.refHandlers) {
        if ([handler isEqualToString: refHandle]) {
            // Reference handler exists.
            return true;
        }
    }
    
    // Reference handler does not exist.
    return false;
}

// Add a new reference handler to list of all reference handlers.
- (void) addRefHandler: (NSString *) refHandle {
    // Add the ref handler only if it does not exist.
    if (![sharedDatabase refHandlerAllreadyExists: refHandle]) {
        [sharedDatabase.refHandlers addObject: refHandle];
    }
}

#pragma mark - Loading

// Starts the loading procedure.
+ (void) startLoading {
    // Load contacts from addressbook.
    [sharedDatabase contactScan];
}

#pragma mark Loading - Groups - Request

// Here we get all groups in firebase were the user participate.
- (void) getGroups {
    // Get current user.
    FIRUser * appUser = [FIRAuth auth].currentUser;
    
    // The following two lines are necassary because of a bug in firebase. The removeallobserver function does not work. Sooo....
    // Check first if the ref handler still exists.
    if (![sharedDatabase refHandlerAllreadyExists: RefHandlerGroupAdded]) {
        // If we are the first time here, add this ref handler to our list of refhandlers and further working...
        [sharedDatabase addRefHandler: RefHandlerGroupAdded];
        
        // Register listener for groups of current user
        [[sharedDatabase.ref child: @"groups"] observeEventType: FIRDataEventTypeChildAdded
                                                     withBlock: ^(FIRDataSnapshot *group) {
            NSString * groupId   = group.key;
            NSString * groupName = @"unknown";
            BOOL groupIsPrivate  = false;
            
            FIRDataSnapshot * messages = [[FIRDataSnapshot alloc] init];
            FIRDataSnapshot * users    = [[FIRDataSnapshot alloc] init];
            
            // Iterate through the keys and proper values of the group.
            for (FIRDataSnapshot * child in group.children) {
                if ([child.key isEqualToString: @"name"]) {
                    groupName = child.value;
                } else if ([child.key isEqualToString: @"users"]) {
                    users = child;
                } else if ([child.key isEqualToString: @"isPrivate"]) {
                    groupIsPrivate = [child.value boolValue];
                } else if ([child.key isEqualToString: @"messages"]) {
                    messages = child;
                }
            }
            
            BOOL userIsInGroup = false;
            
            // Check if user participate group.
            for (FIRDataSnapshot * user in users.children) {
                if ([user.key isEqualToString: appUser.uid]){
                    userIsInGroup = true;
                    
                    break;
                }
            }
            
            // If current user is in this group
            if (userIsInGroup) {
                // If the chat is a private chat (2 persons only chat) set the uid
                if (groupIsPrivate) {
                    NSString * otherUserId = @"";
                    
                    // Get the other user in this private chat.
                    for(FIRDataSnapshot * user in users.children) {
                        if(![user.key containsString:appUser.uid]) {
                            otherUserId = user.key;
                            
                            break;
                        }
                    }
                    
                    // Copy the contact in this private chat to our groups.
                    for (Contact * contact in sharedDatabase.contactsAddressBookUsingApp) {
                        if ([contact.userId isEqualToString: otherUserId]){
                            contact.groupId = groupId;
                            contact.isPrivate = true;
                            [contact setMessagesWithDataSnapShot: messages];
                            [sharedDatabase.groups addObject: contact];
                            
                            break;
                        }
                    }
                } else {
                    // If the chat is not private it must be a groupchat.
                    // Create a contact of this group.
                    Contact * contact = [[Contact alloc] init];
                    
                    contact.image     = [UIImage imageNamed:@"group-button.png"];
                    contact.name      = groupName;
                    contact.email     = @"";
                    contact.groupId   = groupId;
                    contact.isPrivate = false;
                    [contact setMessagesWithDataSnapShot: messages];
                    
                    // Push the contact to our groups.
                    [sharedDatabase.groups addObject: contact];
                }
                
                // Add message delegate for the created group.
                [sharedDatabase addMessageDelegateForGroupWitGroupId: groupId];
                
                // Tell all delegates which responds to selector that a new new group was found.
                if (sharedDatabase.delegate && [sharedDatabase.delegate respondsToSelector:@selector(getNewGroup)]) {
                    [sharedDatabase.delegate getNewGroup];
                }
            }
        }];
    }
}

#pragma mark Loading - Groups - Creation Helper

// Creates a group with the specified name and as participants the included contacts.
+ (void) createGroup: (NSString *) name
        withContacts: (NSMutableArray<Contact *> *) contacts {
    // Create a new group with a random group id.
    NSString * newGroupID = [[sharedDatabase.ref child: @"groups"] childByAutoId].key;
    
    // Get the current user as one participant of the new group.
    FIRUser * appUser = [FIRAuth auth].currentUser;
    
    // Add any contact to the dict and push them to the new created group.
    NSMutableDictionary * users = [[NSMutableDictionary alloc] init];
    
    // Add the current user...
    [users setObject: [NSNumber numberWithBool: false]
              forKey: appUser.uid];
    
    // .. and each contact that is included here.
    for (Contact * tmpUser in contacts) {
        [users setObject: [NSNumber numberWithBool: false]
                  forKey: tmpUser.userId];
    }
    
    // Add the properties of the new group.
    [[[sharedDatabase.ref child: @"groups"] child: newGroupID] setValue: @{@"created"   : [sharedDatabase getCurrentTime],
                                                                           @"name"      : name,
                                                                           @"isPrivate" : [NSNumber numberWithBool: false],
                                                                           @"users"     : users}];
}

// Creates a private group with current user and another contact as participants.
- (void) createPrivateGroup: (NSString *) otherUserId {
    // Before we create this private group we check firstly that it does not exist. So get all groups.
    [[sharedDatabase.ref child: @"groups"] observeSingleEventOfType: FIRDataEventTypeValue
                                                          withBlock: ^(FIRDataSnapshot * groups) {
        // Get the current user of this application
        FIRUser *appUser = [FIRAuth auth].currentUser;
        
        // Check if the group exist.
        if (![sharedDatabase checkIfPrivateGroupExists: appUser.uid
                                        withConcurrent: otherUserId
                                              inGroups: groups]) {
            // The private group does not exist so add it in firebase.
            
            // Get a new group id.
            NSString *newGroupID = [[sharedDatabase.ref child:@"groups"] childByAutoId].key;
            
            // Add any selected user to the dict and push them to the new group.
            NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
            [users setObject: [NSNumber numberWithBool: false]
                      forKey: otherUserId];
            [users setObject: [NSNumber numberWithBool: false]
                      forKey: appUser.uid];
            
            // Create the group.
            [[[sharedDatabase.ref child: @"groups"] child: newGroupID] setValue: @{@"created"   : [sharedDatabase getCurrentTime],
                                                                                   @"isPrivate" : [NSNumber numberWithBool: true],
                                                                                   @"users"     : users}];
            
        }
    }];
}

// Checks if in the firebase snaphot a private group exists which has the two inputed members as participants.
- (BOOL) checkIfPrivateGroupExists: (NSString *) memberOneId
                    withConcurrent: (NSString *) memberTwoId
                          inGroups: (FIRDataSnapshot *) groups {
    // First of all we have to check if the snapshot exists.
    if (groups.exists) {
        // Now check group by group if this is a private group and has the two members as participants.
        for (FIRDataSnapshot * group in groups.children) {
            BOOL isPrivate = false;
            
            // Check if current group is private.
            for (FIRDataSnapshot * element in group.children) {
                if ([element.key isEqualToString: @"isPrivate"]) {
                    isPrivate = element.value;
                    
                    break;
                }
            }
            
            // If the group is a private group, check further.
            if (isPrivate) {
                FIRDataSnapshot * users = nil;
                
                // Get the participants of the group.
                for (FIRDataSnapshot * element in group.children) {
                    if ([element.key isEqualToString: @"users"]) {
                        users = element;
                        break;
                    }
                }
                
                BOOL foundFirstId = false;
                BOOL foundSecondId = false;
                
                // Check if both members are participants of the private group.
                for (FIRDataSnapshot *user in users.children) {
                    // Check if first member participate group.
                    if ([user.key isEqualToString: memberOneId]) {
                        foundFirstId = true;
                    }
                    // Check if second member participate group.
                    if ([user.key isEqualToString: memberTwoId]) {
                        foundSecondId = true;
                    }
                }
                
                if (foundFirstId && foundSecondId) {
                    // The private group exists.
                    return true;
                }
            }
        }
    }
    
    // The private group does not exist.
    return false;
}

// Get the current date as format dd.MM.YYYY HH:mm:ss.
- (NSString *) getCurrentTime {
    // Get date.
    NSDate * date = [NSDate date];
    
    // Format date.
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"dd.MM.YYYY HH:mm:ss"];
    
    // Return date as string.
    return [formatter stringFromDate: date];
}

#pragma mark Loading - Addressbook - Request

// This method is used to scan all local contacts on the mobile device using the CNContact.
- (void) contactScan {
    // Check if CNContactStore is available.
    if ([CNContactStore class]) {
        CNEntityType entityType = CNEntityTypeContacts;
        
        // If the user does not allow reading the addressbook...
        if ([CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined) {
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            
            // ask for reading the addressbook
            [contactStore requestAccessForEntityType: entityType
                                   completionHandler: ^(BOOL granted, NSError * _Nullable error) {
                // If the user allows reading then start reading.
                if (granted) {
                    [self getAllContact:requestAllContactsDone];
                }
            }];
            // If the user allows reading the addressbook then start reading.
        } else if ([CNContactStore authorizationStatusForEntityType: entityType] == CNAuthorizationStatusAuthorized) {
            [self getAllContact:requestAllContactsDone];
        }
    }
}

// Gets all contacts from the addressbook on the device. We ask only the email address and the name of the users in the addressbook.
- (void) getAllContact: (void (^)(BOOL requestSuccess)) block {
    // At first we get the addressbook.
    NSError* contactError;
    CNContactStore * addressBook = [[CNContactStore alloc] init];
    [addressBook containersMatchingPredicate: [CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]]
                                       error: &contactError];
    
    // These are the properties we are interessted in.
    NSArray * keysToFetch = @[CNContactFamilyNameKey,
                              CNContactGivenNameKey,
                              CNContactEmailAddressesKey];
    
    // We define the request...
    CNContactFetchRequest * request = [[CNContactFetchRequest alloc] initWithKeysToFetch: keysToFetch];
    // ... and start it. After all contacts are parsed call the block.
    block([addressBook enumerateContactsWithFetchRequest: request
                                                   error: &contactError
                                              usingBlock: ^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
        // We get one contact in the addressbook. Now check it and parse it to our contactslist.
        [self parseContactWithContact: contact];
    }]);
}

#pragma mark Loading - Addressbook - Parse Helper

// Add a new contact to the list of all contacts that are using the app and are included in the addressbook of the current user.
- (void) addContactToContactsAddressBookUsingApp: (NSString *) uid
                                        withMail: (NSString *) email
                                    withPhotoURL: (NSString *) photoURL {
    // Search the user with right email address.
    for (Contact * contact in sharedDatabase.contactsAddressBook) {
        // Check if current contact has the right email address.
        if ([contact.email isEqualToString: email]) {
            // Add some properties to this contact.
            contact.userId = uid;
            
            // The default avatar icon of a contact.
            contact.image = [UIImage imageNamed: @"member-button.png"];
            
            // Check if the contact have still an image.
            if (![photoURL isEqualToString: @""]) {
                NSURL * URL = [NSURL URLWithString: photoURL];
                
                if (URL) {
                    NSData * data = [NSData dataWithContentsOfURL: URL];
                    
                    if (data) {
                        contact.image = [UIImage imageWithData: data];
                    }
                }
            }
            
            // Add the contact to the list of all contacts which using the app and are in the addressbook of the current user.
            [sharedDatabase.contactsAddressBookUsingApp addObject: contact];
           
            break;
        }
    }
}

#pragma mark Loading - Addressbook - Parse

// Parse the contact from the address book and add it to my contacts if the contact has a gmail address.
- (void) parseContactWithContact: (CNContact* ) contact {
    // Get all information of the contact.
    NSString * firstName   = contact.givenName;
    NSString * lastName    = contact.familyName;
    NSMutableArray * email = [contact.emailAddresses valueForKey:@"value"];
    
    // Create a new contact.
    Contact *ct = [[Contact alloc] init];
    Boolean validuser = false;
    
    // Check if there is an valid E-Mail adress available.
    if ([email count] > 0) {
        NSUInteger count = [email count];
        
        // For every contact check if there is an gmail address available.
        for (int i = 0; i < count; i++) {
            if ([email[i] rangeOfString:@"gmail."].location != NSNotFound) {
                // Address is a gmail address.
                ct.email = (NSString *) (email[i]);
                validuser = true;
                
                break;
            }
        }
    }
    
    // If the user has a valid E-Mail address...
    if (validuser) {
        ct.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        
        // ... add the contact to our list.
        [sharedDatabase.contactsAddressBook addObject:ct];
    }
}

// This counter is used to check if all contacts are proven against the firebase content.
NSInteger * counterForContactsInAddressbook = 0;

// A block which will be called after getting contacts from addressbook.
void(^requestAllContactsDone)(BOOL) = ^(BOOL contactsFound) {
    counterForContactsInAddressbook = 0;
    // At this point all contacts are loaded from the addressbook of the device.
    // At this point we want to check which contact uses this app too.
    if (contactsFound) {
        
        // Iterate through all contacts of current user in his local directory.
        for (Contact * contact in sharedDatabase.contactsAddressBook) {
            
            // We have to increase this counter for each contact to prove if it is in the database.
            counterForContactsInAddressbook++;
            
            // Check if the user is in db.
            [[[[sharedDatabase.ref child: @"users"] queryOrderedByChild: @"email"] queryEqualToValue: contact.email] observeSingleEventOfType: FIRDataEventTypeValue
                                                                                                                                   withBlock: ^(FIRDataSnapshot *users) {
                // If we have found this email in the database, it means that the user with this email uses although this app.
                if (users.exists) {
                    NSString * userID   = @"";
                    NSString * email    = @"";
                    NSString * photoURL = @"";
                    
                    // Because the user is an element child of this snapshot, we have to iterate first through all children in this snapshot.
                    for (FIRDataSnapshot * user in users.children) {
                        userID = user.key;
                        // At this point we came only once. We check now if the user has values for the asked keys.
                        for (FIRDataSnapshot * child in user.children) {
                            if ([child.key isEqualToString: @"email"]) {
                                email = child.value;
                            } else if ([child.key isEqualToString: @"photoURL"]) {
                                photoURL = child.value;
                            }
                        }
                    }
                    
                    [sharedDatabase addContactToContactsAddressBookUsingApp: userID
                                                                   withMail: email
                                                               withPhotoURL: photoURL];
                    [sharedDatabase createPrivateGroup: userID];
                }
                
                // Check if all contacts, if there are in the database, are proven.
                counterForContactsInAddressbook--;
                                                                                                                                       
                if (counterForContactsInAddressbook == 0) {
                    // After getting all contacts we check the groups of the current user.
                    [sharedDatabase getGroups];
                }
            }];
        }
    }
};

#pragma mark - Message Loading

// Add the message to the messages of the group if it is not included in the messages of the group.
- (BOOL) addMessage: (FIRDataSnapshot *) message
 toGroupWithGroupId: (NSString *) groupId {
    // Add message to group.
    for (Contact * contact in sharedDatabase.groups) {
        // Check if contact is the group to add the message.
        if ([contact.groupId isEqualToString:groupId]) {
            // Check if the message is allready included.
            for (FIRDataSnapshot * oldMessage in contact.messages) {
                if ([oldMessage.key isEqualToString:message.key]) {
                    // The message is no new one so do not work further.
                    return false;
                }
            }
            
            [contact.messages addObject:message];
            
            return true;
        }
    }
    
    return false;
}

// Add a new delegate for listening on messages for the specified group.
- (void) addMessageDelegateForGroupWitGroupId: (NSString *) groupId {
    // The following two lines are necassary because of a bug in firebase. The removeallobserver function does not work. Sooo....
    // Check first if the ref handler with name of input groupId still exists.
    if (![sharedDatabase refHandlerAllreadyExists: groupId]) {
        // If we are the first time here, add this ref handler to our list of refhandlers and further working...
        [sharedDatabase addRefHandler: groupId];
        // -------------Listener for messages in current group-------------
        [[[[_ref child:@"groups"] child: groupId] child: @"messages"] observeEventType: FIRDataEventTypeChildAdded
                                                                             withBlock: ^(FIRDataSnapshot * message) {
                                                                                 if ([sharedDatabase addMessage: message
                                                                                             toGroupWithGroupId: groupId]) {
                                                                                     // Tell all delegates which responds to selector that a new message were come in.
                                                                                     if (sharedDatabase.delegate && [sharedDatabase.delegate respondsToSelector:@selector(getNewMessage: forGroupId:)]) {
                                                                                         [sharedDatabase.delegate getNewMessage: message
                                                                                                                    forGroupId: groupId];
                                                                                     }
                                                                                 }
                                                                                 
                                                                             }];
    }
}

@end
