//
//  InfinitContactManager.m
//  Infinit
//
//  Created by Christopher Crone on 28/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitContactManager.h"

#import "InfinitApplicationSettings.h"
#import "InfinitContact.h"
#import "InfinitHostDevice.h"

#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>
#import <Gap/NSString+email.h>
#import <Gap/NSString+PhoneNumber.h>

#import <AddressBook/AddressBook.h>

#undef check
#import <elle/log.hh>

ELLE_LOG_COMPONENT("iOS.ContactManager");

@interface InfinitContactManager ()

@property (atomic, readwrite) NSArray* contact_cache;

@end

static InfinitContactManager* _instance = nil;
static dispatch_once_t _instance_token = 0;
static dispatch_once_t _got_access_token = 0;

@implementation InfinitContactManager

- (instancetype)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newUser:)
                                                 name:INFINIT_NEW_USER_NOTIFICATION 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearModel)
                                                 name:INFINIT_CLEAR_MODEL_NOTIFICATION 
                                               object:nil];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[InfinitContactManager alloc] init];
  });
  return _instance;
}

- (void)clearModel
{
  _got_access_token = 0;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (NSArray*)allContacts
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
  {
    NSString* status = nil;
    switch (ABAddressBookGetAuthorizationStatus())
    {
      case kABAuthorizationStatusNotDetermined:
        status = @"not determined";
        break;
      case kABAuthorizationStatusRestricted:
        status = @"restricted";
        break;
      case kABAuthorizationStatusDenied:
        status = @"denied";
        break;

      default:
        status = @"unknown";
        break;
    }
    ELLE_WARN("%s: unable to access contacts, authorization status: %s",
              self.description.UTF8String, status.UTF8String);
    return nil;
  }
  NSMutableArray* res = [NSMutableArray array];
  CFErrorRef* error = nil;
  ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, error);
  CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(address_book);
  // Array containing record ids that have been fetched.
  NSMutableArray* fetched_records = [NSMutableArray array];
  for (int i = 0; i < CFArrayGetCount(sources); i++)
  {
    ABRecordRef source = CFArrayGetValueAtIndex(sources, i);
    CFArrayRef contacts =
      ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(address_book,
                                                                source,
                                                                kABPersonSortByFirstName);
    for (int j = 0; j < CFArrayGetCount(contacts); j++)
    {
      ABRecordRef person = CFArrayGetValueAtIndex(contacts, j);
      if (person)
      {
        int32_t record_id = ABRecordGetRecordID(person);
        if ([fetched_records containsObject:@(record_id)])
          continue;
        InfinitContactAddressBook* contact = [InfinitContactAddressBook contactWithABRecord:person];
        if (contact != nil && (contact.emails.count || (contact.phone_numbers.count)))
          [res addObject:contact];
        [fetched_records addObject:@(contact.address_book_id)];
        [fetched_records addObjectsFromArray:contact.linked_address_book_ids];
      }
    }
    CFRelease(contacts);
  }
  CFRelease(sources);
  CFRelease(address_book);
  NSSortDescriptor* sort =
    [[NSSortDescriptor alloc] initWithKey:@"fullname"
                                ascending:YES
                                 selector:@selector(caseInsensitiveCompare:)];
  [res sortUsingDescriptors:@[sort]];
  self.contact_cache = [NSArray arrayWithArray:res];
  NSMutableArray* exclusions = [NSMutableArray array];
  if (![InfinitHostDevice canSendSMS])
  {
    for (InfinitContactAddressBook* contact in res)
    {
      if (!contact.emails.count)
        [exclusions addObject:contact];
    }
  }
  [res removeObjectsInArray:exclusions];
  return res;
}

- (void)gotAddressBookAccess
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  dispatch_once(&_got_access_token, ^
  {
    NSArray* contacts = [[InfinitContactManager sharedInstance] allContacts];
    [[InfinitContactManager sharedInstance] fetchGhostData];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
    {
      NSMutableArray* upload_array = [NSMutableArray array];
      [contacts enumerateObjectsUsingBlock:^(InfinitContactAddressBook* contact,
                                             NSUInteger i,
                                             BOOL* stop)
       {
         [upload_array addObject:[self dictForContact:contact]];
       }];
      if ([InfinitApplicationSettings sharedInstance].address_book_uploaded)
        return;
      [[InfinitStateManager sharedInstance] uploadContacts:upload_array
                                           completionBlock:^(InfinitStateResult* result)
      {
        if (result.success)
          [InfinitApplicationSettings sharedInstance].address_book_uploaded = YES;
      }];
    });
  });
}

