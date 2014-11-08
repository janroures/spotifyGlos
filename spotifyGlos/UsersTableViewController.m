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

@interface UsersTableViewController ()

@property(strong,nonatomic)NSMutableArray *usersArray;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    self.usersArray=[NSMutableArray arrayWithArray:[query findObjects]];
}

-(void)viewDidAppear:(BOOL)animated{
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    self.usersArray=[NSMutableArray arrayWithArray:[query findObjects]];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    JSLSonosViewController *vc=[segue destinationViewController];
    NSIndexPath *selectedIndexPath=[self.tableView indexPathForSelectedRow];
    PFObject *newUser=self.usersArray[selectedIndexPath.row];
    if ([[newUser objectForKey:@"name"]isEqual:@"Jan"]) {
        NSString *retrievedUserName=[newUser objectForKey:@"name"];
        BOOL retrievedIsAdmin;
        if ([[newUser objectForKey:@"isAdmin"]isEqual:@1]) {
            retrievedIsAdmin=YES;
        }else{
            retrievedIsAdmin=NO;
        }
        NSNumber *retrievedtimesAdmin=[newUser objectForKey:@"timesAdmin"];
        NSNumber *retrievedreceivedUpvotes=[newUser objectForKey:@"receivedUpvotes"];
        NSNumber *retrievedreceivedDownvotes=[newUser objectForKey:@"receivedDownvotes"];
        NSMutableArray *retrievedtopSongs=[NSMutableArray arrayWithArray:[newUser objectForKey:@"topSongs"]];
        User *janUser=[[User alloc]initWithUserName:retrievedUserName isAdmin:retrievedIsAdmin timesAdmin:retrievedtimesAdmin receivedUpvotes:retrievedreceivedUpvotes receivedDownvotes:retrievedreceivedDownvotes topSongs:retrievedtopSongs];
        vc.user=janUser;
        
    }else if ([[newUser objectForKey:@"name"]isEqual:@"Louis"]){
        NSString *retrievedUserName=[newUser objectForKey:@"name"];
        BOOL retrievedIsAdmin;
        if ([[newUser objectForKey:@"isAdmin"]isEqual:@1]) {
            retrievedIsAdmin=YES;
        }else{
            retrievedIsAdmin=NO;
        }
        NSNumber *retrievedtimesAdmin=[newUser objectForKey:@"timesAdmin"];
        NSNumber *retrievedreceivedUpvotes=[newUser objectForKey:@"receivedUpvotes"];
        NSNumber *retrievedreceivedDownvotes=[newUser objectForKey:@"receivedDownvotes"];
        NSMutableArray *retrievedtopSongs=[NSMutableArray arrayWithArray:[newUser objectForKey:@"topSongs"]];
        User *louisUser=[[User alloc]initWithUserName:retrievedUserName isAdmin:retrievedIsAdmin timesAdmin:retrievedtimesAdmin receivedUpvotes:retrievedreceivedUpvotes receivedDownvotes:retrievedreceivedDownvotes topSongs:retrievedtopSongs];
        vc.user=louisUser;
    }else{
        NSString *retrievedUserName=[newUser objectForKey:@"name"];
        BOOL retrievedIsAdmin;
        if ([[newUser objectForKey:@"isAdmin"]isEqual:@1]) {
            retrievedIsAdmin=YES;
        }else{
            retrievedIsAdmin=NO;
        }
        NSNumber *retrievedtimesAdmin=[newUser objectForKey:@"timesAdmin"];
        NSNumber *retrievedreceivedUpvotes=[newUser objectForKey:@"receivedUpvotes"];
        NSNumber *retrievedreceivedDownvotes=[newUser objectForKey:@"receivedDownvotes"];
        NSMutableArray *retrievedtopSongs=[NSMutableArray arrayWithArray:[newUser objectForKey:@"topSongs"]];
        User *sumaUser=[[User alloc]initWithUserName:retrievedUserName isAdmin:retrievedIsAdmin timesAdmin:retrievedtimesAdmin receivedUpvotes:retrievedreceivedUpvotes receivedDownvotes:retrievedreceivedDownvotes topSongs:retrievedtopSongs];
        vc.user=sumaUser;
    }
    vc.usersArray=self.usersArray;
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
