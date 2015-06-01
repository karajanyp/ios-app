//
//  InfinitApplicationSettings.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitApplicationSettings.h"

typedef NS_ENUM(NSUInteger, InfinitSettings)
{
  InfinitSettingAddressBookUploaded,
  InfinitSettingAskedNotifications,
  InfinitSettingBeenLaunched,
  InfinitSettingLoginMethod,
  InfinitSettingRatedApp,
  InfinitSettingRatingTransactions,
  InfinitSettingSendToSelfOnboarded,
  InfinitSettingUsername,
  InfinitSettingWelcomeOnboarded,
  // Home onboarding
  InfinitSettingHomeOnboardedNotifications,
  InfinitSettingHomeOnboardedSwipe,
  InfinitSettingHomeOnboardedNormalSend,
  InfinitSettingHomeOnboardedGhostSend,
  InfinitSettingHomeOnboardedSelfSend,
  InfinitSettingHomeOnboardedBackground,
};

@interface InfinitApplicationSettings ()

@property (atomic) NSUserDefaults* defaults;

@end

static InfinitApplicationSettings* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation InfinitApplicationSettings

#pragma mark - Init

- (id)init
{
  NSCAssert(_instance == nil, @"Use the sharedInstance");
  if (self = [super init])
  {
    _defaults = [NSUserDefaults standardUserDefaults];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitApplicationSettings alloc] init];
  });
  return _instance;
}

#pragma mark - Settings

- (void)resetOnboarding
{
  self.home_onboarded_swipe = NO;
  self.home_onboarded_notifications = NO;
  self.home_onboarded_normal_send = NO;
  self.home_onboarded_ghost_send = NO;
  self.home_onboarded_self_send = NO;
  self.home_onboarded_background = NO;
  self.rated_app = NO;
  self.rating_transactions = @2;
  self.send_to_self_onboarded = @0;
  self.welcome_onboarded = @0;
}

- (BOOL)address_book_uploaded
{
  return [self boolForKey:InfinitSettingAddressBookUploaded];
}

- (void)setAddress_book_uploaded:(BOOL)address_book_uploaded
{
  [self setBool:address_book_uploaded forKey:InfinitSettingAddressBookUploaded];
}

- (BOOL)asked_notifications
{
  return [self boolForKey:InfinitSettingAskedNotifications];
}

- (void)setAsked_notifications:(BOOL)asked_notifications
{
  [self setBool:asked_notifications forKey:InfinitSettingAskedNotifications];
}

- (BOOL)been_launched
{
  return [self boolForKey:InfinitSettingBeenLaunched];
}

- (InfinitLoginMethod)login_method
{
  NSNumber* res = [self.defaults valueForKey:[self keyForSetting:InfinitSettingLoginMethod]];
  if (res)
    return res.unsignedIntegerValue;
  else
    return InfinitLoginNone;
}

- (void)setLogin_method:(InfinitLoginMethod)login_method
{
  [self.defaults setValue:@(login_method) forKey:[self keyForSetting:InfinitSettingLoginMethod]];
}

- (void)setBeen_launched:(BOOL)been_launched
{
  [self setBool:been_launched forKey:InfinitSettingBeenLaunched];
}

- (BOOL)rated_app
{
  return [self boolForKey:InfinitSettingRatedApp];
}

- (void)setRated_app:(BOOL)rated_app
{
  [self setBool:rated_app forKey:InfinitSettingRatedApp];
}

- (NSNumber*)rating_transactions
{
  return [self.defaults valueForKey:[self keyForSetting:InfinitSettingRatingTransactions]];
}

- (void)setRating_transactions:(NSNumber*)rating_transactions
{
  [self.defaults setValue:rating_transactions
                   forKey:[self keyForSetting:InfinitSettingRatingTransactions]];
}

- (NSNumber*)send_to_self_onboarded
{
  return [self.defaults valueForKey:[self keyForSetting:InfinitSettingSendToSelfOnboarded]];
}

- (void)setSend_to_self_onboarded:(NSNumber*)send_to_self_onboarded
{
  [self.defaults setValue:send_to_self_onboarded
                   forKey:[self keyForSetting:InfinitSettingSendToSelfOnboarded]];
}

- (NSString*)username
{
  return [self.defaults valueForKey:[self keyForSetting:InfinitSettingUsername]];
}

- (void)setUsername:(NSString*)username
{
  [self.defaults setValue:username.lowercaseString
                   forKey:[self keyForSetting:InfinitSettingUsername]];
}

