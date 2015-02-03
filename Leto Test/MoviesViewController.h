//
//  MoviesViewController.h
//  Leto Test
//
//  Created by Radoo on 03/02/15.
//  Copyright (c) 2015 Radoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoviesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *filmSearchBar;
@property (weak, nonatomic) IBOutlet UILabel *openingFilmsLabel;
@property (weak, nonatomic) IBOutlet UITableView *filmsTableView;

- (IBAction)sortButtonPressed:(id)sender;
- (IBAction)segmentValueChanged:(UISegmentedControl*)sender;

@end
