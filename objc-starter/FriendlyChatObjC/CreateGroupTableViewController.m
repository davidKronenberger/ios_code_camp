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

@import Firebase;
@import GoogleMobileAds;


@interface CreateGroupTableViewController ()
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;

@end

@implementation CreateGroupTableViewController {
    // Singleton instance of database.
    DatabaseSingelton *database;
}


- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self addBorderToTextView];
    
    database = [DatabaseSingelton sharedDatabase];
    
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self;
    
    [self.contactsTableView setNeedsDisplay];
}

#pragma mark - Table view data source

- (void) addBorderToTextView {
    //displays a border to the view for better visuality
    self.groupNameTextField.layer.cornerRadius=8.0f;
    self.groupNameTextField.layer.masksToBounds=YES;
    self.groupNameTextField.layer.borderColor=[[UIColor lightGrayColor] CGColor];
    self.groupNameTextField.layer.borderWidth= 1.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // We have just one section.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // We have for each contact one row.
    return [database._contactsAddressBookUsingApp count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    //load the contact and display the data into the tableview cell
    Contact *contact = (database._contactsAddressBookUsingApp)[indexPath.row];
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.email;
    cell.imageView.image = (UIImage *)contact.image;
    
    //modify the colors of each cell for better visibility
    const CGFloat *colors = CGColorGetComponents([tableView.backgroundColor CGColor]);
    
    if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.05 green:colors[1] - 0.05 blue:colors[2] - 0.05 alpha:colors[3]];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.025 green:colors[1] - 0.025 blue:colors[2] - 0.025 alpha:colors[3]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //if a user selected a contact for adding to the group this part is called
    //load the requested contact and set him up for the groupchat
    Contact *contact = nil;
    contact = [database._contactsAddressBookUsingApp objectAtIndex:indexPath.row];
    
    [database._contactsForNewGroup addObject:contact];
    
    [self.groupNameTextField resignFirstResponder];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    //if a user made a mistake by selecting the wrong user and wants to deselect him this part is called
    //get the selected user and remove him from the new to build groupchat
    Contact *contact = nil;
    contact = [database._contactsAddressBookUsingApp objectAtIndex:indexPath.row];
    
    [database._contactsForNewGroup removeObject:contact];
    
    [self.groupNameTextField resignFirstResponder];
}

#pragma mark - Create Group Handling

- (void) createGroup :(NSString *) name {
    NSString *newGroupID = [[database._ref child:@"groups"] childByAutoId].key;
    
    FIRUser *appUser = [FIRAuth auth].currentUser;
    
    // add any selected users to the dict and push them to the new created group
    NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
    
    [users setObject:[NSNumber numberWithBool:false] forKey:appUser.uid];
    
    for (Contact *tmpUser in database._contactsForNewGroup) {
        [users setObject:[NSNumber numberWithBool:false] forKey:tmpUser.userId];
    }
    
    [[[database._ref child:@"groups"] child:newGroupID] setValue:@{@"created": [DatabaseSingelton getCurrentTime], @"name":name, @"isPrivate": [NSNumber numberWithBool:false], @"users":users}];
}

#pragma mark - Button Handling

- (IBAction)CreateGroupButtonPressed:(id)sender {
    //check if there are selected users for creating a new group.
    if (sizeof(database._contactsForNewGroup) > 0 && [self.groupNameTextField.text length] > 0) {
        [self createGroup:self.groupNameTextField.text];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)AbortButtonPressed:(id)sender {
    //if the user decides to cancel the process of creating a group this part is called
    database._contactsForNewGroup = [[NSMutableArray alloc] init];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
