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

// Create weak self instance. Its for accessing in whole singleton.
__weak DatabaseSingelton *weakSingleton;

// Synthesise LoadDelegate delegate
@synthesize delegate;

#pragma mark Singleton Methods

+ (id)sharedDatabase {
    static DatabaseSingelton *sharedDatabase = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDatabase = [[self alloc] init];
    });
    return sharedDatabase;
}

+ (void)clearCache {
    weakSingleton._contactsAddressBook = [[NSMutableArray alloc] init];
    weakSingleton._contactsAddressBookUsingApp = [[NSMutableArray alloc] init];
    weakSingleton._contactsForNewGroup = [[NSMutableArray alloc] init];
}

+ (void) startLoading {
    // Load contacts from addressbook.
    [weakSingleton contactScan];
}

+ (void) addUserToGroup: (NSString *) groupId withUserId: (NSString *) userId {
    [[[[[weakSingleton._ref child:@"groups"] child:groupId] child:@"users"] child:userId] setValue:[NSNumber numberWithBool:false]];
}

+ (void) addUsersToGroup: (NSString *) groupId withUsers: (NSMutableDictionary *) userIds {
    [[[[weakSingleton._ref child:@"groups"] child:groupId] child:@"users"] setValue:userIds];
}

+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl {
    NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
    user[@"email"] = email;
    user[@"username"] = username;
    user[@"photoURL"] = photourl.absoluteString;

    [[[weakSingleton._ref child:@"users"] child:userID] setValue:user];
}

+(void)addContactToContactsAddressBookUsingApp:(NSString *) uid withMail:(NSString *)email withPhotoURL: (NSString *)photoURL {
    for (Contact *contact in weakSingleton._contactsAddressBook) {
        if ([contact.email isEqualToString:email]) {
            contact.userId = uid;
            
            contact.image = [UIImage imageNamed: @"member-button.png"];
            
            if (![photoURL isEqualToString:@""]) {
                NSURL *URL = [NSURL URLWithString:photoURL];
                if (URL) {
                    NSData *data = [NSData dataWithContentsOfURL:URL];
                    if (data) {
                        contact.image = [UIImage imageWithData:data];
                    }
                }
            }
            
            [weakSingleton._contactsAddressBookUsingApp addObject:contact];
        }
    }
}

+ (NSString *) getCurrentTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:date];
    
    return timeString;
}

+ (BOOL) refHandlerAllreadyExists:(NSString *) refHandle {
    for (NSString * handler in weakSingleton._refHandlers) {
        if ([handler isEqualToString:refHandle]) {
            return true;
        }
    }
    
    return false;
}

+ (void) addRefHandler: (NSString *) refHandle {
    if (![DatabaseSingelton refHandlerAllreadyExists:refHandle]) {
        [weakSingleton._refHandlers addObject:refHandle];
    }
}


+ (void) updateContact: (Contact *) contact withMessage:(FIRDataSnapshot*) message {
    for (Contact *tmpContact in weakSingleton._contactsForTableView) {
        if ([tmpContact.groupId isEqualToString:contact.groupId]) {
            [tmpContact.messages addObject:message.value[@"text"]];
        }
    }
}

