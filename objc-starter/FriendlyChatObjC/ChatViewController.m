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

@import Photos;

@import Firebase;
@import GoogleMobileAds;

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */
static NSString* const kBannerAdUnitID = @"ca-app-pub-3940256099942544/2934735716";

@interface ChatViewController ()<UITableViewDataSource, UITableViewDelegate,
UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
FIRInviteDelegate> {
    FIRDatabaseHandle _refHandle;
}

@property(nonatomic, weak) IBOutlet UITextField *textField;
@property(nonatomic, weak) IBOutlet UIButton *sendButton;

@property(nonatomic, weak) IBOutlet UITableView *clientTable;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (nonatomic, strong) FIRRemoteConfig *remoteConfig;

//@property (nonatomic, strong) NSString *currentGroup; //always update current group

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%@",_currentGroup);
    _messages = [[NSMutableArray alloc] init];
    
    _clientTable.rowHeight = UITableViewAutomaticDimension;
    _clientTable.estimatedRowHeight = 140;
    
    [self configureDatabase];
    [self configureStorage];
    
    [self registerForKeyboardNotifications];
}

- (void)dealloc {
    [_ref removeAllObservers];
}

- (void)configureDatabase {
    _ref = [[FIRDatabase database] reference];
    
    // -------------Listener for messages in current group-------------
    _refHandle = [[[[_ref child:@"groups"] child: _currentGroup] child:@"messages"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
        [_clientTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        [_clientTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
}

- (void)sendMessageToGroup:(NSString *)message withGroupId:(NSString *)groupdId{
    
    FIRUser *user = [FIRAuth auth].currentUser;
    
    //get current time
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:now];
    
    [[[[[_ref child:@"groups"] child:groupdId] child:@"messages"] childByAutoId] setValue:@{@"text": message, @"user": user.displayName, @"time": newDateString}];
}

- (void)configureStorage {
    NSString *storageUrl = [FIRApp defaultApp].options.storageBucket;
    self.storageRef = [[FIRStorage storage] referenceForURL:[NSString stringWithFormat:@"gs://%@", storageUrl]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // We have just one section.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // Dequeue cell
    MessageCellTableViewCell *cell = nil;
    
    // Unpack message from Firebase DataSnapshot
    FIRDataSnapshot *messageSnapshot = _messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    NSString *name = message[@"user"];
    NSString *time = message[@"time"];
    NSString *imageURL = message[MessageFieldsimageURL];
    
    // First of all we have to check who sent this message.
    if ([name isEqualToString: [FIRAuth auth].currentUser.displayName]){
        // Dependent on the fact, that the message is from the current user. We show the message cell own.
        cell = (MessageCellTableViewCell *)[_clientTable dequeueReusableCellWithIdentifier:@"MessageCellOwn" forIndexPath:indexPath];
        
        // This color is for the border of the image view. This will only be used, if the message contains an image.
        cell.imageUploadView.layer.borderColor = [[UIColor whiteColor] CGColor];
    } else {
        
        // Dependent on the fact, that the message is from another user. We show the message cell other.
        cell = (MessageCellTableViewCell *)[_clientTable dequeueReusableCellWithIdentifier:@"MessageCellOther" forIndexPath:indexPath];
        
        // This color is for the border of the image view. This will only be used, if the message contains an image.
        cell.imageUploadView.layer.borderColor = [[UIColor blackColor] CGColor];
    }
    
    // If the message contains an image.
    if (imageURL) {
        // We load the image only if it has the prefix gs://. This means it is from firebase.
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      cell.imageUploadView.image = [UIImage imageWithData:data];
                                                                      
                                                                      [tableView reloadData];
                                                                  }];
        } else {
            // If the prefix is different we show it from the url.
            cell.imageUploadView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    } else {
        // There is no image data, so we remove the image view from the parent container.
        [cell.imageUploadView removeFromSuperview];
        
        // Set the message text to the uiview.
        NSString *text = message[MessageFieldstext];
        cell.message.text = text;
    }
    
    // Set the sender information
    cell.sentBy.text = name;
    cell.sentAt.text = time;
    
    // Show the sender avatar.
    cell.avatar.image = [UIImage imageNamed: @"ic_account_circle"];
    NSString *photoURL = message[MessageFieldsphotoURL];
    if (photoURL) {
        NSURL *URL = [NSURL URLWithString:photoURL];
        if (URL) {
            NSData *data = [NSData dataWithContentsOfURL:URL];
            if (data) {
                cell.avatar.image = [UIImage imageWithData:data];//commented out
            }
        }
    }
    
    //Turn the Imageview into a circle with the help of invisible borders.
    cell.avatar.layer.cornerRadius = cell.avatar.frame.size.height /2;
    cell.avatar.layer.masksToBounds = YES;
    cell.avatar.layer.borderWidth = 0;
    cell.avatar.layer.borderColor = [[UIColor blackColor] CGColor];
    
    //Turn the Imageview into a circle with the help of invisible borders.
    cell.imageUploadView.layer.cornerRadius = cell.imageUploadView.frame.size.height /2;
    cell.imageUploadView.layer.masksToBounds = YES;
    
    // We want to show the border only if there are image data.
    if (cell.imageUploadView.image) {
        cell.imageUploadView.layer.borderWidth = 1;
    }
    
    // We want that the cell background is allthough transparant like the table view background.
    cell.backgroundColor = tableView.backgroundColor;
    
    return cell;
}

# pragma mark - Image Picker

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    // if it's a photo from the library, not an image from the camera
    if (referenceURL) {
        PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceURL] options:nil];
        PHAsset *asset = [assets firstObject];
        [asset requestContentEditingInputWithOptions:nil
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       NSURL *imageFile = contentEditingInput.fullSizeImageURL;
                                       NSString *filePath = [NSString stringWithFormat:@"%@/%lld/%@",
                                                             [FIRAuth auth].currentUser.uid,
                                                             (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),
                                                             [referenceURL lastPathComponent]];
                                       [[_storageRef child:filePath]
                                        putFile:imageFile metadata:nil
                                        completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                            if (error) {
                                                NSLog(@"Error uploading: %@", error);
                                                return;
                                            }
                                            [self sendMessage:@{MessageFieldsimageURL:[_storageRef child:metadata.path].description}];
                                        }
                                        ];
                                   }];
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *imagePath =
        [NSString stringWithFormat:@"%@/%lld.jpg",
         [FIRAuth auth].currentUser.uid,
         (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
        FIRStorageMetadata *metadata = [FIRStorageMetadata new];
        metadata.contentType = @"image/jpeg";
        [[_storageRef child:imagePath] putData:imageData metadata:metadata
                                    completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                                        if (error) {
                                            NSLog(@"Error uploading: %@", error);
                                            return;
                                        }
                                        [self sendMessage:@{MessageFieldsimageURL:[_storageRef child:metadata.path].description}];
                                    }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UI Event Handling

- (IBAction)back:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapAddPhoto:(id)sender {
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
        [alert addAction:dismissAction];
        [self presentViewController:alert animated: true completion: nil];
    });
}

#pragma mark - TextView Handling

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage:@{MessageFieldstext: textField.text}];
    textField.text = @"";
    [self.view endEditing:YES];
    return YES;
}

- (void)sendMessage:(NSDictionary *)data {
    NSMutableDictionary *mdata = [data mutableCopy];
    mdata[@"user"] = [FIRAuth auth].currentUser.displayName;
    NSURL *photoURL = [FIRAuth auth].currentUser.photoURL;
    if (photoURL) {
        mdata[MessageFieldsphotoURL] = [photoURL absoluteString];
    }
    
    //get current time
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:now];
    
    mdata[@"time"] = newDateString;
    
    
    // Push data to Firebase Database
    [[[[[_ref child:@"groups"] child: _currentGroup] child:@"messages"] childByAutoId] setValue:mdata];
}

- (IBAction)didSendMessage:(UIButton *)sender {
    [self textFieldShouldReturn:_textField];
}

#pragma mark - Keyboard Handling

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    const int movementDistance = kbSize.height; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = -movementDistance;
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
    
}


- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    const int movementDistance = kbSize.height; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = movementDistance;
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
    
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.textField resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end
