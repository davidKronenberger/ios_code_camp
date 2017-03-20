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
#import "ChatViewController.h"
#import "MessageCellTableViewCell.h"
#import "DatabaseSingelton.h"

@import Photos;
@import Firebase;

@interface ChatViewController () <UITableViewDataSource,
                                  UITableViewDelegate,
                                  UITextFieldDelegate,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate,
                                  DatabaseDelegate>

// Storyboard views
@property (nonatomic, weak) IBOutlet UILabel *     headerLabel;
@property (nonatomic, weak) IBOutlet UITextField * textField;
@property (nonatomic, weak) IBOutlet UIButton *    sendButton;
@property (nonatomic, weak) IBOutlet UITableView * clientTable;

// Storyboard constraints to scale the tableview.
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * bottomViewOffset;

// The database object.
@property (nonatomic, strong) DatabaseSingelton * database;

// A property to save the keyboard height. It is that we do not get the keyboard height every time. It's constant for whole lifecycle of app.
@property (nonatomic) int keyboardHeight;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.database = [DatabaseSingelton sharedDatabase];
    self.database.delegate = self;
    
    [self initTableView];
    
    // Set the header label to the name of the group.
    [self.headerLabel setText: self.database.selectedContact.name];
    
    [self registerForKeyboardNotifications];
}

#pragma mark - Init methods

- (void) initTableView {
    // Tell the table view the estimated height of a cell.
    self.clientTable.rowHeight = UITableViewAutomaticDimension;
    self.clientTable.estimatedRowHeight = 140;
    
    [self addGestureRecognizer];
    
    // Scroll to bottom of table view.
    [self.clientTable setContentOffset: CGPointMake(0, CGFLOAT_MAX)];
}

// Adds a single tap recognizer on the table view. It will be used to hide the keyboard also by tapping the table view.
- (void) addGestureRecognizer {
    // Define singel tap recognizer.
    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                 action: @selector(tableViewTapped)];
    singleTap.numberOfTapsRequired = 1;
    
    // Tell the table view that it has to listen also on user interaction.
    [self.clientTable setUserInteractionEnabled: YES];
    // The table view shall tell this view controller when it recognzes a single tap.
    [self.clientTable addGestureRecognizer: singleTap];
    
}

// This view controller shall be informated if the keyboards was shown and will be hidden.
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWasShown:)
                                                 name: UIKeyboardDidShowNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillBeHidden:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    
}

- (void) dealloc {
    // Simply unsubscribe from *all* notifications upon being deallocated.
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Database delegate

- (void) getNewMessage: (FIRDataSnapshot *) message
            forGroupId: (NSString *)        groupId {
    // Check if the group id equals the selected contact group id. In this case at the message as cell to the table view and scroll down to this message.
    if ([groupId isEqualToString: self.database.selectedContact.groupId]) {
        // Index path of new last cell.
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow: self.database.selectedContact.messages.count - 1
                                                     inSection: 0];
        // Insert the cell as last item in table view.
        [_clientTable insertRowsAtIndexPaths: @[indexPath]
                            withRowAnimation: UITableViewRowAnimationFade];
        
        // Delay execution of scroll to bottom, because the insertion of a new message in the tableview needs a bit of time...
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
            [_clientTable scrollToRowAtIndexPath: indexPath
                                atScrollPosition: UITableViewScrollPositionBottom
                                        animated: NO];
        });
    }
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    // We have just one section.
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView
  numberOfRowsInSection: (NSInteger)     section {
    return [self.database.selectedContact.messages count];
}

