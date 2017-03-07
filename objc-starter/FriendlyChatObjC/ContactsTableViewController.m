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
                //if user is not available in array
                if(!containsContact){
                    [[weakSelf.database._ref child:@"groups"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot2) {
                        
                        NSMutableArray<NSDictionary *> *array = [[NSMutableArray alloc] init];
                        //add the user to the array
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
                            
                            //is there is no privatchat already in place create one via groupid
                            if(!hasPrivateChat){
                                NSString *newGroupId = [self createPrivateGroup: contactId withName:contact.name];
                                contact.groupId = newGroupId;
                            }

                        }];
                        
                    }];
                    //set the userId
                    contact.userId = dict[@"id"];
                    
                    contact.image = [UIImage imageNamed: @"nouser.jpg"];
                    NSString *photoURL = dict[@"photoURL"];
                    if (![photoURL isEqualToString:@""]) {
                        NSURL *URL = [NSURL URLWithString:photoURL];
                        if (URL) {
                            NSData *data = [NSData dataWithContentsOfURL:URL];
                            if (data) {
                                contact.image = [UIImage imageWithData:data];//commented out
                            }
                        }
                    }
                    
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
    
    //load all needed data into the tableView cell
    Contact *contact = (weakSelf.database._contacts)[indexPath.row];
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

    //this is called when a user touches a cell from the tableview
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = nil;
    contact = [weakSelf.database._contacts objectAtIndex:indexPath.row];
    self.selectedGroup = contact.groupId;
    
    //perform the segue
    [self performSegueWithIdentifier:@"ContactsToFC" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //segue for switching from contacts to chat
    if([segue.identifier isEqualToString:@"ContactsToFC"]){
        
        ChatViewController *vcToPushTo = segue.destinationViewController;
        vcToPushTo.currentGroup = _selectedGroup;
    
    //segue for switching from contacts to create group
    }else if([segue.identifier isEqualToString:@"ContactToCreateNewGroup"]){
        
    }

}

#pragma mark - Group Handling

- (void)getGroups {
    //get current user
    FIRUser *user = [FIRAuth auth].currentUser;
    
    //------Register listener for groups of current user
    _refHandle = [[weakSelf.database._ref child:@"groups"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        NSString *groupId = snapshot.key;
        NSString *groupName = @"unknown";
        NSString *groupUsers = @"";
        BOOL groupIsPrivate = false;
        BOOL isInGroup = false;
        
        FIRDataSnapshot *userChilds = [[FIRDataSnapshot alloc] init];
        //get all groups of current user
        //iterate all his keys and add proper values
        
        for (FIRDataSnapshot *child in snapshot.children) {
            if([child.key isEqualToString: @"name"]){
                groupName = child.value;
            }else if([child.key isEqualToString: @"user"]){
                groupUsers = child.value;
                userChilds = child.children;
                
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
            
            //if the chat is a private chat (2 persons only chat) set the uid
            if (groupIsPrivate){
                NSString* otherId = @"";
                for(FIRDataSnapshot *child in userChilds){
                    if(![child.key containsString:user.uid]){
                        otherId = child.key;
                        break;
                    }
                }
                
                [[[weakSelf.database._ref child:@"users"] child:otherId] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot2) {
                    
                    //and set the Mail aswell for calculating the correct groupID
                    NSString *otherUserMail = snapshot2.value;
                    
                    for (Contact *contact in weakSelf.database._contacts){
                        if ([contact.email isEqualToString: otherUserMail]){
                            contact.groupId = groupId;
                        }
                    }
                }];
            } else {
                //if chat is not private it must be a groupchat (more than 2 people)
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
}

- (NSString *) createPrivateGroup: (NSString *) otherUserId withName: (NSString *) otherUserName {
    NSString *newGroupID = [[weakSelf.database._ref child:@"groups"] childByAutoId].key;
    
    [[[weakSelf.database._ref child:@"groups"] child:newGroupID] setValue:@{@"created": [DatabaseSingelton getCurrentTime], @"isPrivate": [NSNumber numberWithBool:true]}];
    
    //get the current user of this application
    FIRUser *user = [FIRAuth auth].currentUser;

    [DatabaseSingelton addUserToGroup: newGroupID withUserId:user.uid];
    
    [[[[weakSelf.database._ref child:@"groups"] child:newGroupID] child:@"user"] setValue:@{user.uid: [NSNumber numberWithBool:false], otherUserId:[NSNumber numberWithBool:false]}];
    
    return newGroupID;
}

#pragma mark - Contact Handling

//this method is used to scan all local contacts on the mobile device using the CNContact
- (void) contactScan {
    if ([CNContactStore class]) {

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
    // At this point all contacts are loaded from the addressbook of the device
    // At this point we want to check which contact uses this app too.
    if (contactsFound) {
        //iterate all users of current user in his local directory
        for (Contact *contact in weakSelf._tmpContacts) {
            
            //get all users of current user in db
            [[[[weakSelf.database._ref child:@"users"] queryOrderedByChild:@"email"] queryEqualToValue:contact.email] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
                
                NSString *username = @"";
                NSString *email = @"";
                NSString *photoURL = @"";
                
                for (FIRDataSnapshot *child in snapshot.children) {
                    if([child.key isEqualToString: @"username"]){
                        username = child.value;
                    }else if([child.key isEqualToString: @"email"]){
                        email = child.value;
                    }else if([child.key isEqualToString: @"photoURL"]){
                        photoURL = child.value;
                    }
                }
                
                [weakSelf._myContacts addObject:@{@"id": snapshot.key, @"username": username, @"email": email, @"photoURL":photoURL}];
                //reload the table with contacts of current user
                [weakSelf._contactsTableView reloadData];
            }];
            
        }
    }
};

-(void)getAllContact:(void (^)(BOOL requestSuccess))block {
    if([CNContactStore class]) {
        
        //make sure while in contact scan we fetch all the data we need and are permitted access.
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactEmailAddressesKey];
        
        
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
    
    
    //create a new contact
    Contact *ct = [[Contact alloc] init];
    Boolean validuser = false;
    
    //Check if the user found in contacts is a valid user and
    //therefor has the applikation.
    
    //1. Check if there is an valid E-Mail adress available
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
        
        [weakSelf._tmpContacts addObject:ct];
    }
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
    [self performSegueWithIdentifier:@"ContactToCreateNewGroup" sender:self];
}
@end
