//
//  CreateGroupTableViewController.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CreateGroupTableViewController.h"
#import "Contact.h"
#import "DatabaseSingelton.h"
#import "ContactTableView.h"

@import Firebase;

@interface CreateGroupTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet ContactTableView * contactsTableView;
@property (weak, nonatomic) IBOutlet UITextField * groupNameTextField;

// A list of contacts that builds a nwe group.
@property (strong, nonatomic) NSMutableArray<Contact *> * contactsForNewGroup;

// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton *database;

@end

@implementation CreateGroupTableViewController

// Create weak self instance. Its for accessing in whole view controller;
__weak CreateGroupTableViewController * weakSelfCreateGroup;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakSelfCreateGroup = self;
    
    [weakSelfCreateGroup initProperties];
    
    [weakSelfCreateGroup initTextField];
    
    [weakSelfCreateGroup initTableView];
}

// Init all in this view controller needed properties.
- (void) initProperties {
    weakSelfCreateGroup.database = [DatabaseSingelton sharedDatabase];
    
    weakSelfCreateGroup.contactsForNewGroup = [[NSMutableArray alloc] init];
}

// Upgrade the visuality of the textfield and set the delegate.
- (void) initTextField {
    // Round the corners of the textfield.
    weakSelfCreateGroup.groupNameTextField.layer.cornerRadius = 8.0f;
    weakSelfCreateGroup.groupNameTextField.layer.masksToBounds = YES;
    
    // Displays a border to the view for better visuality.
    weakSelfCreateGroup.groupNameTextField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    weakSelfCreateGroup.groupNameTextField.layer.borderWidth = 1.0f;
    
    // Set delegate of the text field to this view controller.
    weakSelfCreateGroup.groupNameTextField.delegate = weakSelfCreateGroup;
}

// Initialise the table view data and delegates.
- (void) initTableView {
    weakSelfCreateGroup.contactsTableView.contactsForTableView = weakSelfCreateGroup.database.contactsAddressBookUsingApp;
    
    weakSelfCreateGroup.contactsTableView.didSelectRowAtIndexPath = didSelectRowAtIndexpathCreateGroup;
    weakSelfCreateGroup.contactsTableView.didDeselectRowAtIndexPath = didDeselectRowAtIndexpathCreateGroup;
}

#pragma mark - textfield should return

- (BOOL) textFieldShouldReturn: (UITextField *) textField {
    // We want to hide the keyboard after the return button is pressed.
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

void(^didSelectRowAtIndexpathCreateGroup)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    // If a user selected a contact for adding to the group this part is called.
    // Load the requested contact.
    Contact *contact = nil;
    contact = [weakSelfCreateGroup.database.contactsAddressBookUsingApp objectAtIndex: indexPath.row];
    
    // Set him up for the groupchat.
    [weakSelfCreateGroup.contactsForNewGroup addObject: contact];
    
    // Hide the keyboard.
    [weakSelfCreateGroup.groupNameTextField resignFirstResponder];
};

void(^didDeselectRowAtIndexpathCreateGroup)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    // If a user made a mistake by selecting the wrong user and wants to deselect him this part is called.
    // Get the selected user.
    Contact *contact = nil;
    contact = [weakSelfCreateGroup.database.contactsAddressBookUsingApp objectAtIndex: indexPath.row];
    
    // Remove him from the new to build groupchat.
    [weakSelfCreateGroup.contactsForNewGroup removeObject: contact];
    
    // Hide the keyboard.
    [weakSelfCreateGroup.groupNameTextField resignFirstResponder];
};

#pragma mark - Button Handling

- (IBAction) CreateGroupButtonPressed: (id)sender {
    // Check if there are selected users for creating a new group and a name was included.
    if (weakSelfCreateGroup.contactsForNewGroup.count > 0 && [self.groupNameTextField.text length] > 0) {
        // Create a new group.
        [DatabaseSingelton createGroup: weakSelfCreateGroup.groupNameTextField.text
                          withContacts: weakSelfCreateGroup.contactsForNewGroup];
        // And change to the contacts overview.
        [weakSelfCreateGroup dismissViewControllerAnimated: YES
                                                completion: nil];
    }
}

- (IBAction) AbortButtonPressed: (id)sender {
    // If the user decides to cancel the process go back to the contacts overview.
    [weakSelfCreateGroup dismissViewControllerAnimated: YES
                                            completion: nil];
}
@end
