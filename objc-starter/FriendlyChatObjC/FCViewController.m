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
#import "FCViewController.h"
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

@interface FCViewController ()<UITableViewDataSource, UITableViewDelegate,
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


@property (nonatomic, strong) NSString *currentGroup; //always update current group

@end

@implementation FCViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _messages = [[NSMutableArray alloc] init];
    
  _currentGroup = [[NSString alloc] init];
    
  [_clientTable registerClass:UITableViewCell.self forCellReuseIdentifier:@"tableViewCell"];

  _clientTable.rowHeight = UITableViewAutomaticDimension;
  _clientTable.estimatedRowHeight = 140;
    
  [self configureDatabase];
  [self configureStorage];
  [self configureRemoteConfig];
  [self fetchConfig];
  [self loadAd];
  [self logViewLoaded];
}

- (void)dealloc {
    [_ref removeAllObservers];
}

- (void)configureDatabase {
    
    
    _ref = [[FIRDatabase database] reference];
    
    
    
    //get current user
    FIRUser *user = [FIRAuth auth].currentUser;
    //add user to DB
    [[[_ref child:@"users"] child:user.uid]
     setValue:@{@"username": user.displayName}];
    
    
    // -------------Listener for messages in current group-------------
    _refHandle = [[[[_ref child:@"groups"] child: @"gggggg"] child:@"messages"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
        [_clientTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation: UITableViewRowAnimationAutomatic];
        [_clientTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
}

- (void) onGroupChanged {
    
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

- (void)configureRemoteConfig {
}

- (void)fetchConfig {
}
- (IBAction)didSendMessage:(UIButton *)sender {
  [self textFieldShouldReturn:_textField];
}

- (void)logViewLoaded {
}

- (void)loadAd {
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewWillDisappear:(BOOL)animated {
}

// UITableViewDataSource protocol methods
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
    NSString *imageURL = message[MessageFieldsimageURL];
    
    if([name isEqualToString: [FIRAuth auth].currentUser.displayName]){
        cell = (MessageCellTableViewCell *)[_clientTable dequeueReusableCellWithIdentifier:@"MessageCellOwn" forIndexPath:indexPath];
 
    }else{
        cell = (MessageCellTableViewCell *)[_clientTable dequeueReusableCellWithIdentifier:@"MessageCellOther" forIndexPath:indexPath];
    }
    
    if (imageURL) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      //cell.imageView.image = [UIImage imageWithData:data];
                                                                      [tableView reloadData];
                                                                  }];
        } else {
            //cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
        //cell.textLabel.text = [NSString stringWithFormat:@"sent by: %@", name];
    } else {
        NSString *text = message[MessageFieldstext];
        cell.message.text = [NSString stringWithFormat:@"%@: %@", name, text];
        cell.avatar.image = [UIImage imageNamed: @"ic_account_circle"]; //commented out
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
    }
    
    //Turn the Imageview into a circle with the help of invisible borders.
    cell.avatar.layer.cornerRadius = cell.avatar.frame.size.height /2;
    cell.avatar.layer.masksToBounds = YES;
    cell.avatar.layer.borderWidth = 0;
    
    //[cell.avatar setFrame:CGRectMake(100, cell., cell.avatar.frame.size.width, cell.avatar.frame.size.height)];
   
    
    const CGFloat *colors = CGColorGetComponents([tableView.backgroundColor CGColor]);
    
    cell.backgroundColor = tableView.backgroundColor;
    
   /* if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.05 green:colors[1] - 0.05 blue:colors[2] - 0.05 alpha:colors[3]];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:colors[0] - 0.025 green:colors[1] - 0.025 blue:colors[2] - 0.025 alpha:colors[3]];
    }*/

    return cell;
}

// UITextViewDelegate protocol methods
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
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:now];
    
    mdata[@"time"] = newDateString;

    
    // Push data to Firebase Database
    [[[[[_ref child:@"groups"] child: @"gggggg"] child:@"messages"] childByAutoId] setValue:mdata];
}

# pragma mark - Image Picker

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

- (IBAction)signOut:(UIButton *)sender {
    /*
    FIRAuth *firebaseAuth = [FIRAuth auth];
    NSError *signOutError;
    BOOL status = [firebaseAuth signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
     */
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDestructive handler:nil];
    [alert addAction:dismissAction];
    [self presentViewController:alert animated: true completion: nil];
  });
}

@end
