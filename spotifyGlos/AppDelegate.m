//
//  AppDelegate.m
//  spotifyGlos
//
//  Created by Louis Tur on 10/31/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.
//

#import "AppDelegate.h"
#import "SonosManager.h"
#import <Parse/Parse.h>
#import <AFNetworking/AFNetworking.h>


static NSString * const kSpotifyAccountType =@"spotify";
static NSString * const kSpotifyClientSecret = @"ea449fa4da8044ad8bcf67e58c30934a";
static NSString * const kSpotifyClientID = @"b1888b168ab341f19b1b6a3e257f76d9";

// -- (SPOTIFY) spotifyURIS --//
static NSString * const kSpotifyAuthURI = @"https://accounts.spotify.com/authorize";
static NSString * const kSpotifyRedirectURI = @"glos://returnAfterAuth";

// -- (SPOTIFY) Token       --//
static NSString * kSpotifyToken=@"";

@interface AppDelegate ()

-(void) createAuthSessionForSpotify;
-(void)createSessionTokenWithURL:(NSURL *)authResponseURL;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [Parse setApplicationId:@"5HQQuuB7Oo85wgcQuOElTPyy81aexHCttCSf5OIi"
                  clientKey:@"5xAP2COeyMvEXg62DvnU1LtsHOFd5x7ZZjhRMO6s"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // -- Spotify auth methods --//
    [self performSelector:@selector(createAuthSessionForSpotify) onThread:[NSThread mainThread] withObject:self waitUntilDone:YES];
    // -- Spotify auth methods --//
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) createAuthSessionForSpotify{
    
    AFURLSessionManager * urlSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    //-- Oh you fancy? Maybe next release will have a basic hash --//
    //NSNumber * hashKey = [NSNumber numberWithInteger:[[NSDate date] hash]];
    //@"state"          :[hashKey stringValue], // --- maybe add if all else is working
    NSDictionary * jsonRequestParameters = @{ @"client_id"      :kSpotifyClientID,
                                              @"response_type"  :@"token",
                                              @"redirect_uri"   :[NSURL URLWithString:kSpotifyRedirectURI],
                                              @"scope"          :@[@"streaming",@"user-read-private"],
                                              @"show_dialog"    :@"true"
                                              };
    
    AFJSONRequestSerializer *jsonRequestWhyNot = [AFJSONRequestSerializer serializer];
    NSMutableURLRequest * spotifyRequest = [jsonRequestWhyNot requestWithMethod:@"GET"
                                                                      URLString:kSpotifyAuthURI
                                                                     parameters:jsonRequestParameters
                                                                          error:nil];
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:spotifyRequest completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        /*
         //NSLog(@"**** THE RESPONSE:\n\n %@", response);
         if ([NSJSONSerialization isValidJSONObject:responseObject]) {
         //NSLog(@"Went to DisneyLand, got JSON");
         }
         //NSLog(@"**** THe RESPONSEOBJECT: %@", jsonObj);
         */
        if (error) {
            NSLog(@"OH SHIT< ERRRORS: %@", error);
        }
    }];
    [dataTask resume];
    
    //-- this method is called on the NSURLSessionDelegate, which is set and handled by AFNetworking
    [urlSession setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response) {
        NSLog(@"Data task did receive response");
        // this method is needed to detect a response after creating the NSURLSessionDataTask
        // When the response is heard, we pass the appropriate authorization URL to Safari
        [[UIApplication sharedApplication] openURL:response.URL];
        
        // lastly we allow this response to continue on by returning this enum value
        return NSURLSessionResponseAllow;
    }];
    
    
    //-- example of a URLRequest URL: --//
    /*
     https://accounts.spotify.com/authorize?client_id=b1888b168ab341f19b1b6a3e257f76d9&scope=streaming%20user-library-read%20user-read-private%20user-read-email&redirect_uri=glos%3A%2F%2FreturnAfterAuth&download_prompt=true&response_type=code
     */
    
    //-- OAuth2 Flow for Implicit Authorization --//
    //-- the below were all used for diagnostic reasons, uncomment to see the flow in action.
    /*
     *  1) dataTask is launched
     *      1a. app enters background and Safari opens
     *  2) Safari loads with NSURLRequest containing kSpotifyAuthURL + @params
     *      2a. The params are a dictionary of keys/values defined by
     *          https://developer.spotify.com/web-api/authorization-guide/ (Implicit Auth Flow)
     *  3) Authentication begins on https://accounts.spotify.com/authorize (kSpotifyAuthURL)
     *      3a. User is given the choice of FB or User/Pass
     *          i. User can auth or decline, active status is returned to App (implementation to handle
     *             declined requests or expired tokens not in place... so don't try it!)
     *      3b. On subsequent auth calls, users will be detected as "logged in" and just asked to
     *          click on the Authorize button again (user/pass not needed)
     *  4) The kSpotifyRedirectURL points back to this App with a JSON response containing the token
     *  5) Token is stored for further API calls
     *
     */
    /*
     [urlSession setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
     NSLog(@"Data task received data");
     NSLog(@"Data from in the delegate Method: %@", [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
     NSLog(@"Additional Stuff? Is this the redirect? :\n\n ");
     NSLog(@"The NSURLSession: %@", session);
     NSLog(@"The Data task returned: %@", dataTask);
     
     }];
     
     [urlSession setDataTaskDidBecomeDownloadTaskBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask) {
     NSLog(@"Did become download task");
     
     }];
     
     [urlSession setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
     //will do this at some point...
     
     NSLog(@"Performing Redirect Block");
     return [NSURLRequest requestWithURL:nil];
     }];
     [urlSession setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *credential) {
     
     NSLog(@"Did receive auth challenge");
     return NSURLSessionAuthChallengeUseCredential;
     }];
     [urlSession setDataTaskDidBecomeDownloadTaskBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask) {
     
     NSLog(@"Data task did become download task block");
     }];
     [urlSession setTaskDidSendBodyDataBlock:^(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
     NSLog(@" Did send body data block");
     }];*/
    
}
-(void)createSessionTokenWithURL:(NSURL *)authResponseURL{
    NSString *baseURLString = [authResponseURL absoluteString];
    kSpotifyToken = [[baseURLString stringByReplacingOccurrencesOfString:@"glos://returnAfterAuth#access_token=" withString:@""] stringByReplacingOccurrencesOfString:@"&token_type=Bearer&expires_in=3600" withString:@""];
    NSLog(@"Final token: %@", kSpotifyToken);
}
+(NSString *)getToken{
    return kSpotifyToken;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    NSLog(@"In call back delegate");
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"tokenReady" object:self] postingStyle:0];
    //-- this has to be added (and make this class a UIApplicationDelegate)
    //-- In order to properly handle the redirect URL
    if ( [[url absoluteString] hasPrefix:kSpotifyRedirectURI]) {
        NSLog(@"%@", [url absoluteString]);
        
        [self createSessionTokenWithURL:url];
        
    }
    return YES;
}


@end
