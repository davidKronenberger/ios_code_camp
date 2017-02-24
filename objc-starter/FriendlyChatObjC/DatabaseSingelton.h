//
//  DatabaseSingelton.h
//  FriendlyChatObjC
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

##import <foundation/Foundation.h>

@interface DatabaseSingelton : NSObject {
    NSString *someProperty;
}


@property (strong, nonatomic) NSMutableArray *_contacts;

+ (id)sharedManager;

@end
