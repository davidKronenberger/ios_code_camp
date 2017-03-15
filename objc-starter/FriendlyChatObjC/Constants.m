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

@implementation Constants

NSString *const NotificationKeysSignedIn = @"onSignInCompleted";

NSString *const SeguesSignInToContacts = @"SignInToContacts";
NSString *const SeguesContactsToSignIn = @"ContactsToSignIn";
NSString *const SeguesContactsToCreateNewGroup = @"ContactsToCreateNewGroup";
NSString *const SeguesContactsToChat = @"ContactsToChat";

NSString *const MessageFieldsname = @"name";
NSString *const MessageFieldstext = @"text";
NSString *const MessageFieldsphotoURL = @"photoURL";
NSString *const MessageFieldsimageURL = @"imageURL";

NSString *const RefHandlerGroupAdded = @"groupAddedHandler";
@end
