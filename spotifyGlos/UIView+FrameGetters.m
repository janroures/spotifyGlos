//
//  UIView+FrameGetters.m
//  zenGarden
//
//  Created by Louis Tur on 10/30/14.
//  Copyright (c) 2014 The Flatiron School. All rights reserved.
//

#import "UIView+FrameGetters.h"

@implementation UIView (FrameGetters)

-(CGRect)myFrame{
    return self.frame;
}

-(CGPoint)myOrigins{
    return self.frame.origin;
}

-(CGSize)myDimensions{
    return self.frame.size;
}

-(CGFloat)myX{
    return self.frame.origin.x;
}

-(CGFloat)myY{
    return self.frame.origin.y;
}

-(CGFloat)myWidth{
    return self.frame.size.width;
}

-(CGFloat)myHeight{
    return self.frame.size.height;
}

-(CGPoint)myCenter{
    return CGPointMake( CGRectGetMidX(self.frame) ,  CGRectGetMidY(self.frame) );
}

-(CGFloat)myDistanceFromCenterToFurthestCorner{
    CGPoint furthestCorner = CGPointZero;
    CGFloat xDist = fabs((self.center.x - furthestCorner.x));
    CGFloat yDist = fabs((self.center.x - furthestCorner.y));
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

@end
