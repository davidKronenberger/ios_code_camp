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

NSString * const SeguesSignInToLoad                         = @"SignInToLoad";
NSString * const SeguesLoadToContacts                       = @"LoadToContacts";
NSString * const SeguesContactsToCreateNewGroup             = @"ContactsToCreateNewGroup";
NSString * const SeguesContactsToChat                       = @"ContactsToChat";
NSString * const SeguesContactsToSignIn                     = @"ContactsToSignIn";

NSString * const CellIdentifierContactCell                  = @"ContactCell";
NSString * const CellIdentifierMessageCellOwn               = @"MessageCellOwn";
NSString * const CellIdentifierMessageCellOther             = @"MessageCellOther";

NSString * const InvisibleTextBehindImage                   = @"Unsere Sprechblasen bzw. die Zellenhöhe im Chat verändert sich abhängig von der Textlänge. Damit das Bild auch vollständig angezeigt wird, setzen wir diese Nachricht ''unsichtbar'' dahinter.";

NSString * const EventContactsTableViewControllerDismissed  = @"ContactsTableViewControllerDismissed";

NSString * const DatabaseFieldsGroups                       = @"groups";
NSString * const DatabaseFieldsUsers                        = @"users";

NSString * const MessageFieldsName                          = @"name";
NSString * const MessageFieldsText                          = @"text";
NSString * const MessageFieldsTime                          = @"time";
NSString * const MessageFieldsUser                          = @"user";
NSString * const MessageFieldsPhotoURL                      = @"photoURL";
NSString * const MessageFieldsImageURL                      = @"imageURL";

NSString * const GroupFieldsMessages                        = @"messages";
NSString * const GroupFieldsIsPrivate                       = @"isPrivate";
NSString * const GroupFieldsUsers                           = @"users";
NSString * const GroupFieldsCreated                         = @"created";
NSString * const GroupFieldsName                            = @"name";

NSString * const UserFieldsEmail                            = @"email";
NSString * const UserFieldsPhotoURL                         = @"photoURL";
NSString * const UserFieldsUsername                         = @"username";

NSString * const ErrorInfoUploading                         = @"Error uploading: ";
NSString * const ErrorInfoDownloading                       = @"Error downloading: ";
NSString * const ErrorInfoSignIn                            = @"Error while signing in: ";
NSString * const ErrorInfoSignOut                           = @"Error while signing out: ";

NSString * const RefHandlerGroupAdded                       = @"groupAddedHandler";

NSString * const StoragePrefix                              = @"gs://";

NSString * const DateFormat                                 = @"dd.MM.YYYY HH:mm:ss";

NSString * const MemberDefaultImage                         = @"member-button.png";
NSString * const GroupDefaultImage                          = @"group-button.png";

NSString * const FireBaseStorageErrorImage                  = @"https://appjoy.org/wp-content/uploads/2016/06/firebase-storage-logo.png";

@end
