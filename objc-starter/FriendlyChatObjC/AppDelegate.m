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
#import "DatabaseSingelton.h"

@import Firebase;
@import GoogleSignIn;

@implementation AppDelegate {
    // Singleton instance of database.
    DatabaseSingelton *database;
}

// This will be called from firebase for logging in with google in browser.
- (BOOL) application: (nonnull UIApplication *)                application
             openURL: (nonnull NSURL *)                        url
             options: (nonnull NSDictionary<NSString *, id> *) options {
    
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

// (This is only for running this app on iOS 8 and older) This will be called from firebase for logging in with google in browser.
- (BOOL) application: (UIApplication *) application
             openURL: (NSURL *)         url
   sourceApplication: (NSString *)      sourceApplication
          annotation: (id)              annotation {
    
    return [[GIDSignIn sharedInstance] handleURL: url
                               sourceApplication: sourceApplication
                                      annotation: annotation];
}

// Handles the google sign in.
- (void)   signIn: (GIDSignIn *)     signIn
 didSignInForUser: (GIDGoogleUser *) user
        withError: (NSError *)       error {
    
    //SignIn with the Googleaccount
    if (error == nil) {
        // Get the google authentification.
        GIDAuthentication *authentication = user.authentication;
        // And on dependent on them the credentials for firebase.
        FIRAuthCredential *credential = [FIRGoogleAuthProvider credentialWithIDToken: authentication.idToken
                                                                         accessToken: authentication.accessToken];
        // And now sign in to our app.
        [[FIRAuth auth] signInWithCredential: credential
                                  completion: ^(FIRUser * _Nullable user, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error %@", error.localizedDescription);
            }
        }];
    } else {
        NSLog(@"Error %@", error.localizedDescription);
    }
}

// Configure firebase and set sign in delegates.
- (BOOL)           application: (UIApplication *) application
 didFinishLaunchingWithOptions: (NSDictionary *)  launchOptions {
    [FIRApp configure];
    [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
    [GIDSignIn sharedInstance].delegate = self;
    
    return YES;
}

@end
