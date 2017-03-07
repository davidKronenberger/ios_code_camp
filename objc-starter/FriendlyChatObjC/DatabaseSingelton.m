//
//  DatabaseSingelton.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "DatabaseSingelton.h"

@implementation DatabaseSingelton

@synthesize _contacts;

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

+ (void) addUserToGroup: (NSString *) groupId withUserId: (NSString *) userId {
    [[[[weakSingleton._ref child:@"groups"] child:groupId] child:@"user"] setValue:@{userId: [NSNumber numberWithBool:false]}];
}

+ (void) addUserToGroup: (NSString *) groupId withUsers: (NSMutableDictionary *) users {
    [[[[weakSingleton._ref child:@"groups"] child:groupId] child:@"user"] setValue:users];
}

+ (void) updateUser:(NSString *) userID withUsername: (NSString *) username withEmail: (NSString *) email withPhotoURL: (NSURL *) photourl {
    NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
    user[@"email"] = email;
    user[@"username"] = username;
    user[@"photoURL"] = photourl.absoluteString;

    [[[weakSingleton._ref child:@"users"] child:userID] setValue:user];
}

+ (NSString *) getCurrentTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:date];
    
    return timeString;
}

- (id)init {
    if (self = [super init]) {
        weakSingleton = self;
        self._contacts = [[NSMutableArray alloc] init];
        self._contactsForGroup = [[NSMutableArray alloc] init];
        self._ref = [[FIRDatabase database] reference];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end