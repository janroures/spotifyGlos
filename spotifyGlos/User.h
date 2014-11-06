//
//  User.h
//  spotifyGlos
//
//  Created by Jan Roures Mintenig on 6/11/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property(strong,nonatomic)NSString *userName;
@property(nonatomic)BOOL isAdmin;
@property(strong,nonatomic)NSNumber *timesAdmin;
@property(strong,nonatomic)NSNumber *receivedUpvotes;
@property(strong,nonatomic)NSNumber *receivedDownvotes;
@property(strong,nonatomic)NSMutableArray *topSongs;

-(instancetype)init;
-(instancetype)initWithUserName:(NSString *)username isAdmin:(BOOL)isadmin timesAdmin:(NSNumber *)timesadmin receivedUpvotes:(NSNumber *)receivedupvotes receivedDownvotes:(NSNumber *)receiveddownvotes topSongs:(NSMutableArray *)topsongs;



@end
