//
//  UIView+FrameGetters.h
//  zenGarden
//
//  Created by Louis Tur on 10/30/14.
//  Copyright (c) 2014 The Flatiron School. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FrameGetters)

-(CGRect) myFrame;
-(CGPoint) myOrigins;
-(CGSize) myDimensions;

-(CGFloat) myX;
-(CGFloat) myY;
-(CGFloat) myWidth;
-(CGFloat) myHeight;
-(CGPoint) myCenter;

-(CGFloat) myDistanceFromCenterToFurthestCorner;

@end