- (id)init {
    if (self = [super init]) {
        weakSingleton = self;
        
        weakSingleton._contactsAddressBook = [[NSMutableArray alloc] init];
        weakSingleton._contactsAddressBookUsingApp = [[NSMutableArray alloc] init];
        weakSingleton._contactsForNewGroup = [[NSMutableArray alloc] init];
        weakSingleton._contactsForTableView = [[NSMutableArray alloc] init];
        
        weakSingleton._refHandlers = [[NSMutableArray alloc] init];
        
        self._ref = [[FIRDatabase database] reference];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

#pragma mark - Group Handling

- (void)getGroups {
    //get current user
    FIRUser *appUser = [FIRAuth auth].currentUser;
    
    
    // The following two lines are necassary because of a bug in firebase. The removeallobserver function does not work. Sooo....
    // Check first if the ref handler still exists.
    if (![DatabaseSingelton refHandlerAllreadyExists:RefHandlerGroupAdded]) {
        // If we are the first time here, add this ref handler to our list of refhandlers and further working...
        [DatabaseSingelton addRefHandler:RefHandlerGroupAdded];
        
        //------Register listener for groups of current user
        [[weakSingleton._ref child:@"groups"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *group) {
            
            NSString *groupId = group.key;
            NSString *groupName = @"unknown";
            BOOL groupIsPrivate = false;
            
            FIRDataSnapshot *users = [[FIRDataSnapshot alloc] init];
            //get all groups of current user
            //iterate all his keys and add proper values
            
            for (FIRDataSnapshot *child in group.children) {
                if ([child.key isEqualToString: @"name"]) {
                    groupName = child.value;
                } else if([child.key isEqualToString: @"users"]) {
                    users = child;
                } else if ([child.key isEqualToString: @"isPrivate"]) {
                    groupIsPrivate = [child.value boolValue];
                }
            }
            
            BOOL userIsInGroup = false;
            
            for (FIRDataSnapshot *user in users.children) {
                if ([user.key isEqualToString: appUser.uid]){
                    userIsInGroup = true;
                    break;
                }
            }
            
            // If current user is in this group
            if(userIsInGroup) {
                // If the chat is a private chat (2 persons only chat) set the uid
                if (groupIsPrivate) {
                    NSString* otherUserId = @"";
                    
                    for(FIRDataSnapshot *user in users.children) {
                        if(![user.key containsString:appUser.uid]) {
                            otherUserId = user.key;
                            break;
                        }
                    }
                    
                    for (Contact *contact in weakSingleton._contactsAddressBookUsingApp) {
                        if ([contact.userId isEqualToString: otherUserId]){
                            contact.groupId = groupId;
                            contact.isPrivate = true;
                            [weakSingleton._contactsForTableView addObject:contact];
                            break;
                        }
                    }
                } else {
                    //if chat is not private it must be a groupchat (more than 2 people)
                    //1. create an local contact for every group found
                    Contact *contact = [[Contact alloc] init];
                    UIImage * image = [UIImage imageNamed:@"group-button.png"];
                    contact.image = image;
                    contact.name = groupName;
                    contact.number = @"";
                    contact.email = @"";
                    contact.groupId = groupId;
                    contact.isPrivate = false;
                    
                    //2. push contact to ui.
                    [weakSingleton._contactsForTableView addObject:contact];
                }
                
                [weakSingleton.delegate getNewGroup];
            }
        }];
    }
}
BOOL test = true;

- (void) createPrivateGroup: (NSString *) otherUserId {
    [[weakSingleton._ref child:@"groups"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *groups) {
        //get the current user of this application
        FIRUser *appUser = [FIRAuth auth].currentUser;
        
        if (![weakSingleton checkIfPrivateGroupExists:appUser.uid withConcurrent:otherUserId inGroups:groups]) {
            NSString *newGroupID = [[weakSingleton._ref child:@"groups"] childByAutoId].key;
            
            // add any selected users to the dict and push them to the new created group
            NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
            [users setObject:[NSNumber numberWithBool:false] forKey:otherUserId];
            [users setObject:[NSNumber numberWithBool:false] forKey:appUser.uid];
            
            [[[weakSingleton._ref child:@"groups"] child:newGroupID] setValue:@{@"created": [DatabaseSingelton getCurrentTime], @"isPrivate": [NSNumber numberWithBool:true], @"users":users}];
            
        }
    }];
}

-(BOOL) checkIfPrivateGroupExists:(NSString *) memberOneId withConcurrent:(NSString *) memberTwoId inGroups:(FIRDataSnapshot *) groups {
    if (groups.exists) {
        for (FIRDataSnapshot* group in groups.children) {
            BOOL isPrivate = false;
            for (FIRDataSnapshot* element in group.children) {
                if ([element.key isEqualToString:@"isPrivate"]) {
                    isPrivate = element.value;
                    break;
                }
            }
            
            if (isPrivate) {
                FIRDataSnapshot * users = nil;
                for (FIRDataSnapshot *element in group.children) {
                    if ([element.key isEqualToString:@"users"]) {
                        users = element;
                        break;
                    }
                }
                
                BOOL foundFirstId = false;
                BOOL foundSecondId = false;
                
                for (FIRDataSnapshot *user in users.children) {
                    if ([user.key isEqualToString:memberTwoId]) {
                        foundFirstId = true;
                    }
                    
                    if ([user.key isEqualToString:memberOneId]) {
                        foundSecondId = true;
                    }
                }
                
                if (foundFirstId && foundSecondId) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

#pragma mark - Contact Handling

//this method is used to scan all local contacts on the mobile device using the CNContact
- (void) contactScan {
    if ([CNContactStore class]) {
        
        CNEntityType entityType = CNEntityTypeContacts;
        
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined) {
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(granted) {
                    [self getAllContact:requestAllContactsDone];
                }
            }];
            
        } else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized) {
            [self getAllContact:requestAllContactsDone];
        }
    }
}

// This counter is used to check if all contacts are proven against the firebase content.
NSInteger *counterForContactsInAddressbook = 0;

void(^requestAllContactsDone)(BOOL) = ^(BOOL contactsFound) {
    counterForContactsInAddressbook = 0;
    // At this point all contacts are loaded from the addressbook of the device
    // At this point we want to check which contact uses this app too.
    if (contactsFound) {
        
        // Iterate through all contacts of current user in his local directory.
        for (Contact *contact in weakSingleton._contactsAddressBook) {
            
            // We have to increase this counter for each contact to prove if it is in the database.
            counterForContactsInAddressbook++;
            
            // Check if the user is in db.
            [[[[weakSingleton._ref child:@"users"] queryOrderedByChild:@"email"] queryEqualToValue:contact.email] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *users) {
                // If we have found this email in the database, it means that the user with this email uses although this app.
                if (users.exists) {
                    NSString *userID = @"";
                    NSString *email = @"";
                    NSString *photoURL = @"";
                    
                    // Because the user is an element child of this snapshot, we have to iterate first through all children in this snapshot.
                    for (FIRDataSnapshot *user in users.children) {
                        userID = user.key;
                        // At this point we came only once. We check now if the user has values for the asked keys.
                        for (FIRDataSnapshot *child in user.children) {
                            if ([child.key isEqualToString: @"email"]) {
                                email = child.value;
                            } else if ([child.key isEqualToString: @"photoURL"]) {
                                photoURL = child.value;
                            }
                        }
                    }
                    
                    [DatabaseSingelton addContactToContactsAddressBookUsingApp:userID withMail:email withPhotoURL:photoURL];
                    [weakSingleton createPrivateGroup:userID];
                    
                }
                
                // Check if all contacts, to prove if there are in the database, are proven.
                counterForContactsInAddressbook --;
                if (counterForContactsInAddressbook == 0) {
                    // After getting all contacts we check the groups of the current user.
                    [weakSingleton getGroups];
                }
            }];
        }
    }
};

-(void)getAllContact:(void (^)(BOOL requestSuccess))block {
    if([CNContactStore class]) {
        
        //make sure while in contact scan we fetch all the data we need and are permitted access.
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactEmailAddressesKey];
        
        
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        block([addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            [self parseContactWithContact:contact];
        }]);
    }
}

