//
//  InfinitHostDevice.h
//  Infinit
//
//  Created by Christopher Crone on 21/01/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Ordered in increasing power.
typedef NS_ENUM(NSUInteger, InfinitCPUTypes)
{
  InfinitCPUType_Unknown = 0,
  InfinitCPUType_ARM_Unknown,
  InfinitCPUType_ARM_v7,
  InfinitCPUType_ARM_v7f,
  InfinitCPUType_ARM_v7s,
  InfinitCPUType_ARM64_Unknown,
  InfinitCPUType_ARM64_v8,
  InfinitCPUType_x86,
};

@interface InfinitHostDevice : NSObject

+ (InfinitCPUTypes)deviceCPU;
+ (NSString*)deviceCPUDescription;

+ (CGFloat)screenScale;
+ (BOOL)smallScreen;

@end