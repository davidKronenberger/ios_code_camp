//
//  ContactsTableViewController.m
//
//  Created by Codecamp on 21.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "Contact.h"
#import <Contacts/Contacts.h>
#import "ChatViewController.h"
#import "DatabaseSingelton.h"

@import Firebase;
@import GoogleMobileAds;

@interface ContactsTableViewController ()

// The table view with all contacts and groups.
@property (weak, nonatomic) IBOutlet UITableView *_contactsTableView;
// This array includes all groups that where the user is participating.
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *myGroups;
// Here are all users saved, which use this app.
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *allUsers;
// This object saves all valid contacts of the addressbook on the device, which are also using this app.
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *_myContacts;
// This array is used to get all contacts of the addressbook on the device, which have a valid email address. (Currently only gmail addresses are valid.)
@property (strong, nonatomic) NSMutableArray *_tmpContacts;
// Singleton instance of database.
@property (strong, nonatomic) DatabaseSingelton *database;

// !!!!!!!!!!PLEASE COMMENT THESE TWO PROPERTIES!!!!!!!!!
@property (strong, nonatomic) NSString *selectedGroup;

@end

// Create weak self instance. Its for accessing in whole view controller;
__weak ContactsTableViewController *weakSelf;

@implementation ContactsTableViewController {
    // !!!!!!!!!!PLEASE COMMENT OR RENAME!!!!!!!!!
    FIRDatabaseHandle _refHandle;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakSelf = self;
    
    weakSelf.database = [DatabaseSingelton sharedDatabase];
    
    [weakSelf initProperties];
    
    [weakSelf getGroups];
    
    [weakSelf contactScan];
    
    weakSelf._contactsTableView.delegate = weakSelf;
    weakSelf._contactsTableView.dataSource = weakSelf;
    
    [weakSelf._contactsTableView setNeedsDisplay];
}