- (UITableViewCell *) tableView: (UITableView *)         tableView
          cellForRowAtIndexPath: (nonnull NSIndexPath *) indexPath {
    MessageCellTableViewCell * cell = nil;
    
    // Unpack message from Firebase DataSnapshot
    FIRDataSnapshot * messageSnapshot = self.database.selectedContact.messages[indexPath.row];
    
    // Convert to dictionary.
    NSDictionary<NSString *, NSString *> * message = messageSnapshot.value;
    
    NSString * name     = message[@"user"];
    NSString * time     = message[@"time"];
    NSString * imageURL = message[MessageFieldsimageURL];
    NSString * text     = message[MessageFieldstext];
    NSString * photoURL = message[MessageFieldsphotoURL];
    
    // First of all we have to check who sent this message.
    if ([name isEqualToString: [FIRAuth auth].currentUser.displayName]) {
        // Dependent on the fact, that the message is from the current user. We show the message cell own.
        cell = (MessageCellTableViewCell *)[self.clientTable dequeueReusableCellWithIdentifier: @"MessageCellOwn"
                                                                                  forIndexPath: indexPath];
        
        // This color is for the border of the image view. This will only be used, if the message contains an image.
        cell.imageUploadView.layer.borderColor = [[UIColor whiteColor] CGColor];
        [cell.message setTextColor: [UIColor colorWithWhite: 1.0f
                                                      alpha: 1.0f]];
    } else {
        // Dependent on the fact, that the message is from another user. We show the message cell other.
        cell = (MessageCellTableViewCell *)[self.clientTable dequeueReusableCellWithIdentifier: @"MessageCellOther"
                                                                                  forIndexPath: indexPath];
        
        // This color is for the border of the image view. This will only be used, if the message contains an image.
        cell.imageUploadView.layer.borderColor = [[UIColor blackColor] CGColor];
        [cell.message setTextColor: [UIColor colorWithWhite: 0.0f
                                                      alpha: 1.0f]];
    }
    
    // If the message contains an image.
    if (imageURL) {
        // Set an invisible text behind the image. Because the text tells the cell which height it has.
        cell.message.text = @"Unsere Sprechblasen bzw. die Zellenhöhe im Chat verändert sich abhängig von der Textlänge. Damit das Bild auch vollständig angezeigt wird, setzen wir diese Nachricht ''unsichtbar'' dahinter.";
        
        // Make the text invisible.
        [cell.message setTextColor: [UIColor colorWithWhite: 1.0f
                                                      alpha: 0.0f]];
        
        // Set also the image height.
        cell.imageHeight.constant = 100;
        
        // We want to show the border only if there are image data.
        cell.imageUploadView.layer.borderWidth = 1;
        
        // Now set a default image if the image can't be loaded.
        cell.imageUploadView.image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString: @"https://appjoy.org/wp-content/uploads/2016/06/firebase-storage-logo.png"]]];;
        
        // We load the image only if it has the prefix gs://. This means it is from firebase storage.
        if ([imageURL hasPrefix: @"gs://"]) {
            // Load the image from firebase storage. Because we do not now how big the image ist we said that it the biggest possible.
            [[[FIRStorage storage] referenceForURL: imageURL] dataWithMaxSize: INT64_MAX
                                                                   completion: ^(NSData *data, NSError *error) {
                                                                      // Check if an error occurs while downloading.
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          
                                                                          return;
                                                                      }
                                                                      
                                                                      cell.imageUploadView.image = [UIImage imageWithData:data];
                                                                  }];
        } else {
            // If the prefix is not from firebase storage, load it from web.
            cell.imageUploadView.image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString: imageURL]]];
        }
    } else {
        // There is no image data, so we remove the default image.
        cell.imageUploadView.image  = nil;
        
        // We want to show the border only if there are image data.
        cell.imageUploadView.layer.borderWidth = 0;
        
        // The image height shall not influent the cell. So set it to a big value.
        cell.imageHeight.constant = INT64_MAX;
        
        // Instead of the image we set the message text to the ui view.
        cell.message.text = text;
    }
    
    // Set the sender information
    cell.sentBy.text = name;
    cell.sentAt.text = time;
    
    // Show the sender avatar.
    cell.avatar.image = [UIImage imageNamed: @"member-button.png"];
    
    // Check if the sender has a photo url.
    if (photoURL) {
        NSURL * URL = [NSURL URLWithString: photoURL];
        
        // Check if the phtoto url is a url.
        if (URL) {
            NSData * data = [NSData dataWithContentsOfURL: URL];
            
            // Check if there are data at the end of the url.
            if (data) {
                // Set the image data at the end of the url.
                cell.avatar.image = [UIImage imageWithData: data];
            }
        }
    }
    
    // Make the image upload view round.
    cell.imageUploadView.layer.cornerRadius = 40;
    cell.imageUploadView.layer.masksToBounds = YES;
    
    // We want that the cell background is allthough transparent like the table view background.
    cell.backgroundColor = tableView.backgroundColor;
    
    return cell;
}

