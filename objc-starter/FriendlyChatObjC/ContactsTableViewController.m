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

@property (strong, nonatomic) FIRDatabaseReference *ref;

@property (strong, nonatomic) NSMutableArray<NSDictionary *> *myGroups;
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *allUsers;
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *myUsers;
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *_tmpContacts;
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *_contacts;
@property (strong, nonatomic) NSMutableArray<NSDictionary *> *_myContacts;

@end

__weak ContactsTableViewController *weakViewController;

@implementation ContactsTableViewController {
    FIRDatabaseHandle _refHandle;
}


#pragma mark - Table view data source

- (void) viewDidLoad {
    [super viewDidLoad];
    
    weakViewController = self;
    
    _myGroups = [[NSMutableArray alloc] init];
    _allUsers = [[NSMutableArray alloc] init];
    _myUsers = [[NSMutableArray alloc] init];
    weakViewController._tmpContacts = [[NSMutableArray alloc] init];
    weakViewController._contacts = [[NSMutableArray alloc] init];
    weakViewController._myContacts = [[NSMutableArray alloc] init];
    
    
    _ref = [[FIRDatabase database] reference];
    
    weakViewController.ref =_ref;
    
    //get current user
    FIRUser *user = [FIRAuth auth].currentUser;
    //add user to DB
    [[[_ref child:@"users"] child:user.uid]
     setValue:@{@"username": user.displayName, @"email": user.email}];

    //------Register listener for groups of current user
    _refHandle = [[_ref child:@"groups"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        
        NSString *groupId = snapshot.key;
        NSString *groupName = @"unknown";
        NSString *groupUsers = @"";
        BOOL groupIsPrivate = false;
        BOOL isInGroup = false;
        
        //get all groups of current user
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
        
        if(isInGroup){
            //save groups of current user
            [_myGroups addObject:@{@"id" : groupId, @"name" : groupName, @"isPrivate" : [NSNumber numberWithBool:groupIsPrivate], @"users" : groupUsers}];
            
            //1. create an local contact for every group found
            Contact *ct = [[Contact alloc] init];

            UIImage * image = [UIImage imageNamed:@"nouser.jpg"];
            ct.image = image;
            ct.name = groupName;
            ct.number = @"Keine Nummer gefunden.";
            ct.email = @"keinemail@gmail.com";
            ct.userId = groupId;
            
            //2. push contact to ui
            [weakViewController._contacts addObject:ct];
            [weakViewController._contactsTableView reloadData];
            
            
            //3. wenn auf celle gedrückt wird (onclick) dann ermittle mittels groupname (firstname) die gruppenid
            //4. übergebe die gruppenid dem nächsten viewcontroller ( frag sascha nochmal)
        }
        
        
    }];
    
    
    // -------------Listener for users-------------
    
        _refHandle = [[_ref child:@"users"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
            
            NSString *userId = snapshot.key;
            NSString *username = @"";
            NSString *email = @"";
            
            //get all users from DB
            for (FIRDataSnapshot *child in snapshot.children) {
                if([child.key isEqualToString: @"username"]){
                    username = child.value;
                }else if([child.key isEqualToString: @"email"]){
                    email = child.value;
                }
            }
            
            [_allUsers addObject:@{@"id" : userId, @"username" : username, @"email" : email}];
            
            
        }];
    
    
    
    [self contactScan];
    
    self._contactsTableView.delegate = self;
    self._contactsTableView.dataSource = self;
    
    [self._contactsTableView setNeedsDisplay];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (void) addUserToGroup: (NSDictionary *) userDict withGroupID: (NSString *) groupID withRights: (NSString*)rights{
    [[[[[_ref child:@"groups"] child:groupID] child:@"user"] child:userDict[@"id"] ]setValue:@{@"joined": [self getCurrentTime], @"rights": rights}];
}


- (void) createGroup :(NSString *) name{
    NSString *newGroupID = [[_ref child:@"groups"] childByAutoId].key;
    
    [[[_ref child:@"groups"] child:newGroupID] setValue:@{@"created": [self getCurrentTime], @"name":name}];
    
    FIRUser *user = [FIRAuth auth].currentUser;
    
    NSDictionary *userDict = @{@"id" : user.uid, @"username" : user.displayName, @"email" : user.email};
    
    [self addUserToGroup:userDict withGroupID:newGroupID withRights:@"Admin"];
}


- (NSString *) getCurrentTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:date];
    
    return timeString;
}


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

- (NSString *) getIdFromEmail:(NSString *) email {
    for (NSDictionary *dict in _allUsers) {
        if ([dict[@"email"] isEqualToString: email]) {
            return dict[@"id"];
        }
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
 
    
    for(Contact *contact in weakViewController._tmpContacts) {
       
        for(NSDictionary *dict in weakViewController._myContacts) {
            
            if([contact.email isEqualToString:dict[@"email"]]){
                BOOL containsContact = false;
                NSString *tmpContactsString = @"";
                for(Contact *tempContact in weakViewController._contacts){
                    if([tempContact.email isEqualToString:contact.email]){
                        containsContact = true;
                    }
                }
                if(!containsContact){
                    [weakViewController._contacts addObject:contact];
                    break;
                }
            }
        }
    }
    
    
    return [weakViewController._contacts count];
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
   
    Contact *contact = (weakViewController._contacts)[indexPath.row];
    cell.textLabel.text = contact.name;  //contact.name
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
    contact = [weakViewController._contacts objectAtIndex:indexPath.row];
    
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
        for (Contact *contact in weakViewController._tmpContacts) {
            
            [[[[weakViewController.ref child:@"users"] queryOrderedByChild:@"email"] queryEqualToValue:contact.email] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
                
                NSString *username = @"";
                NSString *email = @"";
                
                for (FIRDataSnapshot *child in snapshot.children) {
                    if([child.key isEqualToString: @"username"]){
                        username = child.value;
                    }else if([child.key isEqualToString: @"email"]){
                        email = child.value;
                    }
                }
                
                [weakViewController._myContacts addObject:@{@"id": snapshot.key, @"username": username, @"email": email}];
                [weakViewController._contactsTableView reloadData];
            }];
            
        }
    }
};

- (BOOL) emailAvailable:(NSString *)email {
    for (NSDictionary *dict in _allUsers) {
        if ([dict[@"email"] isEqualToString: email]) {
            return true;
        }
    }
    return false;
    
}

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
        
        [weakViewController._tmpContacts addObject:ct];
        }
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
