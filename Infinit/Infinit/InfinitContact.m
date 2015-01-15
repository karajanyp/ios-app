//
//  InfinitContact.m
//  Infinit
//
//  Created by Christopher Crone on 12/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContact.h"

#import "InfinitColor.h"

@implementation InfinitContact
{
@private
  BOOL _inited_with_infinit_user;
}

#pragma mark - Init

- (id)initWithABRecord:(ABRecordRef)record
{
  if (self = [super init])
  {
    _inited_with_infinit_user = NO;
    _infinit_user = nil;

    ABMultiValueRef email_property = ABRecordCopyValue(record, kABPersonEmailProperty);
    _emails = (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(email_property);
    CFRelease(email_property);

    ABMultiValueRef phone_property = ABRecordCopyValue(record, kABPersonPhoneProperty);
    _phone_numbers = (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(phone_property);
    CFRelease(phone_property);

    if (self.emails.count == 0 && self.phone_numbers.count == 0)
      return nil;

    NSString* first_name = (__bridge NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString* surname = (__bridge NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    NSMutableString* name_str = [[NSMutableString alloc] init];
    if (first_name.length > 0)
    {
      [name_str appendString:first_name];
      if (surname.length > 0)
        [name_str appendFormat:@" %@", surname];
    }
    else if (surname.length > 0)
    {
      [name_str appendString:surname];
    }
    else
    {
      if (self.emails.count > 0)
        [name_str appendString:self.emails[0]];
      else if (self.phone_numbers.count > 0)
        [name_str appendString:self.phone_numbers[0]];
      else
        [name_str appendString:NSLocalizedString(@"Unknown", nil)];
    }
    _first_name = first_name;
    _fullname = [NSString stringWithString:name_str];

    NSData* image_data =
      (__bridge NSData*)(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
    _avatar = [UIImage imageWithData:image_data scale:1.0f];
    if (self.avatar == nil)
      [self generateAvatarWithFirstName:first_name surname:surname];
  }
  return self;
}

- (id)initWithEmail:(NSString*)email_
{
  if (self = [super init])
  {
    NSString* email =
      [email_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].lowercaseString;
    _inited_with_infinit_user = NO;
    _infinit_user = nil;
    _avatar = nil;
    _emails = @[email];
    _selected_email_index = 0;
    _fullname = email;
    _first_name = email;
    _phone_numbers = nil;
  }
  return self;
}

- (id)initWithInfinitUser:(InfinitUser*)user
{
  if (self = [super init])
  {
    _inited_with_infinit_user = YES;
    _infinit_user = user;
    _avatar = user.avatar;
    _emails = nil;
    if (user.is_self)
      _fullname = NSLocalizedString(@"Me", nil);
    else
      _fullname = user.fullname;
    NSArray* temp = [self.fullname componentsSeparatedByString:@" "];
    if (temp.count > 0 && [temp[0] length] > 0)
      _first_name = temp[0];
    else
      _first_name = self.fullname;
    _phone_numbers = nil;
  }
  return self;
}

#pragma mark - General

- (void)generateAvatarWithFirstName:(NSString*)first_name
                            surname:(NSString*)surname
{
  UIColor* fill = [InfinitColor colorFromPalette:ColorShamRock];
  CGRect rect = CGRectMake(0.0f, 0.0f, 80.0f, 80.0f);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [fill setFill];
  CGContextFillRect(context, rect);
  [[UIColor whiteColor] set];
  NSMutableString* text = [[NSMutableString alloc] init];
  if (first_name.length > 0)
  {
    [text appendFormat:@"%c", [first_name characterAtIndex:0]];
    if (surname.length > 0)
      [text appendFormat:@"%c", [surname characterAtIndex:0]];
  }
  else if (self.emails.count > 0)
  {
    [text appendString:@"@"];
  }
  else
  {
    [text appendString:@" "];
  }
  NSDictionary* attrs = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light"
                                                               size:34.0f],
                          NSForegroundColorAttributeName: [UIColor whiteColor]};
  NSAttributedString* str = [[NSAttributedString alloc] initWithString:text attributes:attrs];
  [str drawAtPoint:CGPointMake(round((rect.size.width - str.size.width) / 2.0f),
                               round((rect.size.height - str.size.height) / 2.0f))];
  self.avatar = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
}

#pragma mark - Helpers

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> emails: %@\rnumbers: %@\rinfinit:%@",
          self.fullname, self.emails, self.phone_numbers, self.infinit_user];
}

#pragma mark - Comparison

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:self.class])
    return NO;
  InfinitContact* other = (InfinitContact*)object;
  if ([self.infinit_user isEqual:other.infinit_user])
    return YES;
  if ([self.emails isEqualToArray:other.emails])
    return YES;
  if ([self.fullname isEqualToString:other.fullname])
    return YES;
  return NO;
}

#pragma mark - Search

- (BOOL)containsSearchString:(NSString*)search_string
{
  NSUInteger score = 0;
  NSString* trimmed_string = search_string;
    [search_string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSArray* components = [trimmed_string componentsSeparatedByString:@" "];
  for (NSString* component in components)
  {
    if ([self source:self.fullname containsString:component] ||
        [self emails:self.emails containString:component] ||
        (self.infinit_user != nil &&
         [self source:self.infinit_user.handle containsString:component]))
    {
      score++;
    }
  }
  if (score == components.count)
    return YES;
  return NO;
}

- (BOOL)source:(NSString*)source
containsString:(NSString*)string
{
  if ([source rangeOfString:string options:NSCaseInsensitiveSearch].location == NSNotFound)
    return NO;
  return YES;
}

- (BOOL)emails:(NSArray*)emails
 containString:(NSString*)string
{
  if (emails == nil)
    return NO;
  for (NSString* email in emails)
  {
    if ([self source:email containsString:string])
      return YES;
  }
  return NO;
}

@end
