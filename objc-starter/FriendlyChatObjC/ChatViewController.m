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
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;

@property(nonatomic, weak) IBOutlet UITextField *textField;
@property(nonatomic, weak) IBOutlet UIButton *sendButton;

@property(nonatomic, weak) IBOutlet UITableView *clientTable;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (nonatomic, strong) FIRRemoteConfig *remoteConfig;
@property (nonatomic, strong) DatabaseSingelton *database;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewOffset;
@property (nonatomic) int keyboardHeight;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.database = [DatabaseSingelton sharedDatabase];
    
    _messages = [[NSMutableArray alloc] init];
    
    [self initTableView];
    
    [self.headerLabel setText:self.database._selectedContact.name];
    
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
    _refHandle = [[[[_ref child:@"groups"] child:self.database._selectedContact.groupId] child:@"messages"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
    
        [_clientTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];

        // Delay execution of scroll to bottom , because the insertion of a new message in the tableview needs a bit of time...
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
            [_clientTable scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:_messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        });
    }];
}

- (void)sendMessageToGroup:(NSString *)message withGroupId:(NSString *)groupdId{
    //1. get the current user of this app
    FIRUser *user = [FIRAuth auth].currentUser;
    
    //2. get current time
    NSDate * now = [NSDate date];
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"dd.MM.YYYY HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:now];
    
    //3. set everything together
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
        [cell.message setTextColor:[UIColor colorWithWhite:1.0f alpha:1.0f]];
    } else {
        // Dependent on the fact, that the message is from another user. We show the message cell other.
        cell = (MessageCellTableViewCell *)[_clientTable dequeueReusableCellWithIdentifier:@"MessageCellOther" forIndexPath:indexPath];
        // This color is for the border of the image view. This will only be used, if the message contains an image.
        cell.imageUploadView.layer.borderColor = [[UIColor blackColor] CGColor];
        [cell.message setTextColor:[UIColor colorWithWhite:0.0f alpha:1.0f]];
    }
    
    // If the message contains an image.
    if (imageURL) {
        cell.message.text = @"oimoei coweicmwoc jweoci ewockew ociw cowe ceowic ewoci weociew coewi cewoi eoeiw cewoi ewcoi weoic ewowei ewoic ewoeiw  <oinvori erovimrevoimrevo oimre";
        [cell.message setTextColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
        
        cell.imageHeight.constant = 100;
        
        cell.imageUploadView.image = [UIImage imageNamed: @"wallpaper2.jpg"];
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
        cell.imageUploadView.image  = nil;
        
        cell.imageHeight.constant = 999999;
        
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
    cell.imageUploadView.layer.cornerRadius = 40;
    cell.imageUploadView.layer.masksToBounds = YES;
    
    // We want to show the border only if there are image data.
    if (cell.imageUploadView.image) {
        cell.imageUploadView.layer.borderWidth = 1;
    } else {
        cell.imageUploadView.layer.borderWidth = 0;
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
                                                if (error.code == -13013) {
                                                    [self sendMessage:@{MessageFieldsimageURL:@"https://appjoy.org/wp-content/uploads/2016/06/firebase-storage-logo.png"}];
                                                }
                                                
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
    //when in the process of selecting images to share in chat and the user hits cancel button
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UI Event Handling

- (IBAction)back:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapAddPhoto:(id)sender {
    //when the user hits the button for sharing photos in chat this is called
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
    if ([textField.text length] > 0) {
        [self sendMessage:@{MessageFieldstext: textField.text}];
        textField.text = @"";
    }
    return NO;
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
    [[[[[_ref child:@"groups"] child: self.database._selectedContact.groupId] child:@"messages"] childByAutoId] setValue:mdata];
}

- (IBAction)didSendMessage:(UIButton *)sender {
    [self textFieldShouldReturn:_textField];
}

#pragma mark - Keyboard Handling

- (void)keyboardWasShown:(NSNotification*)aNotification {
    [self getKeyboardHeight:aNotification];
    
    self.bottomViewOffset.constant = self.bottomViewOffset.constant + self.keyboardHeight;
    
    [self.clientTable layoutIfNeeded];
    
    if ([self.messages count] > 0) {
        NSIndexPath *indexPathOfLastCell = [NSIndexPath indexPathForRow:[self.messages count] - 1 inSection:0];
        [self.clientTable scrollToRowAtIndexPath:indexPathOfLastCell atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void) getKeyboardHeight:(NSNotification *)aNotification {
    if (!self.keyboardHeight) {
        //when the keyboard is being displayed the rest of the view has to adjust so the inputtextfield is not
        //hidden behind the keyboard
        NSDictionary* info = [aNotification userInfo];
        //get the keyboardsize
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        
        //set the distance
        self.keyboardHeight = kbSize.height;
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    self.bottomViewOffset.constant = self.bottomViewOffset.constant - self.keyboardHeight;
    
    [self.clientTable layoutIfNeeded];
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

- (void) initTableView {
    self.clientTable.rowHeight = UITableViewAutomaticDimension;
    self.clientTable.estimatedRowHeight = 140;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped)];
    singleTap.numberOfTapsRequired = 1;
    [self.clientTable setUserInteractionEnabled:YES];
    [self.clientTable addGestureRecognizer:singleTap];
}

- (void) tableViewTapped {
    [self.textField resignFirstResponder];
}


@end
