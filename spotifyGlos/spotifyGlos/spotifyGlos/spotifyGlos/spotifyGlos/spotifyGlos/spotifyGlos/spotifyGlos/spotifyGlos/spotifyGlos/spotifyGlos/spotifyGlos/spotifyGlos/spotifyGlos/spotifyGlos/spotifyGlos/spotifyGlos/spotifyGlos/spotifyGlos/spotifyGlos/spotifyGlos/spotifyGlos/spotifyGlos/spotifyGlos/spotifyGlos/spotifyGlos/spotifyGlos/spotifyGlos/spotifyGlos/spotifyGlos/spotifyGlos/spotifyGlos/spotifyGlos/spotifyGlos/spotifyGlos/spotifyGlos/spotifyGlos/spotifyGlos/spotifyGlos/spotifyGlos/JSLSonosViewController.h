//
//  JSLSonosViewController.h
//  spotifyGlos
//
//  Created by Louis Tur on 10/31/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "User.h"

@interface JSLSonosViewController : UIViewController

@property(strong,nonatomic)NSMutableArray *usersArray;
@property(strong,nonatomic)NSMutableArray *usersWhoAreNotAdminsArray;
@property(strong,nonatomic)PFObject *currentUserObject;

@end