- (NSNumber*)welcome_onboarded
{
  return [self.defaults valueForKey:[self keyForSetting:InfinitSettingWelcomeOnboarded]];
}

- (void)setWelcome_onboarded:(NSNumber*)welcome_onboarded
{
  [self.defaults setValue:welcome_onboarded
                   forKey:[self keyForSetting:InfinitSettingWelcomeOnboarded]];
}

#pragma mark - Home Onboarding

- (BOOL)home_onboarded_notifications
{
  return [self boolForKey:InfinitSettingHomeOnboardedNotifications];
}

- (void)setHome_onboarded_notifications:(BOOL)home_onboarded_notifications
{
  [self setBool:home_onboarded_notifications forKey:InfinitSettingHomeOnboardedNotifications];
}

- (BOOL)home_onboarded_swipe
{
  return [self boolForKey:InfinitSettingHomeOnboardedSwipe];
}

- (void)setHome_onboarded_swipe:(BOOL)home_onboarded_swipe
{
  [self setBool:home_onboarded_swipe forKey:InfinitSettingHomeOnboardedSwipe];
}

- (BOOL)home_onboarded_normal_send
{
  return [self boolForKey:InfinitSettingHomeOnboardedNormalSend];
}

- (void)setHome_onboarded_normal_send:(BOOL)home_onboarded_normal_send
{
  [self setBool:home_onboarded_normal_send forKey:InfinitSettingHomeOnboardedNormalSend];
}

- (BOOL)home_onboarded_ghost_send
{
  return [self boolForKey:InfinitSettingHomeOnboardedGhostSend];
}

- (void)setHome_onboarded_ghost_send:(BOOL)home_onboarded_ghost_send
{
  [self setBool:home_onboarded_ghost_send forKey:InfinitSettingHomeOnboardedGhostSend];
}

- (BOOL)home_onboarded_self_send
{
  return [self boolForKey:InfinitSettingHomeOnboardedSelfSend];
}

- (void)setHome_onboarded_self_send:(BOOL)home_onboarded_self_send
{
  [self setBool:home_onboarded_self_send forKey:InfinitSettingHomeOnboardedSelfSend];
}

- (BOOL)home_onboarded_background
{
  return [self boolForKey:InfinitSettingHomeOnboardedBackground];
}

- (void)setHome_onboarded_background:(BOOL)home_onboarded_background
{
  [self setBool:home_onboarded_background forKey:InfinitSettingHomeOnboardedBackground];
}

#pragma mark - Enum

- (NSString*)keyForSetting:(InfinitSettings)setting
{
  switch (setting)
  {
    case InfinitSettingAddressBookUploaded:
      return @"address_book_uploaded";
    case InfinitSettingAskedNotifications:
      return @"asked_notifications";
    case InfinitSettingBeenLaunched:
      return @"been_launched";
    case InfinitSettingLoginMethod:
      return @"login_method";
    case InfinitSettingRatedApp:
      return @"rated_app";
    case InfinitSettingRatingTransactions:
      return @"rating_transactions";
    case InfinitSettingSendToSelfOnboarded:
      return @"send_to_self_onboarded";
    case InfinitSettingUsername:
      return @"username";
    case InfinitSettingWelcomeOnboarded:
      return @"welcome_onboarded";
    case InfinitSettingHomeOnboardedBackground:
      return @"home_onboarded_background";
    case InfinitSettingHomeOnboardedGhostSend:
      return @"home_onboarded_ghost_send";
    case InfinitSettingHomeOnboardedNotifications:
      return @"home_onboarded_notifications";
    case InfinitSettingHomeOnboardedSwipe:
      return @"home_onboarded_swipe";
    case InfinitSettingHomeOnboardedNormalSend:
      return @"home_onboarded_normal_send";
    case InfinitSettingHomeOnboardedSelfSend:
      return @"home_onboarded_self_send";

    default:
      NSCAssert(false, @"Missing application settings key.");
  }
}

#pragma mark - Helpers

- (BOOL)boolForKey:(InfinitSettings)key
{
  NSNumber* res = [self.defaults valueForKey:[self keyForSetting:key]];
  if (res == nil)
    return NO;
  return res.boolValue;
}

- (void)setBool:(BOOL)value forKey:(InfinitSettings)key
{
  [self.defaults setValue:@(value) forKey:[self keyForSetting:key]];
}

@end
