//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AppDelegate.h"
#import "ContactsTableViewController.h"
#import "Contact.h"
#import <Contacts/Contacts.h>

@import Firebase;
@import GoogleSignIn;

@implementation AppDelegate
{
    NSMutableArray *_contacts;
}

- (BOOL)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *, id> *)options {
  return [self application:application
                   openURL:url
         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
  return [[GIDSignIn sharedInstance] handleURL:url
                             sourceApplication:sourceApplication
                                    annotation:annotation];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    if (error == nil) {
        GIDAuthentication *authentication = user.authentication;
        FIRAuthCredential *credential =
        [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken
                                         accessToken:authentication.accessToken];
        [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error %@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"Error %@", error.localizedDescription);
    }
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _contacts = [NSMutableArray arrayWithCapacity:20];
    
    [self contactScan];
    
    ContactsTableViewController *contactsViewController = [[UIStoryboard storyboardWithName:@"Test" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsTableViewController"];
    
    contactsViewController.contacts = _contacts;
    
    [FIRApp configure];
    [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
    [GIDSignIn sharedInstance].delegate = self;
    return YES;
}

- (void) contactScan {
    
    if ([CNContactStore class]) {
        
        //ios9 or later
        
        CNEntityType entityType = CNEntityTypeContacts;
        
        if( [CNContactStore authorizationStatusForEntityType:entityType] == CNAuthorizationStatusNotDetermined)
            
        {
            
            CNContactStore * contactStore = [[CNContactStore alloc] init];
            
            [contactStore requestAccessForEntityType:entityType completionHandler:^(BOOL granted, NSError * _Nullable error) {
                
                if(granted){
                    
                    [self getAllContact];
                    
                }
                
            }];
            
        }
        
        else if( [CNContactStore authorizationStatusForEntityType:entityType]== CNAuthorizationStatusAuthorized)
            
        {
            
            [self getAllContact];
            
        }
        
    }
    
}



-(void)getAllContact

{
    
    if([CNContactStore class])
        
    {
        
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



- (void)parseContactWithContact :(CNContact* )contact

{
    
    NSString * firstName =  contact.givenName;
    
    NSString * lastName =  contact.familyName;
    
    NSMutableArray * phone = [[contact.phoneNumbers valueForKey:@"value"] valueForKey:@"digits"];
    
    
    
    UIImage * image;
    
    if(contact.imageDataAvailable){
        
        image = [UIImage imageWithData:(NSData *) contact.imageData];
        
    }else{
        
        image = [UIImage imageNamed:@"nouser.jpg"];
        
    }
    
    
    
    Contact *ct = [[Contact alloc] init];
    
    ct.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    ct.number = (NSString *)(phone[0]);
    
    ct.image = image;
    
    
    
    [_contacts addObject:ct];
    
    
    
}


@end
