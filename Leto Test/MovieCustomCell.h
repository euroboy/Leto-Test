//
//  MovieCustomCellTableViewCell.h
//  Leto Test
//
//  Created by Radoo on 03/02/15.
//  Copyright (c) 2015 Radoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieCustomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *filmThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *filmTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *filmYearLabel;

@end
