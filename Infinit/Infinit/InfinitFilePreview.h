//
//  InfinitFilePreview.h
//  Infinit
//
//  Created by Christopher Crone on 26/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InfinitFileTypes)
{
  InfinitFileTypeAudio,
  InfinitFileTypeImage,
  InfinitFileTypePDF,
  InfinitFileTypeVideo,

  InfinitFileTypeOther,
};

@interface InfinitFilePreview : NSObject

+ (InfinitFileTypes)fileTypeForPath:(NSString*)path;

+ (UIImage*)previewForPath:(NSString*)path
                    ofSize:(CGSize)size
                      crop:(BOOL)crop;

@end