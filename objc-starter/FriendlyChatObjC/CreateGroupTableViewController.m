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

@import Firebase;
@import GoogleMobileAds;


@interface CreateGroupTableViewController ()
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;

@end

@implementation CreateGroupTableViewController {
    // Singleton instance of database.
    DatabaseSingelton *database;
}


- (void) viewDidLoad {
    [super viewDidLoad];
    
    database = [DatabaseSingelton sharedDatabase];
    
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self;
    
    [self.contactsTableView setNeedsDisplay];
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // We have just one section.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // We have for each contact one row.
    return [database._contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    Contact *contact = (database._contacts)[indexPath.row];
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.email;
    cell.imageView.image = (UIImage *)contact.image;
    
    
    const CGFloat *colors = CGColorGetComponents([tableView.backgroundColor CGColor]);
    
    if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.05 green:colors[1] - 0.05 blue:colors[2] - 0.05 alpha:colors[3]];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.025 green:colors[1] - 0.025 blue:colors[2] - 0.025 alpha:colors[3]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = nil;
    contact = [database._contacts objectAtIndex:indexPath.row];
    //self.selectedGroup = contact.userId;
    
    //[self performSegueWithIdentifier:@"ContactsToFC" sender:self];
    
}

- (IBAction)CreateGroupButtonPressed:(id)sender {
    
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)AbortButtonPressed:(id)sender {
    
    
    
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
