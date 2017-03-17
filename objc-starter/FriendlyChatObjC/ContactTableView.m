//
//  ContactTableView.m
//  FriendlyChatObjC
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

#import "ContactTableView.h"
#import "ContactTableViewCell.h"
#import "Contact.h"
#import "DatabaseSingelton.h"

@implementation ContactTableView

- (void) layoutSubviews {
    [super layoutSubviews];
    
    self.rowHeight = UITableViewAutomaticDimension;
    self.estimatedRowHeight = 140;
    
    self.delegate = self;
    self.dataSource = self;
    
    [self setNeedsDisplay];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Currently we have just one section.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self._contactsForTableView count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    //load all needed data into the tableView cell
    Contact *contact = (self._contactsForTableView)[indexPath.row];
    cell.name.text = contact.name;
    cell.lastMessage.text = [contact.messages lastObject];
    cell.avatar.image = (UIImage *)contact.image;
    
    //Turn the Imageview into a circle with the help of invisible borders.
    cell.avatar.layer.cornerRadius = cell.avatar.frame.size.height /2;
    cell.avatar.layer.masksToBounds = YES;
    cell.avatar.layer.borderWidth = 0;
    cell.avatar.layer.borderColor = [[UIColor blackColor] CGColor];
    
    if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.85 alpha:0.5];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.25];
    }
    
    return cell;
}

//this is called when a user touches a cell from the tableview
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.didSelectRowAtIndexPath(indexPath);
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    self.didDeselectRowAtIndexPath(indexPath);
}

@end
