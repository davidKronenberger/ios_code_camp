//
//  ContactsTableViewController.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 21.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "Contact.h"
#import <Contacts/Contacts.h>

@import Firebase;
@import GoogleMobileAds;

@interface ContactsTableViewController ()

@end

@implementation ContactsTableViewController


#pragma mark - Table view data source

- (void) viewDidLoad {
    [super viewDidLoad];
    
    _contacts = [NSMutableArray arrayWithCapacity:20];
    
    [self contactScan];
    
    ContactsTableViewController *contactsViewController = [[UIStoryboard storyboardWithName:@"Test" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsTableViewController"];
    
    contactsViewController.contacts = _contacts;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.contacts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    Contact *contact = (self.contacts)[indexPath.row];
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.number;
    cell.imageView.image = (UIImage *)contact.image;
    
    return cell;
}

- (void) contactScan {
    if ([CNContactStore class]) {
        //ios9 or later
        CNEntityType entityType = CNEntityTypeContacts;
        
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined) {
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(granted) {
                    [self getAllContact];
                }
            }];
            
        } else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized) {
            [self getAllContact];
        }
    }
}

-(void)getAllContact {
    if([CNContactStore class]) {
        
        //iOS 9 or later
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactImageDataAvailableKey];
        
        
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        [addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            [self parseContactWithContact:contact];
        }];
    }
}



- (void)parseContactWithContact :(CNContact* )contact {
    NSString * firstName =  contact.givenName;
    NSString * lastName =  contact.familyName;
    NSMutableArray * phone = [[contact.phoneNumbers valueForKey:@"value"] valueForKey:@"digits"];
    
    
    UIImage * image;
    if(contact.imageDataAvailable){
        image = [UIImage imageWithData:(NSData *) contact.imageData];
    } else {
        image = [UIImage imageNamed:@"nouser.jpg"];
    }
    
    
    
    Contact *ct = [[Contact alloc] init];
    ct.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    ct.number = (NSString *)(phone[0]);
    ct.image = image;
    
    [_contacts addObject:ct];
}

- (IBAction)signOut:(UIButton *)sender {
    FIRAuth *firebaseAuth = [FIRAuth auth];
    NSError *signOutError;
    BOOL status = [firebaseAuth signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