- (void)parseContactWithContact :(CNContact* )contact {
    
    //Get all information of the contact
    NSString * firstName =  contact.givenName;
    NSString * lastName =  contact.familyName;
    NSMutableArray * phone = [[contact.phoneNumbers valueForKey:@"value"] valueForKey:@"digits"];
    NSMutableArray * email = [contact.emailAddresses valueForKey:@"value"];
    
    
    //create a new contact
    Contact *ct = [[Contact alloc] init];
    Boolean validuser = false;
    
    //Check if the user found in contacts is a valid user and
    //therefor has the applikation.
    
    //1. Check if there is an valid E-Mail adress available
    if([email count] > 0 ){
        
        NSUInteger count = [email count];
        
        //for every contact check if there is an gmail adress available
        //if so prefer it over any other address.
        for(int i = 0; i < count; i++){
            if ([email[i] rangeOfString:@"gmail."].location == NSNotFound) {
                //address is not a gmail address
                continue;
            } else {
                //address is a gmail address
                ct.email = (NSString *) (email[i]);
                validuser = true;
                break;
            }
        }
    }
    
    //if the user has a valid EMail address
    if(validuser){
        ct.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        
        //check if there is a phone number available
        if([phone count] > 0 ){
            ct.number = (NSString *)(phone[0]);
        } else {
            ct.number = @"Keine Nummer gefunden.";
        }
        
        [weakSingleton._contactsAddressBook addObject:ct];
    }
}

@end
