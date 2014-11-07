//
//  AutoAutoLayout.h
//  autoAutoLayout
//
//  Created by Cathy Chen on 11/2/14.
//  Copyright (c) 2014 Cathy Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AutoAutoLayout : NSObject

+ (void)reLayoutAllSubviewsFromBase:(NSString *)iPhoneModel forSubviewsOf:(UIView *)selfDotView;

+ (void)reLayoutSubviewFromArray:(NSArray *)UIViewSubviewsArray fromBaseModel:(NSString *)baseiPhoneModel forSubviewsOf:(UIView *)selfDotView;


+ (NSString *)getUsersPhoneModel:(UIView *)userView;
+ (CGPoint)getPhoneDimension:(NSString *)phoneModel;
+ (CGPoint)getMultipleFrom:(CGPoint)phone1 toNewPhone:(CGPoint)phone2;


@end