- (void)initProperties {
    _myGroups = [[NSMutableArray alloc] init];
    _allUsers = [[NSMutableArray alloc] init];
    weakSelf._tmpContacts = [[NSMutableArray alloc] init];
    weakSelf.database._contacts = [[NSMutableArray alloc] init];
    weakSelf._myContacts = [[NSMutableArray alloc] init];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // We have just one section.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //compare my users from contact list with users from firebase
    for(Contact *contact in weakSelf._tmpContacts) {
        
        for(NSDictionary *dict in weakSelf._myContacts) {
            
            if([contact.email isEqualToString:dict[@"email"]]){
                BOOL containsContact = false;
                for(Contact *tempContact in weakSelf.database._contacts){
                    //check if array already contains user
                    if([tempContact.email isEqualToString:contact.email]){
                        containsContact = true;
                    }
                }
                //add user if not available in array
                if(!containsContact){
                    
                    
                    [[weakSelf.database._ref child:@"groups"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot2) {
                        
                        
                        NSMutableArray<NSDictionary *> *array = [[NSMutableArray alloc] init];
                        
                        for(FIRDataSnapshot *child in snapshot2.children){
                            
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                            
                            [dict setObject:child.key forKey:@"id"];
                            for(FIRDataSnapshot *child2 in child.children){
                                NSString *key = [NSString stringWithFormat: @"%@", child2.key];
                                if([key isEqualToString:@"isPrivate"] || [key isEqualToString:@"user"] ){
                                    [dict setObject:child2.value forKey:child2.key];
                                }
                            }
                            if ([[dict allKeys] containsObject:@"isPrivate"]) {
                                [array addObject: dict];
                            }
                            
                        }
                        
                        
                        [[[[weakSelf.database._ref child:@"users"] queryOrderedByChild:@"email"] queryEqualToValue:contact.email] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
                            
                            NSString *contactId = snapshot.key;
                            BOOL hasPrivateChat = false;
                            
                            for(NSDictionary *dict2 in array){
                                
                                NSString *usersString = [NSString stringWithFormat: @"%@", dict2[@"user"]];
                                if([usersString containsString:contactId] && [usersString containsString:[FIRAuth auth].currentUser.uid]){
                                    hasPrivateChat = true;
                                }
                            }
                            
                            if(!hasPrivateChat){
                                NSString *newGroupId = [self createPrivateGroup: contactId withName:contact.name];
                                contact.groupId = newGroupId;
                                
                            }
                       
                            
                        }];
                        
                        
                    }];
                    contact.userId = dict[@"id"];
                    [weakSelf.database._contacts addObject:contact];
                    break;
                    
                }
            }
        }
    }
    
    
    return [weakSelf.database._contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    Contact *contact = (weakSelf.database._contacts)[indexPath.row];
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
    contact = [weakSelf.database._contacts objectAtIndex:indexPath.row];
    self.selectedGroup = contact.groupId;
    
    [self performSegueWithIdentifier:@"ContactsToFC" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if([segue.identifier isEqualToString:@"ContactsToFC"]){
        
        ChatViewController *vcToPushTo = segue.destinationViewController;
        //UIViewController *vcToPushTo = segue.destinationViewController;  <- Für Übergabe der GroupId geändert.
        vcToPushTo.currentGroup = _selectedGroup;
        
    }else if([segue.identifier isEqualToString:@"ContactToCreateNewGroup"]){
        
        
    }

}

#pragma mark - Group Handling

- (void)getGroups {
    //get current user
    FIRUser *user = [FIRAuth auth].currentUser;
    //add user to DB
    [[[weakSelf.database._ref child:@"users"] child:user.uid]
     setValue:@{@"username": user.displayName, @"email": user.email}];
    
    //------Register listener for groups of current user
    _refHandle = [[weakSelf.database._ref child:@"groups"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        NSString *groupId = snapshot.key;
        NSString *groupName = @"unknown";
        NSString *groupUsers = @"";
        BOOL groupIsPrivate = false;
        BOOL isInGroup = false;
        
        //get all groups of current user
        //iterate all his keys and add proper values
        //   [self contactScan];
        
        
        for (FIRDataSnapshot *child in snapshot.children) {
            if([child.key isEqualToString: @"name"]){
                groupName = child.value;
            }else if([child.key isEqualToString: @"user"]){
                groupUsers = child.value;
                
                NSString* allCurUsers = [NSString stringWithFormat:@"%@", child.value];
                if([allCurUsers containsString: user.uid]){
                    isInGroup = true;
                }
            }else if([child.key isEqualToString: @"isPrivate"]){
                
                if([child.key isEqualToString:@""]){
                    groupIsPrivate = false;
                }else{
                    groupIsPrivate = true;
                }
            }
        }
        
        //if current user is in this group
        if(isInGroup){
            //save groups of current user
            [_myGroups addObject:@{@"id" : groupId, @"name" : groupName, @"isPrivate" : [NSNumber numberWithBool:groupIsPrivate], @"users" : groupUsers}];
            
            if (groupIsPrivate){
                NSString* parseOtherId = [NSString stringWithFormat:@"%@", groupUsers];
                
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:[FIRAuth auth].currentUser.uid withString:@""];
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:@"{" withString:@""];
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:@"}" withString:@""];
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:@" = 0;" withString:@""];
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:@" " withString:@""];
                parseOtherId = [parseOtherId stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                parseOtherId = [parseOtherId stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

                [[[weakSelf.database._ref child:@"users"] child:parseOtherId] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot2) {
                    
                    NSString *otherUserMail = snapshot2.value;
                    
                    for (Contact *contact in weakSelf.database._contacts){
                        if ([contact.email isEqualToString: otherUserMail]){
                            contact.groupId = groupId;
                        }
                    }
                }];
            } else {
                //1. create an local contact for every group found
                Contact *ct = [[Contact alloc] init];
                
                UIImage * image = [UIImage imageNamed:@"nouser.jpg"];
                ct.image = image;
                ct.name = groupName;
                ct.number = @"Keine Nummer gefunden.";
                ct.email = @"keinemail@gmail.com";
                ct.groupId = groupId;
                
                //2. push contact to ui.
                [weakSelf.database._contacts addObject:ct];
                [weakSelf._contactsTableView reloadData];
            }
        }
    }];
    
    /*
     // -------------Listener for users-------------
     
     _refHandle = [[_ref child:@"users"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
     
     NSString *userId = snapshot.key;
     NSString *username = @"";
     NSString *email = @"";
     
     //get all users from DB
     //iterate all his keys and add proper values
     for (FIRDataSnapshot *child in snapshot.children) {
     if([child.key isEqualToString: @"username"]){
     username = child.value;
     }else if([child.key isEqualToString: @"email"]){
     email = child.value;
     }
     }
     //add to array
     [_allUsers addObject:@{@"id" : userId, @"username" : username, @"email" : email}];
     
     
     }];
     */
}

- (NSString *) createPrivateGroup: (NSString *) otherUserId withName: (NSString *) otherUserName {
    NSString *newGroupID = [[weakSelf.database._ref child:@"groups"] childByAutoId].key;
    
    [[[weakSelf.database._ref child:@"groups"] child:newGroupID] setValue:@{@"created": [DatabaseSingelton getCurrentTime], @"isPrivate": [NSNumber numberWithBool:true]}];
    
    FIRUser *user = [FIRAuth auth].currentUser;

    [DatabaseSingelton addUserToGroup: newGroupID withUserId:user.uid];
    
    [[[[weakSelf.database._ref child:@"groups"] child:newGroupID] child:@"user"] setValue:@{user.uid: [NSNumber numberWithBool:false], otherUserId:[NSNumber numberWithBool:false]}];
    //[self addUserToGroup: newGroupID withUserId:otherUserId];
    return newGroupID;
}

