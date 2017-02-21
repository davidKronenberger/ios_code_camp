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
@property (weak, nonatomic) IBOutlet UITableView *_contactsTableView;

@end

@implementation ContactsTableViewController {
    NSMutableArray *_contacts;
}


#pragma mark - Table view data source

- (void) viewDidLoad {
    [super viewDidLoad];
    
    _contacts = [NSMutableArray arrayWithCapacity:20];
    
    [self contactScan];
    
    self._contactsTableView.delegate = self;
    self._contactsTableView.dataSource = self;
    
    [self._contactsTableView setNeedsDisplay];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_contacts count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Kontakte";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
   //tableView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.90];
    if (indexPath.row % 2 == 1)
    {
        cell.backgroundColor = tableView.backgroundColor;
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    Contact *contact = (_contacts)[indexPath.row];
    cell.textLabel.text = contact.name;  //contact.name
    cell.detailTextLabel.text = contact.email;
    cell.imageView.image = (UIImage *)contact.image;
    
  
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = nil;
    contact = [_contacts objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"ContactsToFC" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *vcToPushTo = segue.destinationViewController;
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
        NSArray * keysToFetch =@[CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactImageDataAvailableKey, CNContactEmailAddressesKey];
        
        
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
    NSMutableArray * email = [contact.emailAddresses valueForKey:@"value"];
    
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
    if([email count] > 0 ){
        ct.email = (NSString *) (email[0]);
    }else{
        ct.email = @"keine E-Mail vorhanden.";
    }
    
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