// If a cell was selected we deselect it propably and hide the keyboard.
- (void)       tableView: (UITableView *) tableView
 didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    // Hide keyboard.
    [self.textField resignFirstResponder];
    
    // Deselect cell.
    [tableView deselectRowAtIndexPath: indexPath
                             animated: YES];
}

# pragma mark - Table View Gesture Recognizer

// Hide the keyboard if the table view recognizes a single tap on it.
- (void) tableViewTapped {
    [self.textField resignFirstResponder];
}

# pragma mark - Image Picker Delegates

- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    // If a picture is chossen dismiss the image picker view controller.
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    // Get reference url of the choosen image.
    NSURL * referenceURL = info[UIImagePickerControllerReferenceURL];
    
    // If it's a photo from the library, not an image from the camera...
    if (referenceURL) {
        // ... fetch the assets at the image reference.
        PHFetchResult * assets = [PHAsset fetchAssetsWithALAssetURLs: @[referenceURL]
                                                             options: nil];
        // Because just one image can be selected, get the first and only asset.
        PHAsset * asset = [assets firstObject];
        
        // Get the content of the asset.
        [asset requestContentEditingInputWithOptions: nil
                                   completionHandler: ^(PHContentEditingInput * contentEditingInput,
                                                        NSDictionary *          info) {
                                       
                                       // Prepare the image for saving in storage.
                                       NSURL * imageFile = contentEditingInput.fullSizeImageURL;
                                       
                                       // This use this format in storage for better structure contents. First the user, then the date and at last the content.
                                       NSString * filePath = [NSString stringWithFormat:@"%@/%lld/%@", [FIRAuth auth].currentUser.uid,
                                                              (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),
                                                              [referenceURL lastPathComponent]];
                                       
                                       // We save the image at the specified path in firebase storage.
                                       [[self.database.storageRef child: filePath] putFile: imageFile
                                                                                  metadata: nil
                                                                                completion: ^(FIRStorageMetadata * metadata,
                                                                                              NSError *            error) {
                                                                                    [self imageUploaded: metadata
                                                                                              withError: error];
                                                                                }];
                                   }];
    } else {
        // The image came from camera.
        
        // Get the original image from camera.
        UIImage * image = info[UIImagePickerControllerOriginalImage];
        
        // Get the image data as jpeg and compress it to 80 %.
        NSData * imageData = UIImageJPEGRepresentation(image, 0.8);
        
        // This use this format in storage for better structure contents. First the user, then the date.
        NSString * imagePath = [NSString stringWithFormat:@"%@/%lld.jpg", [FIRAuth auth].currentUser.uid,
                                (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
        // For uploading the image we tell the uploader that this data are of type jpeg.
        FIRStorageMetadata * metadata = [FIRStorageMetadata new];
        metadata.contentType = @"image/jpeg";
        
        // We save the image data at the specified path in firebase storage.
        [[self.database.storageRef child:imagePath] putData: imageData
                                                   metadata: metadata
                                                 completion: ^(FIRStorageMetadata * _Nullable metadata,
                                                               NSError * _Nullable error) {
                                                     [self imageUploaded: metadata
                                                               withError: error];
                                                 }];
    }
}

// Handles the image uploaded process.
- (void) imageUploaded: (FIRStorageMetadata *) metadata
             withError: (NSError *)            error {
    // Check if an error occurs while uploading.
    if (error) {
        // If the error is that we can't upload anymore than save not a reference of the image in storage but a photo url from web, with a picture of this problem. At the moment it is the only way to see that a problem occurs while uploading. Remark that the correct image will not be sent again. So at this point the information about the image is lost. In our case we want to see, that it is possible to sent an image and this is our alternative.
        if (error.code == -13013) {
            [DatabaseSingelton sendMessage: @{MessageFieldsimageURL: @"https://appjoy.org/wp-content/uploads/2016/06/firebase-storage-logo.png"}];
        }
        
        NSLog(@"Error uploading: %@", error);
        
        return;
    }
    
    // If uploading was succesfull send a message with a referenece url to firebase storage.
    [DatabaseSingelton sendMessage: @{MessageFieldsimageURL: [self.database.storageRef child: metadata.path].description}];
}

// If no image is choosen and instead the cancel button is pressed, just dismiss the image picker view.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    [picker dismissViewControllerAnimated: YES
                               completion: nil];
}

