//
//  InfinitFilesCollectionCell_iPad.m
//  Infinit
//
//  Created by Christopher Crone on 16/04/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitFilesCollectionCell_iPad.h"

#import "InfinitFilePreview.h"

#import <Gap/InfinitTime.h>

@import AVFoundation;

@implementation InfinitFilesCollectionCell_iPad

- (void)awakeFromNib
{
  self.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)configureForFile:(InfinitFileModel*)file
           withThumbnail:(UIImage*)thumb
{
  if ([self.path isEqualToString:file.path])
  {
    self.thumbnail_view.image = thumb;
    return;
  }
  _path = file.path;
  self.thumbnail_view.image = thumb;
  self.h_constraint.constant = thumb.size.height;
  self.w_constraint.constant = thumb.size.width;
  if (file.type == InfinitFileTypeVideo)
  {
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:[[NSURL alloc] initFileURLWithPath:file.path]
                                            options:nil];
    if (asset)
    {
      self.duration_label.text = [InfinitTime stringFromDuration:CMTimeGetSeconds(asset.duration)];
      self.video_view.hidden = NO;
    }
  }
  else
  {
    self.video_view.hidden = YES;
  }
}

- (void)updateThumbnail:(UIImage*)thumb
{
  self.thumbnail_view.image = thumb;
  self.h_constraint.constant = thumb.size.height;
  self.w_constraint.constant = thumb.size.width;
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  self.select_view.hidden = !selected;
}

@end
