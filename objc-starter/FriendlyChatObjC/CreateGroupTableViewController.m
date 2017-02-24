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
#import <Contacts/Contacts.h>
#import "ChatViewController.h"

@import Firebase;
@import GoogleMobileAds;


@interface CreateGroupTableViewController ()






@end

@implementation CreateGroupTableViewController {
        FIRDatabaseHandle _refHandle;
    }


- (void) viewDidLoad {
    [super viewDidLoad];

    //load all users from _contacts
    
    
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //flag all selected users.
    
}





- (IBAction)CreateGroupButtonPressed:(id)sender {
    
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)AbortButtonPressed:(id)sender {
    
    
    
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
