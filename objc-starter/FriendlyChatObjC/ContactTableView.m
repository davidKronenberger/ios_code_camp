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

@implementation ContactTableView

- (void) layoutSubviews {
    [super layoutSubviews];
    
    // Tell the table view the estimated height of a cell.
    self.rowHeight = UITableViewAutomaticDimension;
    self.estimatedRowHeight = 140;
    
    // The delegate and datasource of the table view is the table view.
    self.delegate = self;
    self.dataSource = self;
    
    [self setNeedsDisplay];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    // Currently we have just one section.
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView
  numberOfRowsInSection: (NSInteger) section {
    return [self.contactsForTableView count];
}

- (UITableViewCell *) tableView: (UITableView *) tableView
          cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    // Dequeue cell.
    ContactTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: @"ContactCell"];
    
    // Load all needed data into the table view cell.
    Contact * contact = (self.contactsForTableView)[indexPath.row];
    cell.name.text = contact.name;
    
    cell.lastMessage.text = [contact getLastMessageText];
    cell.avatar.image = (UIImage *)contact.image;
    
    // Toggle background color dependent on row index.
    if (indexPath.row % 2 == 1) {
        cell.backgroundColor = [UIColor colorWithRed: 0.85
                                               green: 0.95
                                                blue: 0.85
                                               alpha: 0.5];
    } else {
        cell.backgroundColor = [UIColor colorWithRed: 0.85
                                               green: 0.95
                                                blue: 0.85
                                               alpha: 0.25];
    }
    
    return cell;
}

- (void)       tableView: (UITableView *) tableView
 didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    // Tell the controller that implements this tableview that a row is selected.
    self.didSelectRowAtIndexPath(indexPath);
}

- (void)         tableView: (UITableView *) tableView
 didDeselectRowAtIndexPath: (nonnull NSIndexPath *) indexPath {
    // Tell the controller that implements this tableview that a row is deselected.
    self.didDeselectRowAtIndexPath(indexPath);
}

@end
