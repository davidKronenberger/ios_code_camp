//
//  CreateGroupTableViewController.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "CreateGroupTableViewController.h"
#import "Contact.h"
#import "DatabaseSingelton.h"
#import "ContactTableView.h"

@import Firebase;
@import GoogleMobileAds;


@interface CreateGroupTableViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet ContactTableView *_contactsTableView;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;

// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton *database;
@end

@implementation CreateGroupTableViewController

// Create weak self instance. Its for accessing in whole view controller;
__weak CreateGroupTableViewController *weakSelfCreateGroup;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakSelfCreateGroup = self;
    
    weakSelfCreateGroup.database = [DatabaseSingelton sharedDatabase];
    
    [weakSelfCreateGroup addBorderToTextView];
    
    weakSelfCreateGroup.groupNameTextField.delegate = weakSelfCreateGroup;
    
    weakSelfCreateGroup._contactsTableView._contactsForTableView = weakSelfCreateGroup.database._contactsAddressBookUsingApp;
    
    weakSelfCreateGroup._contactsTableView.didSelectRowAtIndexPath = didSelectRowAtIndexpathCreateGroup;
    weakSelfCreateGroup._contactsTableView.didDeselectRowAtIndexPath = didDeselectRowAtIndexpathCreateGroup;
}

#pragma mark - textfield should return

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

void(^didSelectRowAtIndexpathCreateGroup)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    //if a user selected a contact for adding to the group this part is called
    //load the requested contact and set him up for the groupchat
    Contact *contact = nil;
    contact = [weakSelfCreateGroup.database._contactsAddressBookUsingApp objectAtIndex:indexPath.row];
    
    [weakSelfCreateGroup.database._contactsForNewGroup addObject:contact];
    
    [weakSelfCreateGroup.groupNameTextField resignFirstResponder];
};

void(^didDeselectRowAtIndexpathCreateGroup)(NSIndexPath *) = ^(NSIndexPath * indexPath) {
    //if a user made a mistake by selecting the wrong user and wants to deselect him this part is called
    //get the selected user and remove him from the new to build groupchat
    Contact *contact = nil;
    contact = [weakSelfCreateGroup.database._contactsAddressBookUsingApp objectAtIndex:indexPath.row];
    
    [weakSelfCreateGroup.database._contactsForNewGroup removeObject:contact];
    
    [weakSelfCreateGroup.groupNameTextField resignFirstResponder];
};

- (void) addBorderToTextView {
    //displays a border to the view for better visuality
    self.groupNameTextField.layer.cornerRadius=8.0f;
    self.groupNameTextField.layer.masksToBounds=YES;
    self.groupNameTextField.layer.borderColor=[[UIColor lightGrayColor] CGColor];
    self.groupNameTextField.layer.borderWidth= 1.0f;
}

#pragma mark - Create Group Handling

- (void) createGroup :(NSString *) name {
    NSString *newGroupID = [[weakSelfCreateGroup.database._ref child:@"groups"] childByAutoId].key;
    
    FIRUser *appUser = [FIRAuth auth].currentUser;
    
    // add any selected users to the dict and push them to the new created group
    NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
    
    [users setObject:[NSNumber numberWithBool:false] forKey:appUser.uid];
    
    for (Contact *tmpUser in weakSelfCreateGroup.database._contactsForNewGroup) {
        [users setObject:[NSNumber numberWithBool:false] forKey:tmpUser.userId];
    }
    
    [[[weakSelfCreateGroup.database._ref child:@"groups"] child:newGroupID] setValue:@{@"created": [DatabaseSingelton getCurrentTime], @"name":name, @"isPrivate": [NSNumber numberWithBool:false], @"users":users}];
}


-(void) checkCreateGroupPossible {
    //check if there are selected users for creating a new group.
    if (weakSelfCreateGroup.database._contactsForNewGroup.count > 0 && [self.groupNameTextField.text length] > 0) {
        [self createGroup:self.groupNameTextField.text];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Button Handling

- (IBAction)CreateGroupButtonPressed:(id)sender {
    //check if there are selected users for creating a new group.
    [self checkCreateGroupPossible];
}

- (IBAction)AbortButtonPressed:(id)sender {
    //if the user decides to cancel the process of creating a group this part is called
    weakSelfCreateGroup.database._contactsForNewGroup = [[NSMutableArray alloc] init];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
