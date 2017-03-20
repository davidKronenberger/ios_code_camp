#import "Contact.h"
#import "Constants.h"

@implementation Contact

- (id) init {
    self.messages = [[NSMutableArray alloc] init];
    return self;
}

// Updates the messages of the contact with the help of a firebase snapshot.
- (void) setMessagesWithDataSnapShot: (FIRDataSnapshot *) messages {
    self.messages = [[NSMutableArray alloc] init];
    
    for (FIRDataSnapshot * message in messages.children) {
        [self.messages addObject: message];
    }
}

// Gets the last message text of the contact as string.
- (NSString *) getLastMessageText {
    FIRDataSnapshot * messageSnapshot = [self.messages lastObject];
    NSDictionary<NSString *, NSString *> * message = messageSnapshot.value;
    
    return message[MessageFieldsText];
}

@end
