//
//  AutoAutoLayout.m
//  autoAutoLayout
//
//  Created by Cathy Chen on 11/2/14.
//  Copyright (c) 2014 Cathy Chen. All rights reserved.
//

#import "AutoAutoLayout.h"

@implementation AutoAutoLayout

+ (void)reLayoutAllSubviewsFromBase:(NSString *)iPhoneModel forSubviewsOf:(UIView *)selfDotView
{
    NSArray *arrayOfUIView = selfDotView.subviews;
    [AutoAutoLayout reLayoutSubviewFromArray:arrayOfUIView fromBaseModel:iPhoneModel forSubviewsOf:selfDotView];
}


+ (void) reLayoutSubviewFromArray:(NSArray *)UIViewSubviewsArray fromBaseModel:(NSString *)baseiPhoneModel forSubviewsOf:(UIView *)selfDotView
{
    CGPoint baseModel = [AutoAutoLayout getPhoneDimension:baseiPhoneModel];
    NSString *userModelName = [AutoAutoLayout getUsersPhoneModel:selfDotView];
    CGPoint userModel = [AutoAutoLayout getPhoneDimension:userModelName];
    CGPoint multiple = [AutoAutoLayout getMultipleFrom:baseModel toNewPhone:userModel];
    
    for (UIView *subview in UIViewSubviewsArray)
    {
        
        CGFloat newX = subview.frame.origin.x * multiple.x;
        CGFloat newY = subview.frame.origin.y * multiple.y;
        CGFloat newWidth = subview.frame.size.width * multiple.x;
        CGFloat newHeight = subview.frame.size.height * multiple.y;
        
        CGFloat constWidth = subview.frame.size.width / baseModel.x;
        CGFloat constHght = subview.frame.size.height / baseModel.y;
        
        
        NSLayoutConstraint *originPositionX =
        [NSLayoutConstraint constraintWithItem:subview
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:selfDotView
                                     attribute:NSLayoutAttributeLeft                                    multiplier:1.0
                                      constant:newX];
        
        NSLayoutConstraint *originPositionY =
        [NSLayoutConstraint constraintWithItem:subview
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:selfDotView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:newY];
        
        NSLayoutConstraint *newWidthAuto =
        [NSLayoutConstraint constraintWithItem:subview
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:selfDotView
                                     attribute:NSLayoutAttributeWidth
                                    multiplier:constWidth
                                      constant:0];
        
        NSLayoutConstraint *newHghtAuto =
        [NSLayoutConstraint constraintWithItem:subview
                                     attribute:NSLayoutAttributeHeight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:selfDotView
                                     attribute:NSLayoutAttributeHeight
                                    multiplier:constHght
                                      constant:0];
        
        
        
        [selfDotView addConstraints:@[originPositionX, originPositionY, newWidthAuto, newHghtAuto]];
        
    }
    
}


+ (NSString *)getUsersPhoneModel:(UIView *)userView
{
    CGFloat userScreenWidth = userView.frame.size.width;
    CGFloat userScreenHeight = userView.frame.size.height;
    
    if (userScreenWidth == 320)
    {
        if (userScreenHeight == 480)
        {
            return @"4s";
        }
        else if (userScreenHeight == 568)
        {
            return @"5s";
        }
        else
        {
            NSLog(@"THOU SHALL NOT GET HERE.");
            return @"err";
        }
    }
    else if (userScreenWidth == 375)
    {
        return @"6";
    }
    else if (userScreenWidth == 414)
    {
        return @"6plus";
    }
    else
    {
        NSLog(@"THOU SHALL NOT GET HERE.");
        return @"err";
        
    }
}



+ (CGPoint)getPhoneDimension:(NSString *)phoneModel
{
    CGPoint iphone4 = CGPointMake(320, 480);
    CGPoint iphone5 = CGPointMake(320, 568);
    CGPoint iphone6 = CGPointMake(375, 667);
    CGPoint iphone6plus = CGPointMake(414, 736);
    
    if ([phoneModel isEqualToString:@"4"] || [phoneModel isEqualToString:@"4s"])
    {
        return iphone4;
    }
    else if ([phoneModel isEqualToString:@"5"] || [phoneModel isEqualToString:@"5s"])
    {
        return iphone5;
    }
    else if ([phoneModel isEqualToString:@"6"])
    {
        return iphone6;
    }
    else if ([phoneModel isEqualToString:@"6+"] || [phoneModel isEqualToString:@"6plus"] || [phoneModel isEqualToString:@"6 plus"])
    {
        return iphone6plus;
    }
    else
    {
        NSLog(@"ERROR: INVALID INPUT OF IPHONE MODEL; will not re-layout.");
        return CGPointMake(1, 1);
    }
}


+ (CGPoint)getMultipleFrom:(CGPoint)phone1 toNewPhone:(CGPoint)phone2
{
    CGFloat layoutMultipleX = phone2.x / phone1.x;
    CGFloat layoutMultipleY = phone2.y / phone1.y;
    
    return CGPointMake(layoutMultipleX, layoutMultipleY);
}





@end