#pragma mark - UI Event Handling

// When the back button is pressed then dismiss this view controller.
- (IBAction) back: (UIButton *) sender {
    [self dismissViewControllerAnimated: YES
                             completion: nil];
}

- (IBAction) didTapAddPhoto: (id) sender {
    // To share photos we start the internal image picker.
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    // Tell the picker that this view controller is the delegate for picker events.
    picker.delegate = self;
    
    // Check which image picker source is available and set this source type to the picker.
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // The camera picker is available.
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        // Photo library is allways available.
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    // Change view to image picker.
    [self presentViewController: picker
                       animated: YES
                     completion: nil];
}

#pragma mark - TextView Handling

- (BOOL) textFieldShouldReturn: (UITextField *) textField {
    // Check if there is content in the text field.
    if ([textField.text length] > 0) {
        // Send a message to firebase with the text of the text field to firebase.
        [DatabaseSingelton sendMessage: @{MessageFieldstext: textField.text}];
        
        // Clear the text field.
        textField.text = @"";
    }
    
    // We don't want that the keyboard hide.
    return NO;
}

// When a message shall be send, recognized by tap on send button, then tell the textfield that a similiar action to clicking the return button is done.
- (IBAction) didSendMessage: (UIButton *) sender {
    [self textFieldShouldReturn: self.textField];
}

#pragma mark - Keyboard Handling

- (void) keyboardWasShown: (NSNotification *) aNotification {
    // Gets the keyboard height.
    [self initKeyboardHeight: aNotification];
    
    // When the keyboard is being displayed the rest of the view has to adjust that the input text field is not
    // hidden behind the keyboard.
    self.bottomViewOffset.constant = self.bottomViewOffset.constant + self.keyboardHeight;
    
    // Layout the table view.
    [self.clientTable layoutIfNeeded];
    
    // If there are messages scroll to the last cell in table view.
    if ([self.database.selectedContact.messages count] > 0) {
        // Get indexpath of last cell in table view....
        NSIndexPath * indexPathOfLastCell = [NSIndexPath indexPathForRow: [self.database.selectedContact.messages count] - 1
                                                               inSection: 0];
        // ... and scroll to it.
        [self.clientTable scrollToRowAtIndexPath: indexPathOfLastCell
                                atScrollPosition: UITableViewScrollPositionTop
                                        animated: YES];
    }
}

- (void) keyboardWillBeHidden: (NSNotification *) aNotification {
    // When the keyboard is being hided the rest of the view has to adjust that the bottom is reached.
    self.bottomViewOffset.constant = self.bottomViewOffset.constant - self.keyboardHeight;
    
    // Layout the table view.
    [self.clientTable layoutIfNeeded];
}

// The keyboard height will be set if it is not allready done.
- (void) initKeyboardHeight: (NSNotification *) aNotification {
    // Check if keyboard height isn't be set.
    if (!self.keyboardHeight) {
        // Get keyboard height from user info.
        NSDictionary * info = [aNotification userInfo];
        // Get the keyboard dimensions.
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        // Set the keyboard height.
        self.keyboardHeight = kbSize.height;
    }
}

@end
