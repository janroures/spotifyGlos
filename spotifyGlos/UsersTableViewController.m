//
//  UsersTableViewController.m
//  spotifyGlos
//
//  Created by Jan Roures Mintenig on 6/11/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.
//

#import "UsersTableViewController.h"
#import "User.h"
#import "SonosController.h"
#import "JSLSonosViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <RNBlurModalView.h>
#import "AppDelegate.h"

static NSString * const kSpotifyAccountType =@"spotify";
static NSString * const kSpotifyClientSecret = @"ea449fa4da8044ad8bcf67e58c30934a";
static NSString * const kSpotifyClientID = @"b1888b168ab341f19b1b6a3e257f76d9";

NSString * const kSpotifyCurrentUserQueryURL = @"https://api.spotify.com/v1/me";

@interface UsersTableViewController () <UIApplicationDelegate>

@property(strong,nonatomic)NSMutableArray *usersArray;

@property(strong,nonatomic)NSString * spotifyToken;
@property(strong,nonatomic)NSString * spotifyUser;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getTheTokenFromAppDelegate) name:@"tokenReady"  object:nil];
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    self.usersArray=[NSMutableArray arrayWithArray:[query findObjects]];
    for (PFObject *object in self.usersArray) {
        if ([[object objectForKey:@"isAdmin"]isEqual:@1]) {
            NSString *currentAdminName=[NSString stringWithFormat:@"The current admin is %@", [object objectForKey:@"name"]];
            RNBlurModalView *alertView=[[RNBlurModalView alloc]initWithTitle:@"Current admin" message:currentAdminName];
            [alertView show];
        }
    }
}

-(void) getTheTokenFromAppDelegate{
    
    self.spotifyToken = [AppDelegate getToken];
    AFHTTPSessionManager *getUserSession = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kSpotifyCurrentUserQueryURL]];
    AFJSONResponseSerializer *jsonDataPlease = [AFJSONResponseSerializer serializer];
    [getUserSession setResponseSerializer:jsonDataPlease];
    
    NSDictionary *parameters = @{ @"Authorization":self.spotifyToken};
    NSURLSessionDataTask *dataTask = [getUserSession GET:@"" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"RESPONSE: %@", responseObject);
        
        //NSLog(@"current user: %@", self.spotifyUser);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"NOT FOUND USER");
    }];
    [dataTask resume];
    
}

-(void)applicationDidBecomeActive:(UIApplication *)application{
    [[[UIApplication sharedApplication] delegate] applicationDidBecomeActive:application];
    NSLog(@"ACTIVE");
    
    [self getTheTokenFromAppDelegate];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [[NSNotificationQueue defaultQueue] dequeueNotificationsMatching:[NSNotification notificationWithName:@"tokenReady" object:self] coalesceMask:0];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    self.usersArray=[NSMutableArray arrayWithArray:[query findObjects]];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.usersArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell" forIndexPath:indexPath];
    PFObject *currentUser=self.usersArray[indexPath.row];
    cell.textLabel.text=[currentUser objectForKey:@"name"];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    JSLSonosViewController *vc=[segue destinationViewController];
    NSIndexPath *selectedIndexPath=[self.tableView indexPathForSelectedRow];
    PFObject *newUser=self.usersArray[selectedIndexPath.row];
    vc.usersArray=self.usersArray;
    vc.currentUserObject=newUser;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */



@end
