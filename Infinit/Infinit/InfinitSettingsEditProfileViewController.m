//
//  InfinitSettingsEditProfileViewController.m
//  Infinit
//
//  Created by Christopher Crone on 06/02/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsEditProfileViewController.h"

#import "InfinitColor.h"
#import "InfinitConstants.h"
#import "InfinitHostDevice.h"
#import "UIImage+Rounded.h"

#import <Gap/InfinitAvatarManager.h>
#import <Gap/InfinitConnectionManager.h>
#import <Gap/InfinitStateManager.h>
#import <Gap/InfinitUserManager.h>

@import MobileCoreServices;

@interface InfinitSettingsEditProfileViewController () <UIActionSheetDelegate,
                                                        UIGestureRecognizerDelegate,
                                                        UIImagePickerControllerDelegate,
                                                        UINavigationControllerDelegate,
                                                        UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem* ok_button;
@property (nonatomic, weak) IBOutlet UIButton* avatar_button;
@property (nonatomic, weak) IBOutlet UIImageView* avatar_view;
@property (nonatomic, weak) IBOutlet UITextField* name_field;
@property (nonatomic, weak) IBOutlet UIView* name_view;

@property (nonatomic, strong, readonly) UIImage* avatar_image;
@property (nonatomic, strong, readonly) UIImagePickerController* picker;
@property (nonatomic, weak) InfinitUser* user;

@property (nonatomic, strong) CAShapeLayer* dark_layer;

@end

@implementation InfinitSettingsEditProfileViewController

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  UIColor* nav_color = [InfinitColor colorWithRed:81 green:81 blue:73];
  NSDictionary* nav_title_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                         size:17.0f],
                                  NSForegroundColorAttributeName: nav_color};
  [self.navigationController.navigationBar setTitleTextAttributes:nav_title_attrs];
  NSDictionary* nav_but_attrs = @{NSFontAttributeName: [UIFont fontWithName:@"SourceSansPro-Bold"
                                                                       size:18.0f],
                                  NSForegroundColorAttributeName: [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna]};
  [self.ok_button setTitleTextAttributes:nav_but_attrs forState:UIControlStateNormal];
  self.name_view.layer.borderColor = [InfinitColor colorWithGray:216].CGColor;
  self.name_view.layer.borderWidth = 1.0f;
  [super viewDidLoad];
  if (self.dark_layer == nil)
  {
    _dark_layer = [CAShapeLayer layer];
    self.dark_layer.opacity = 0.3f;
    self.dark_layer.fillColor = [UIColor blackColor].CGColor;
    self.dark_layer.path =
    [UIBezierPath bezierPathWithRoundedRect:self.avatar_view.bounds
                               cornerRadius:self.avatar_view.bounds.size.width].CGPath;
    [self.avatar_view.layer addSublayer:self.dark_layer];
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  self.user = [InfinitUserManager sharedInstance].me;
  self.name_field.text = self.user.fullname;
  if (self.avatar_image == nil)
  {
    self.avatar_view.image =
      [self.user.avatar infinit_circularMaskOfSize:self.avatar_view.bounds.size];
  }
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  _picker = nil;
  _avatar_image = nil;
  [super viewDidDisappear:animated];
}

#pragma mark - Button Handling

- (IBAction)changeAvatarTapped:(id)sender
{
  [self dismissKeyboard];
  UIActionSheet* actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Back", nil)
                  destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Take new photo", nil),
                                         NSLocalizedString(@"Choose a photo...", nil), nil];
  [actionSheet showInView:self.view];
}

- (void)goBack
{
  if ([InfinitHostDevice iOS7])
    [self.navigationController popViewControllerAnimated:YES];
  else
    [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)backTapped:(id)sender
{
  [self dismissKeyboard];
  [self goBack];
}

- (IBAction)okTapped:(id)sender
{
  [self dismissKeyboard];
  if ([InfinitConnectionManager sharedInstance].connected == NO)
  {
    NSString* title = NSLocalizedString(@"Need a connection!", nil);
    NSString* message =
      NSLocalizedString(@"Unable to edit your profile without an Internet connection.", nil);
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    return;
  }
  if (self.avatar_image != nil)
  {
    [[InfinitAvatarManager sharedInstance] setSelfAvatar:self.avatar_image];
  }
  if (![self.name_field.text isEqualToString:self.user.fullname] &&
      self.name_field.text.length >= 3)
  {
    [[InfinitStateManager sharedInstance] setSelfFullname:self.name_field.text
                                          performSelector:nil
                                                 onObject:nil];
    self.user.fullname = [self.name_field.text copy];
  }
  [self goBack];
}

- (IBAction)screenTap:(id)sender
{
  [self dismissKeyboard];
}

- (IBAction)webProfileTap:(id)sender
{
  NSMutableString* url_str = [kInfinitWebProfileURL mutableCopy];
  NSString* session_id = [InfinitStateManager sharedInstance].metaSessionId;
  if (session_id.length)
    [url_str appendFormat:@"&session_id=%@", session_id];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url_str]];
}

#pragma mark - Avatar Picker

- (void)actionSheet:(UIActionSheet*)actionSheet
didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  NSString* choice = [actionSheet buttonTitleAtIndex:buttonIndex];
  if([choice isEqualToString:NSLocalizedString(@"Choose a photo...", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
  }
  if([choice isEqualToString:NSLocalizedString(@"Take new photo", nil)])
  {
    [self presentImagePicker:UIImagePickerControllerSourceTypeCamera];
  }
}

- (void)presentImagePicker:(UIImagePickerControllerSourceType)sourceType
{
  if (self.picker == nil)
    _picker = [[UIImagePickerController alloc] init];
  self.picker.view.tintColor = [UIColor blackColor];
  self.picker.sourceType = sourceType;
  self.picker.mediaTypes = @[(NSString*)kUTTypeImage];
  self.picker.allowsEditing = YES;
  self.picker.delegate = self;
  if (sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
  }
  [self presentViewController:self.picker animated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController*)picker
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  _avatar_image = info[UIImagePickerControllerEditedImage];
  [self dismissViewControllerAnimated:YES completion:nil];
  self.avatar_view.image =
    [self.avatar_image infinit_circularMaskOfSize:self.avatar_view.bounds.size];
  [self.avatar_view setNeedsDisplay];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
  [self dismissKeyboard];
  return YES;
}

#pragma mark - Keyboard

- (void)dismissKeyboard
{
  if (self.name_field.isFirstResponder)
  {
    [self.name_field endEditing:YES];
    [self keyboardEntryDone];
  }
}

- (void)keyboardWillShow:(NSNotification*)notification
{
  CGFloat delta = -30.0f;
  if (![InfinitHostDevice smallScreen])
    delta -= 30.0f;
  [UIView animateWithDuration:0.2f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.view.transform = CGAffineTransformMakeTranslation(0.0f, delta);
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.view.transform = CGAffineTransformMakeTranslation(0.0f, delta);
     }
   }];
}

- (void)keyboardEntryDone
{
  [UIView animateWithDuration:0.2f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^
   {
     self.view.transform = CGAffineTransformIdentity;
   } completion:^(BOOL finished)
   {
     if (!finished)
     {
       self.view.transform = CGAffineTransformIdentity;
     }
   }];
}

@end
