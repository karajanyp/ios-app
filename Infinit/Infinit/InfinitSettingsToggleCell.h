//
//  InfinitSettingsToggleCell.h
//  Infinit
//
//  Created by Christopher Crone on 22/06/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfinitSettingsToggleCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* title_label;
@property (nonatomic, weak) IBOutlet UILabel* info_label;
@property (nonatomic, weak) IBOutlet UISwitch* switch_element;

@end