/*
 - (void) onPrivatePressed: (NSString *) selectedEmail {
 for (NSDictionary *dict in _myGroups) {
 if ([dict[@"isPrivate"] intValue] == 1) {
 NSString *contactId = [self getIdFromEmail:selectedEmail];
 if([[NSString stringWithFormat: @"%@", dict[@"users"]] containsString: contactId]){
 NSLog(@"%@", dict[@"id"]);
 }
 }
 }
 
 }
 */

#pragma mark - Contact Handling

- (void) contactScan {
    if ([CNContactStore class]) {
        //ios9 or later
        CNEntityType entityType = CNEntityTypeContacts;
        
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined) {
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(granted) {
                    [self getAllContact:requestAllContactsDone];
                }
            }];
            
        } else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized) {
            [self getAllContact:requestAllContactsDone];
        }
    }
}

void(^requestAllContactsDone)(BOOL) = ^(BOOL contactsFound) {
    // At this point all contacts are loaded from the addressbook of the device.
    
    // At this point we want to check which contact uses this app too.
    
    if (contactsFound) {
        //iterate all users of current user in his local directory
        for (Contact *contact in weakSelf._tmpContacts) {
            
            //get all users of current user in db
            [[[[weakSelf.database._ref child:@"users"] queryOrderedByChild:@"email"] queryEqualToValue:contact.email] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
                
                NSString *username = @"";
                NSString *email = @"";
                
                for (FIRDataSnapshot *child in snapshot.children) {
                    if([child.key isEqualToString: @"username"]){
                        username = child.value;
                    }else if([child.key isEqualToString: @"email"]){
                        email = child.value;
                    }
                }
                
                [weakSelf._myContacts addObject:@{@"id": snapshot.key, @"username": username, @"email": email}];
                //reload the table with contacts of current user
                [weakSelf._contactsTableView reloadData];
            }];
            
        }
    }
};

/*
 - (BOOL) emailAvailable:(NSString *)email {
 for (NSDictionary *dict in _allUsers) {
 if ([dict[@"email"] isEqualToString: email]) {
 return true;
 }
 }
 return false;
 
 }
 */

-(void)getAllContact:(void (^)(BOOL requestSuccess))block {
    if([CNContactStore class]) {
        
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactImageDataAvailableKey, CNContactEmailAddressesKey];
        
        
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        block([addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            [self parseContactWithContact:contact];
        }]);
    }
}



- (void)parseContactWithContact :(CNContact* )contact {
    
    //Get all information of the contact
    NSString * firstName =  contact.givenName;
    NSString * lastName =  contact.familyName;
    NSMutableArray * phone = [[contact.phoneNumbers valueForKey:@"value"] valueForKey:@"digits"];
    NSMutableArray * email = [contact.emailAddresses valueForKey:@"value"];
    
    //if there is no picture to be found take the default one
    UIImage * image;
    if(contact.imageDataAvailable){
        image = [UIImage imageWithData:(NSData *) contact.imageData];
    } else {
        image = [UIImage imageNamed:@"nouser.jpg"];
    }
    
    Contact *ct = [[Contact alloc] init];
    Boolean validuser = false;
    
    //Check if the user found in contacts is a valid user and
    //therefor has the applikation.
    
    //1. Check if there is an valid E-Mail adresses available
    if([email count] > 0 ){
        
        NSUInteger count = [email count];
        
        //for every contact check if there is an gmail adress available
        //if so prefer it over any other address.
        for(int i = 0; i < count; i++){
            if ([email[i] rangeOfString:@"gmail."].location == NSNotFound) {
                //address is not a gmail address
                continue;
            } else {
                //address is a gmail address
                ct.email = (NSString *) (email[i]);
                validuser = true;
                break;
            }
        }
    }
    
    //if the user has a valid EMail address
    if(validuser){
        ct.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        
        //check if there is a phone number available
        if([phone count] > 0 ){
            ct.number = (NSString *)(phone[0]);
        } else {
            ct.number = @"Keine Nummer gefunden.";
        }
        ct.image = image;
        
        [weakSelf._tmpContacts addObject:ct];
    }
}

#pragma mark - Button Handling

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

- (IBAction)NewGroupButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"ContactToCreateNewGroup" sender:self];
}
@end
