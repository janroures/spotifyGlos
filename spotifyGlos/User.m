//
//  User.m
//  spotifyGlos
//
//  Created by Jan Roures Mintenig on 6/11/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.
//

#import "User.h"

@implementation User


-(instancetype)init{
    return [self initWithUserName:nil isAdmin:NO timesAdmin:nil receivedUpvotes:nil receivedDownvotes:nil topSongs:nil];
}

-(instancetype)initWithUserName:(NSString *)username isAdmin:(BOOL)isadmin timesAdmin:(NSNumber *)timesadmin receivedUpvotes:(NSNumber *)receivedupvotes receivedDownvotes:(NSNumber *)receiveddownvotes topSongs:(NSMutableArray *)topsongs{
    self=[super init];
    if (self) {
        _userName=username;
        _isAdmin=isadmin;
        _timesAdmin=timesadmin;
        _receivedUpvotes=receivedupvotes;
        _receivedDownvotes=receiveddownvotes;
        _topSongs=[NSMutableArray arrayWithArray:topsongs];
    }
    return self;
}

@end
