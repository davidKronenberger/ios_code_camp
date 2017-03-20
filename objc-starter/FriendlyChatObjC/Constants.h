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

#import <Foundation/Foundation.h>

@interface Constants : NSObject

extern NSString * const SeguesSignInToLoad;
extern NSString * const SeguesLoadToContacts;
extern NSString * const SeguesContactsToCreateNewGroup;
extern NSString * const SeguesContactsToChat;
extern NSString * const SeguesContactsToSignIn;

extern NSString * const CellIdentifierContactCell;
extern NSString * const CellIdentifierMessageCellOwn;
extern NSString * const CellIdentifierMessageCellOther;

extern NSString * const InvisibleTextBehindImage;

extern NSString * const EventContactsTableViewControllerDismissed;

extern NSString * const DatabaseFieldsGroups;
extern NSString * const DatabaseFieldsUsers;

extern NSString * const MessageFieldsName;
extern NSString * const MessageFieldsText;
extern NSString * const MessageFieldsTime;
extern NSString * const MessageFieldsUser;
extern NSString * const MessageFieldsPhotoURL;
extern NSString * const MessageFieldsImageURL;

extern NSString * const GroupFieldsMessages;
extern NSString * const GroupFieldsIsPrivate;
extern NSString * const GroupFieldsUsers;
extern NSString * const GroupFieldsCreated;
extern NSString * const GroupFieldsName;

extern NSString * const UserFieldsEmail;
extern NSString * const UserFieldsPhotoURL;
extern NSString * const UserFieldsUsername;

extern NSString * const ErrorInfoUploading;
extern NSString * const ErrorInfoDownloading;
extern NSString * const ErrorInfoSignIn;
extern NSString * const ErrorInfoSignOut;

extern NSString * const RefHandlerGroupAdded;

extern NSString * const StoragePrefix;

extern NSString * const DateFormat;

extern NSString * const MemberDefaultImage;
extern NSString * const GroupDefaultImage;

extern NSString * const FireBaseStorageErrorImage;

@end
