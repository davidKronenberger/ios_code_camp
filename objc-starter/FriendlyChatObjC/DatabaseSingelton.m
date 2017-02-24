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

#pragma mark Singleton Methods

+ (id)sharedDatabase {
    static DatabaseSingelton *sharedDatabase = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDatabase = [[self alloc] init];
    });
    return sharedDatabase;
}

- (id)init {
    if (self = [super init]) {
        _contacts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
