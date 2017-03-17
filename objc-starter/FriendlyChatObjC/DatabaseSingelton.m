//
//  DatabaseSingelton.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "DatabaseSingelton.h"
#import "Contact.h"

@implementation DatabaseSingelton

// Create weak self instance. Its for accessing in whole singleton.
__weak DatabaseSingelton *weakSingleton;

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

@end
