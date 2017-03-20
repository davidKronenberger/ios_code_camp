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
@property (strong, nonatomic) DatabaseSingelton * database;

@end

@implementation LoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.database = [DatabaseSingelton sharedDatabase];
    self.database.delegate = self;
    
    // After this view is visible we start loading the data.
    [DatabaseSingelton startLoading];
    
    [self addNotificationObserver];
}

- (void) addNotificationObserver {
    // Set self to listen for the message "ContactsTableViewControllerDismissed"
    // and run a method when this message is detected.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didDismissContactsTableViewController)
                                                 name: EventContactsTableViewControllerDismissed
                                               object: nil];
}

- (void) dealloc {
    // Simply unsubscribe from *all* notifications upon being deallocated.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Delegates

- (void) getNewGroup {
    // Change to view controller contacts.
    [self performSegueWithIdentifier: SeguesLoadToContacts
                              sender: nil];
}

- (void) didDismissContactsTableViewController {
    // Dismiss this view controller.
    [self dismissViewControllerAnimated: NO
                             completion: nil];
}


@end