- (void)fetchGhostData
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  NSMutableArray* ghosts = [NSMutableArray array];
  NSArray* swaggers = [InfinitUserManager sharedInstance].alphabetical_swaggers;
  for (InfinitUser* user in swaggers)
  {
    if (user.ghost)
      [ghosts addObject:user];
  }
  if (ghosts.count == 0)
    return;
  for (InfinitUser* ghost in ghosts)
  {
    [self tryUpdateGhost:ghost];
  }
}

- (InfinitContactAddressBook*)contactForUser:(InfinitUser*)user
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return nil;
  if (!self.contact_cache)
    [self allContacts];
  NSString* email = nil;
  NSString* phone = nil;
  if (user.ghost_identifier.infinit_isEmail)
    email = user.ghost_identifier;
  else if (user.ghost_identifier.infinit_isPhoneNumber)
    phone = [self strippedNumber:user.ghost_identifier];

  if (!email && !phone)
    return nil;

  __block InfinitContactAddressBook* res = nil;
  [self.contact_cache enumerateObjectsUsingBlock:^(InfinitContactAddressBook* contact,
                                                   NSUInteger i,
                                                   BOOL* stop)
  {
    if (contact.emails.count && [contact.emails containsObject:email])
    {
      res = contact;
      *stop = YES;
    }
    else if (contact.phone_numbers.count)
    {
      for (NSString* contact_phone in contact.phone_numbers)
      {
        NSString* stripped_number = [self strippedNumber:contact_phone];
        if ([stripped_number isEqualToString:phone])
        {
          res = contact;
          *stop = YES;
          break;
        }
      }
    }
  }];
  return res;
}

- (InfinitContactAddressBook*)contactForIdentifier:(NSString*)identifier
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return nil;
  if (!self.contact_cache)
    [self allContacts];
  __block InfinitContactAddressBook* res = nil;
  [self.contact_cache enumerateObjectsUsingBlock:^(InfinitContactAddressBook* contact,
                                                   NSUInteger i,
                                                   BOOL* stop)
   {
     if (contact.emails.count &&
         identifier.infinit_isEmail &&
         [contact.emails containsObject:identifier.infinit_cleanEmail])
     {
       res = contact;
       *stop = YES;
     }
     else if (contact.phone_numbers.count && identifier.infinit_isPhoneNumber)
     {
       for (NSString* contact_phone in contact.phone_numbers)
       {
         if ([[self strippedNumber:contact_phone] isEqualToString:[self strippedNumber:identifier]])
         {
           res = contact;
           *stop = YES;
           break;
         }
       }
     }
   }];
  return res;
}

#pragma mark - New User

- (void)newUser:(NSNotification*)notification
{
  if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized)
    return;
  if (_got_access_token == 0)
    return;
  NSNumber* user_id = notification.userInfo[kInfinitUserId];
  InfinitUser* user = [[InfinitUserManager sharedInstance] userWithId:user_id];
  if (!user.ghost)
    return;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
  {
    [self tryUpdateGhost:user];
  });
}

#pragma mark - Helpers

- (NSDictionary*)dictForContact:(InfinitContactAddressBook*)contact
{
  NSArray* email_addresses = contact.emails ? contact.emails : @[];
  NSArray* phone_numbers = contact.phone_numbers ? contact.phone_numbers : @[];
  return @{@"email_addresses": email_addresses, @"phone_numbers": phone_numbers};
}

- (NSString*)strippedNumber:(NSString*)number
{
  return [number stringByReplacingOccurrencesOfString:@"[^0-9]"
                                           withString:@""
                                              options:NSRegularExpressionSearch
                                                range:NSMakeRange(0, number.length)];
}

- (void)tryUpdateGhost:(InfinitUser*)ghost
{
  if (!self.contact_cache)
    [self allContacts];

  NSString* email = nil;
  NSString* phone = nil;
  if (ghost.fullname.infinit_isEmail)
    email = ghost.fullname;
  else if (ghost.fullname.infinit_isPhoneNumber)
    phone = [self strippedNumber:ghost.fullname];

  if (!email && !phone)
    return;

  [self.contact_cache enumerateObjectsUsingBlock:^(InfinitContactAddressBook* contact,
                                                   NSUInteger i,
                                                   BOOL* stop)
  {
    if (contact.emails.count && [contact.emails containsObject:email])
    {
      [ghost updateGhostWithFullname:contact.fullname avatar:contact.avatar];
      *stop = YES;
    }
    else if (contact.phone_numbers.count)
    {
      for (NSString* contact_phone in contact.phone_numbers)
      {
        NSString* stripped_number = [self strippedNumber:contact_phone];
        if ([stripped_number isEqualToString:phone])
        {
          [ghost updateGhostWithFullname:contact.fullname avatar:contact.avatar];
          *stop = YES;
          break;
        }
      }
    }
  }];
}

@end
