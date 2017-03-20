//
//  ContactsTableViewController.m
//
//  Created by Codecamp on 21.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "Contact.h"
#import "DatabaseSingelton.h"
#import "ContactTableView.h"

#import "Constants.h"

@import Firebase;

@interface ContactsTableViewController () <DatabaseDelegate>

// The table view with all contacts and groups.
@property (weak, nonatomic) IBOutlet ContactTableView * contactsTableView;
// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton * database;

@end

// Create weak self instance. Its for accessing self in whole view controller;
__weak ContactsTableViewController * weakSelf;

@implementation ContactsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakSelf = self;
    
    // Init all properties.
    [weakSelf initProperties];
    
    // Init table view.
    [weakSelf initTableView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [weakSelf updateTableView];
}

- (void)initProperties {
    weakSelf.database = [DatabaseSingelton sharedDatabase];
    
    weakSelf.database.delegate = weakSelf;
}

- (void) initTableView {
    weakSelf.contactsTableView.contactsForTableView = weakSelf.database.groups;
    
    weakSelf.contactsTableView.didSelectRowAtIndexPath = didSelectRowAtIndexpathContacts;
    weakSelf.contactsTableView.didDeselectRowAtIndexPath = didDeselectRowAtIndexpathCotacts;
    
    [weakSelf.contactsTableView layoutSubviews];
}

void(^didSelectRowAtIndexpathContacts)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    weakSelf.database.selectedContact = [weakSelf.contactsTableView.contactsForTableView objectAtIndex: indexPath.row];
    
    // We do not want that the selected cell is visible as selected, so deselect it.
    [weakSelf.contactsTableView deselectRowAtIndexPath: indexPath
                                              animated: YES];
    
    // Change to view controller chat.
    [weakSelf performSegueWithIdentifier: SeguesContactsToChat
                                  sender: nil];
};

void(^didDeselectRowAtIndexpathCotacts)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    // Nothing to do here.
};

- (void) dealloc {
    // Clear database.
    [DatabaseSingelton resetDatabase];
}

#pragma mark - Load Delegate Handling

- (void) getNewGroup {
    [weakSelf updateTableView];
}

- (void) getNewMessage: (FIRDataSnapshot *) message
            forGroupId: (NSString *) groupId {
    [weakSelf updateTableView];
}

// Updates contact table view.
- (void) updateTableView {
    weakSelf.contactsTableView.contactsForTableView = weakSelf.database.groups;
    [weakSelf.contactsTableView reloadData];
}

#pragma mark - Button Handling

- (IBAction) signOut: (UIButton *) sender {
    // Get user authentification.
    FIRAuth * firebaseAuth = [FIRAuth auth];
    NSError * signOutError;
    
    // Logout.
    BOOL status = [firebaseAuth signOut: &signOutError];
    
    // If an error occurs while sign out, show the error message.
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        
        return;
    }
    
    // Dismiss this view controller.
    [weakSelf dismissViewControllerAnimated:NO completion:nil];
    
    // This sends a message through the NSNotificationCenter
    // to any listeners for "ContactsTableViewControllerDismissed"
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"ContactsTableViewControllerDismissed"
     object:nil userInfo:nil];
}

- (IBAction) newGroupButtonPressed: (id) sender {
    // Change to view controller create group.
    [self performSegueWithIdentifier: SeguesContactsToCreateNewGroup
                              sender: self];
}
@end
