//
//  InfinitContactViewController.m
//  Infinit
//
//  Created by Christopher Crone on 31/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactViewController.h"

#import "InfinitColor.h"
#import "InfinitHostDevice.h"
#import "InfinitMetricsManager.h"
#import "InfinitTabBarController.h"

#import <Gap/InfinitUserManager.h>

#import "UIImage+Rounded.h"

@interface InfinitContactViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UIImageView* icon_view;
@property (nonatomic, weak) IBOutlet UILabel* name_label;
@property (nonatomic, weak) IBOutlet UIButton* send_invite_button;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_center_constraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* send_size_constraint;
@property (nonatomic, weak) IBOutlet UIButton* favorite_button;
@property (nonatomic, weak) IBOutlet UIView* email_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* email_height;
@property (nonatomic, weak) IBOutlet UILabel* email_address_label;
@property (nonatomic, weak) IBOutlet UIView* phone_view;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* phone_height;
@property (nonatomic, weak) IBOutlet UILabel* phone_label;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint* bar_width_constraint;

@end

static UIImage* _favorite_icon = nil;
static UIImage* _infinit_icon = nil;

@implementation InfinitContactViewController

#pragma mark - Init

- (void)viewDidLoad
{
  if (_favorite_icon == nil)
    _favorite_icon = [UIImage imageNamed:@"icon-badge-favorite-big"];
  if (_infinit_icon == nil)
    _infinit_icon = [UIImage imageNamed:@"icon-badge-infinit-big"];
  [super viewDidLoad];

  self.send_invite_button.layer.cornerRadius = self.send_invite_button.bounds.size.height / 2.0f;
  self.favorite_button.layer.cornerRadius = self.favorite_button.bounds.size.height / 2.0f;
  self.favorite_button.imageEdgeInsets = UIEdgeInsetsMake(0.0f, -8.0f, 0.0f, 0.0f);
  self.favorite_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -2.0f);
  self.send_invite_button.imageEdgeInsets = UIEdgeInsetsMake(3.0f, -6.0f, 3.0f, 0.0f);
  self.send_invite_button.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -5.0f);

  self.navigationController.interactivePopGestureRecognizer.enabled = YES;
  self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
  self.bar_width_constraint.constant = self.view.bounds.size.width - (2.0f * 45.0f);
  [self configureView];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.navigationController.interactivePopGestureRecognizer.delegate = nil;
  [super viewWillDisappear:animated];
}

- (IBAction)backButtonTapped:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureView;
{
  self.navigationItem.title = self.contact.fullname;
  self.avatar_view.image = [self.contact.avatar circularMaskOfSize:self.avatar_view.bounds.size];
  if (self.contact.infinit_user == nil)
  {
    self.icon_view.hidden = YES;
    [self setFavoriteButtonHidden:YES];
    self.email_view.hidden = !(self.contact.emails.count > 0);
    self.email_height.constant = self.contact.emails.count > 0 ? 55.0f : 0.0f;
    self.phone_view.hidden =
      !(self.contact.phone_numbers.count > 0) && [InfinitHostDevice canSendSMS];
    self.phone_height.constant = self.contact.phone_numbers.count > 0 ? 55.0f : 0.0f;
    NSMutableString* email_str = [[NSMutableString alloc] init];
    NSUInteger count = 0;
    for (NSString* email in self.contact.emails)
    {
      [email_str appendString:email];
      if (++count < self.contact.emails.count)
        [email_str appendString:@", "];
    }
    NSMutableString* phone_str = [[NSMutableString alloc] init];
    count = 0;
    for (NSString* number in self.contact.phone_numbers)
    {
      [phone_str appendString:number];
      if (++count < self.contact.phone_numbers.count)
        [phone_str appendString:@", "];
    }
    self.email_address_label.text = email_str;
    self.phone_label.text = phone_str;
  }
  else
  {
    self.email_view.hidden = YES;
    self.phone_view.hidden = YES;
    if (self.contact.infinit_user.favorite || self.contact.infinit_user.is_self)
    {
      self.icon_view.image = _favorite_icon;
      [self setFavoriteButtonFavorite:YES];
    }
    else
    {
      self.icon_view.image = _infinit_icon;
      [self setFavoriteButtonFavorite:NO];
    }
    self.icon_view.hidden = NO;
    [self setFavoriteButtonHidden:self.contact.infinit_user.is_self];
  }
  self.name_label.text = self.contact.fullname;
}

- (void)setFavoriteButtonHidden:(BOOL)hidden
{
  self.send_center_constraint.constant = hidden ? 0.0f : 61.0f;
  self.favorite_button.hidden = hidden;
}

- (void)setFavoriteButtonFavorite:(BOOL)favorite
{
  NSString* text = favorite ? NSLocalizedString(@"UNFAVORITE", nil)
                            : NSLocalizedString(@"FAVORITE", nil);
  [self.favorite_button setTitle:text forState:UIControlStateNormal];
}

#pragma mark - Button Handling

- (IBAction)sendButtonTapped:(id)sender
{
  InfinitTabBarController* tab_controller = (InfinitTabBarController*)self.tabBarController;
  [tab_controller showSendScreenWithContact:self.contact];
}

- (IBAction)favoriteButtonTapped:(id)sender
{
  if (self.contact.infinit_user == nil)
    return;
  if (self.contact.infinit_user.is_self)
    return;
  UIImage* new_icon;
  if (self.contact.infinit_user.favorite)
  {
    new_icon = _infinit_icon;
    [self setFavoriteButtonFavorite:NO];
    [InfinitMetricsManager sendMetric:InfinitUIEventContactViewFavorite
                               method:InfinitUIMethodRemove];
  }
  else
  {
    new_icon = _favorite_icon;
    [self setFavoriteButtonFavorite:YES];
    [InfinitMetricsManager sendMetric:InfinitUIEventContactViewFavorite
                               method:InfinitUIMethodAdd];
  }

  [UIView transitionWithView:self.icon_view
                    duration:0.3f
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^
  {
    self.icon_view.image = new_icon;
  } completion:^(BOOL finished)
  {
    if (!finished)
      self.icon_view.image = new_icon;
  }];
  if (self.contact.infinit_user.favorite)
    [[InfinitUserManager sharedInstance] removeFavorite:self.contact.infinit_user];
  else
    [[InfinitUserManager sharedInstance] addFavorite:self.contact.infinit_user];
}

@end
