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

#import "Constants.h"
#import "SignInViewController.h"
#import "DatabaseSingelton.h"

@import Firebase;

@interface SignInViewController ()
@property(weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@property(strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@end

@implementation SignInViewController
{
    BOOL loggedIn;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set up flag -> user is not logged in yet
    loggedIn = false;
    
    // connection the controller with the GIDSignIn object, listening on UI events.
    [GIDSignIn sharedInstance].uiDelegate = self;
    self.handle = [[FIRAuth auth]
                   addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
                       if (user) {
                           if(!loggedIn){
                               // set up flag, user is succesfully logged in
                               loggedIn = true;
                               
                               // get current user
                               FIRUser *user = [FIRAuth auth].currentUser;
                               
                               // set/update user to database
                               [DatabaseSingelton updateUser:user.uid withUsername: user.displayName withEmail: user.email withPhotoURL: user.photoURL];
                               
                               [self performSegueWithIdentifier:SeguesSignInToFp sender:nil];
                           }
                       } else {
                           loggedIn = false;
                       }
                   }];
}

- (void)dealloc {
    [[FIRAuth auth] removeAuthStateDidChangeListener:_handle];
}

@end
