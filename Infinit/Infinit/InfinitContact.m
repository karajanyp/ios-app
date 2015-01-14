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
  BOOL _inited_with_addressbook;
}

#pragma mark Init

- (id)initWithABRecord:(ABRecordRef)record
{
  if (self = [super init])
  {
    _inited_with_addressbook = YES;
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
    _fullname = [NSString stringWithString:name_str];

    NSData* image_data =
      (__bridge NSData*)(ABPersonCopyImageDataWithFormat(record, kABPersonImageFormatThumbnail));
    _avatar = [UIImage imageWithData:image_data scale:1.0f];
    if (self.avatar == nil)
      [self generateAvatarWithFirstName:first_name surname:surname];
  }
  return self;
}

- (id)initWithInfinitUser:(InfinitUser*)user
{
  if (self = [super init])
  {
    _inited_with_addressbook = NO;
    _infinit_user = user;
    _avatar = user.avatar;
    _emails = nil;
    _fullname = user.fullname;
    _phone_numbers = nil;
  }
  return self;
}

#pragma mark General

- (void)addInfinitUser:(InfinitUser*)user
{
  if (!_inited_with_addressbook)
    return;
  _infinit_user = user;
}

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

#pragma mark Helpers

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@> emails: %@\rnumbers: %@\rinfinit:%@",
          self.fullname, self.emails, self.phone_numbers, self.infinit_user];
}

@end