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
@import GoogleMobileAds;

@interface ContactsTableViewController () <DatabaseDelegate>

// The table view with all contacts and groups.
@property (weak, nonatomic) IBOutlet ContactTableView *_contactsTableView;
// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton *database;

@end

// Create weak self instance. Its for accessing in whole view controller;
__weak ContactsTableViewController *weakSelf;

@implementation ContactsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakSelf = self;
    
    // Init all properties.
    [weakSelf initProperties];
    
    weakSelf._contactsTableView._contactsForTableView = weakSelf.database._contactsForTableView;
    
    weakSelf._contactsTableView.didSelectRowAtIndexPath = didSelectRowAtIndexpathContacts;
    weakSelf._contactsTableView.didDeselectRowAtIndexPath = didDeselectRowAtIndexpathCotacts;
    
    [weakSelf._contactsTableView layoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [weakSelf._contactsTableView reloadData];
}

- (void) dealloc {
    [[weakSelf.database._ref child:@"groups"] removeAllObservers];
    [DatabaseSingelton clearCache];
}

- (void)initProperties {
    weakSelf.database = [DatabaseSingelton sharedDatabase];
    weakSelf.database.delegate = weakSelf;
}

void(^didSelectRowAtIndexpathContacts)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    weakSelf.database._selectedContact = [weakSelf._contactsTableView._contactsForTableView objectAtIndex:indexPath.row];
    
    [weakSelf._contactsTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //perform the segue
    [weakSelf performSegueWithIdentifier:SeguesContactsToChat sender:nil];
};

void(^didDeselectRowAtIndexpathCotacts)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    // Nothing to do here.
};

#pragma mark - Load Delegate Handling

-(void) getNewGroup {
    weakSelf._contactsTableView._contactsForTableView = weakSelf.database._contactsForTableView;
    [weakSelf._contactsTableView reloadData];
}

#pragma mark - Button Handling

- (IBAction)signOut:(UIButton *)sender {
    //this is called when the user hits the logout button
    FIRAuth *firebaseAuth = [FIRAuth auth];
    NSError *signOutError;
    BOOL status = [firebaseAuth signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)NewGroupButtonPressed:(id)sender {
    //this is called when the user hits the new group button
    [self performSegueWithIdentifier:SeguesContactsToCreateNewGroup sender:self];
}
@end
