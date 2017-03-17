//
//  LoadViewController.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "LoadViewController.h"
#import "Constants.h"
#import "Contact.h"
#import <Contacts/Contacts.h>
#import "DatabaseSingelton.h"

@interface LoadViewController () <DatabaseDelegate>

// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton *database;

@end

@implementation LoadViewController

// Create weak self instance. Its for accessing in whole view controller;
__weak LoadViewController *weakSelfLoad;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    weakSelfLoad = self;
    weakSelfLoad.database = [DatabaseSingelton sharedDatabase];
    
    weakSelfLoad.database.delegate = self;
    [DatabaseSingelton startLoading];
}

- (void) getNewGroup {
    // Change view controller.
    [self performSegueWithIdentifier: SeguesLoadToContacts
                              sender: nil];
}




@end
