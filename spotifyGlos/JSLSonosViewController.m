//
//  JSLSonosViewController.m
//  spotifyGlos
//
//  Created by Louis Tur on 10/31/14.
//  Copyright (c) 2014 com.Spotify. All rights reserved.

#import "JSLSonosViewController.h"
#import "SonosManager.h"
#import "UIView+FrameGetters.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIKit/UIDevice.h>
#import <AutoAutoLayout.h>
#import "SonosController.h"
#import <RNBlurModalView.h>
#import "SearchDisplayTableViewController.h"
#import "Songs.h"
#import "SongTableCellTableViewCell.h"


@interface JSLSonosViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

//Actions
- (IBAction)showCurrentDeviceInfo:(id)sender;
- (IBAction)playTrack:(id)sender;
- (IBAction)previousSong:(id)sender;
- (IBAction)voteUp:(id)sender;
- (IBAction)voteDown:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)volumeSlider:(id)sender;

//Search
@property(strong,nonatomic)UISearchController *searchController;
@property(strong,nonatomic) SearchDisplayTableViewController *resultsTable;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property(strong,nonatomic) UITableView *hiddenTableView;
@property (strong, nonatomic) NSArray *songs;
@property (strong, nonatomic) NSArray *searchResults;

//View outlets
@property (weak, nonatomic) IBOutlet UIButton *voteUpButton;
@property (weak, nonatomic) IBOutlet UIButton *voteDownButton;
@property (weak, nonatomic) IBOutlet UIButton *nextSongButton;
@property (weak, nonatomic) IBOutlet UIButton *previousSongButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *votesDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *votesUpLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumArt;
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonContainer;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) SonosManager *sonosManager;
@property (strong, nonatomic) __block SonosController *currentDevice;
@property (strong, nonatomic) __block NSMutableDictionary *currentSong;
@property (strong, nonatomic) __block UIImage *albumImage;
@property (nonatomic) __block NSInteger currentVolume;

@property(strong,nonatomic)AFNetworkReachabilityManager *reachabilityManager;
@property(strong,nonatomic)AFHTTPSessionManager *sessionManager;

/*
 User stuff
 
 user stuff declared in .h because we need to access it from the TableVC
 
 User stuff ends
 */

@property (strong, nonatomic) NSArray *devices;
@property (strong, nonatomic) __block NSMutableDictionary *songInfo;

@end

@implementation JSLSonosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden=NO;

    
//Auto Auto-layout
    [self.view removeConstraints:self.view.constraints];
    [AutoAutoLayout reLayoutAllSubviewsFromBase:@"4s" forSubviewsOf:self.view];
    
//CATransition for blocks
    __block CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.75;
    
//Query for users who are not admins
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"isAdmin=%@", [NSNumber numberWithBool:NO]];
    PFQuery *query=[PFQuery queryWithClassName:@"Users" predicate:predicate];
    self.usersWhoAreNotAdminsArray=[NSMutableArray arrayWithArray:[query findObjects]];
    
//Init session and reachibility managers
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"www.google.com"] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.reachabilityManager=[AFNetworkReachabilityManager sharedManager];
    [self.reachabilityManager startMonitoring];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (![AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi ) {
            NSLog(@"%ld", status);
        }else{
            NSLog(@"You're on wifi");
        }
    }];
    
//Initializing search tableView and and textView delegates
    [self.view addSubview:self.hiddenTableView];
    self.resultsTable = [SearchDisplayTableViewController new];
    self.searchController = [[UISearchController alloc]initWithSearchResultsController:self.resultsTable];
    self.hiddenTableView.dataSource = self;
    self.hiddenTableView.delegate = self;
    self.searchTextField.delegate = self;
    [self.searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
//Volume Slider
    self.volumeSlider.minimumValue=0;
    self.volumeSlider.maximumValue=100;
    self.volumeSlider.maximumTrackTintColor=[UIColor blackColor];
    self.volumeSlider.minimumTrackTintColor=[UIColor blackColor];
    self.volumeSlider.thumbTintColor=[UIColor blackColor];
    
//Init sonosManager and sonosController --also setting up volume slider current volume--
    //self.songInfo = [[NSMutableDictionary alloc] init];
    self.sonosManager = [SonosManager sharedInstance];
    //NSDictionary *currentDeviceInfo = [NSDictionary dictionaryWithDictionary:self.sonosManager.allDevices[0]];
    //    self.currentDevice = [[SonosController alloc] initWithIP:currentDeviceInfo[@"ip"] port:1400 owner:self.currentUserObject];
    self.currentDevice = [[SonosController alloc] initWithIP:@"192.168.2.160" port:1400 owner:self.currentUserObject];
    [self.currentDevice getVolume:^(NSInteger currentVolume, NSError *err) {
        [self.volumeSlider.layer addAnimation:animation forKey:@"kCATransitionFade"];
        self.volumeSlider.value=currentVolume;
    }];
    
//Set up album art, song label, artist label
    
    __block NSDictionary *blockDictionary = [[NSDictionary alloc] init];
    [self.currentDevice trackInfo:^(NSDictionary * returnData, NSError *error){
        if (!error) {
            blockDictionary = [NSDictionary dictionaryWithDictionary:returnData];
            self.currentSong = [NSMutableDictionary dictionaryWithDictionary:blockDictionary];
            [self.songNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.artistNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.albumArt.layer addAnimation:animation forKey:@"kCATransitionFade"];
            self.songNameLabel.text = self.currentSong[@"MetaDataTitle"];
            self.artistNameLabel.text = self.currentSong[@"MetaDataCreator"];
//            [self.albumArt setImageWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
            NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
            [self.albumArt setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                self.albumArt.image = image;
                NSLog(@"Success");
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                [self.albumArt setImageWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
            }];
            NSLog(@"Album Art URI view controller: %@", self.currentSong[@"MetaDataAlbumArtURI"]);
        }else{
            NSLog(@"There was an error getting the current track\n\nThe errors: %@", error.localizedDescription);
        }
    }];
    NSLog(@"%@", [self.currentDevice class]);
    
//    [self.currentDevice queue:@"x-sonos-spotify:spotify%3atrack%3a5Wa2HI33fErYRuAEHZJmf9" completion:^(NSDictionary *responseDict, NSError *err) {
//        NSLog(@"Song added to queue: %@", responseDict);
//    }];
    
//Set pause/play button image depending on the current song status
    [self.currentDevice status:^(NSDictionary *statusResult, NSError *error) {
        if ([statusResult[@"CurrentTransportState"] isEqual:@"PAUSED_PLAYBACK"] ) {
            [self.playButton.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.playButton setImage:[UIImage imageNamed:@"playbutton2.jpeg"] forState:UIControlStateNormal];
            NSLog(@"Paused");
        }else{
            [self.playButton.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.playButton setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
            NSLog(@"Playing");
        }
    }];
    
//Set up control buttons depending on if the current user is an Admin or not
    if ([[self.currentUserObject objectForKey:@"isAdmin"] isEqual:@1]) {
        self.playButton.enabled=YES;
        self.nextSongButton.enabled=YES;
        self.previousSongButton.enabled=YES;
        self.volumeSlider.enabled=YES;
    }else{
        self.playButton.enabled=NO;
        self.nextSongButton.enabled=NO;
        self.previousSongButton.enabled=NO;
        self.volumeSlider.enabled=NO;
    }
    
// Initialize the test songs array
    Songs *song1 = [Songs new];
    song1.artist = @"Mick Jagger And David Bowie";
    song1.song = @"Dancing In The Street";
    
    Songs *song2 = [Songs new];
    song2.artist = @"Weird Al Yankovic";
    song2.song = @"Dare to be Stupid";
    
    Songs *song3 = [Songs new];
    song3.artist = @"Madonna";
    song3.song = @"Dear Jessie";
    
    Songs *song4 = [Songs new];
    song4.artist = @"Culture Club";
    song4.song = @"Do You Really Want To Hurt Me?";

    Songs *song5 = [Songs new];
    song5.artist = @"The Police";
    song5.song = @"Don't Stand So Close to Me - Original";
    
    Songs *song6 = [Songs new];
    song6.artist = @"Bobby McFerrin";
    song6.song = @"Don't Worry, Be Happy";
    
    self.songs = [NSArray arrayWithObjects: song1, song2, song3, song4, song5, song6, nil];

//Query for user who is admin --set up vote labels
    NSPredicate *adminPredicate=[NSPredicate predicateWithFormat:@"isAdmin=%@", [NSNumber numberWithBool:YES]];
    PFQuery *adminQuery=[PFQuery queryWithClassName:@"Users" predicate:adminPredicate];
    NSArray *adminArray=[NSMutableArray arrayWithArray:[adminQuery findObjects]];
    for (PFObject *retrievedAdmin in adminArray) {
        if ([[retrievedAdmin objectForKey:@"isAdmin"]isEqual:@1]) {
            self.votesUpLabel.text=[NSString stringWithFormat:@"%@", [retrievedAdmin objectForKey:@"receivedUpvotes"]];
            self.votesDownLabel.text=[NSString stringWithFormat:@"%@", [retrievedAdmin objectForKey:@"receivedDownvotes"]];
        }
    }
    
//    [self.currentDevice playSpotifyTrack:@"spotify:track:5Wa2HI33fErYRuAEHZJmf9" completion:^(NSDictionary *reponse, NSError *error) {
//        NSLog(@"%@", reponse);
//    }];
    
//viewDidLoad ends
}

//Text field delegates
- (void)textFieldDidChange:(id)sender {
    if (self.searchTextField.text.length == 0) {
        self.hiddenTableView.hidden = YES;
    } else {
        self.hiddenTableView.hidden = NO;
        NSPredicate *resultsPredicate = [NSPredicate predicateWithFormat:@"song CONTAINS[c] %@", self.searchTextField.text];
        self.searchResults = [self.songs filteredArrayUsingPredicate:resultsPredicate];
        [self.hiddenTableView reloadData];
    }
}

#pragma mark - Lazy init
- (UITableView *)hiddenTableView {
    if (_hiddenTableView == nil) {
        _hiddenTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 63, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 63)];
        [_hiddenTableView registerClass:[SongTableCellTableViewCell class] forCellReuseIdentifier:@"searchCell"];
        _hiddenTableView.hidden = YES;
    }
    return _hiddenTableView;
}

#pragma mark - Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SongTableCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell"];
    //    if (self.searchResults.count > 0) {
    Songs *currentSong = self.searchResults[indexPath.row];
    cell.songLabel.text = currentSong.song;
    cell.artistLabel.text = currentSong.artist;
    //    }
    return cell;
}

-(void) setUpConstraints{
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view removeConstraints:self.view.constraints];
    NSDictionary *elementsDictionary = NSDictionaryOfVariableBindings(_albumArt, _songNameLabel, _artistNameLabel);
    NSNumber *centerY = [NSNumber numberWithDouble:CGRectGetMidY(self.view.frame)];
    NSDictionary *metrics = @{ @"frameCenterY" : centerY };

    NSArray *coverArtConstraints = @[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_albumArt]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:elementsDictionary],
                                     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_albumArt]"
                                                                             options:0 metrics:nil
                                                                               views:elementsDictionary],
                                     
                                     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_albumArt(==frameCenterY)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:elementsDictionary]
                                     ];
    
    
    
    [self addConstraints:coverArtConstraints toView:self.view andClearConstraints:NO];
    [self.albumArt setBackgroundColor:[UIColor redColor]];
    
    NSLayoutConstraint *labelXConstraints = [NSLayoutConstraint constraintWithItem:self.artistNameLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0];
    NSLayoutConstraint *labelYConstraints = [NSLayoutConstraint constraintWithItem:self.artistNameLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.albumArt
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:10];
    NSLayoutConstraint *labelWidthConstraints = [NSLayoutConstraint constraintWithItem:self.artistNameLabel
                                                                             attribute:NSLayoutAttributeWidth
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.albumArt
                                                                             attribute:NSLayoutAttributeWidth
                                                                            multiplier:.75
                                                                              constant:0];
    NSLayoutConstraint *labelHeightConstraints = [NSLayoutConstraint constraintWithItem:self.artistNameLabel
                                                                              attribute:NSLayoutAttributeHeight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:nil
                                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                                             multiplier:1.0
                                                                               constant:40];
    [self.view addConstraint:labelXConstraints];
    [self.view addConstraint:labelYConstraints];
    [self.view addConstraint:labelWidthConstraints];
    [self.view addConstraint:labelHeightConstraints];
    [self.artistNameLabel setBackgroundColor:[UIColor blueColor]];
    
    NSLayoutConstraint *songLabelXConstraints = [NSLayoutConstraint constraintWithItem:self.songNameLabel
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.view
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:0];
    
    NSLayoutConstraint *songLabelYConstraints = [NSLayoutConstraint constraintWithItem:self.songNameLabel
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.artistNameLabel
                                                                             attribute:NSLayoutAttributeBottom
                                                                            multiplier:1.0
                                                                              constant:10];
    NSLayoutConstraint *songLabelWidthConstraints = [NSLayoutConstraint constraintWithItem:self.songNameLabel
                                                                                 attribute:NSLayoutAttributeWidth
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.albumArt
                                                                                 attribute:NSLayoutAttributeWidth
                                                                                multiplier:.75
                                                                                  constant:0];
    NSLayoutConstraint *songLabelHeightConstraints = [NSLayoutConstraint constraintWithItem:self.songNameLabel
                                                                                  attribute:NSLayoutAttributeHeight
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                                 multiplier:1.0
                                                                                   constant:40];
    
    [self.view addConstraint:songLabelXConstraints];
    [self.view addConstraint:songLabelYConstraints];
    [self.view addConstraint:songLabelWidthConstraints];
    [self.view addConstraint:songLabelHeightConstraints];
    [self.songNameLabel setBackgroundColor:[UIColor yellowColor]];
    
    NSLayoutConstraint *buttonContainerXConstraints = [NSLayoutConstraint constraintWithItem:self.buttonContainer
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.view
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                  multiplier:1.0
                                                                                    constant:0];
    
    NSLayoutConstraint *buttonContainerYConstraints = [NSLayoutConstraint constraintWithItem:self.buttonContainer
                                                                                   attribute:NSLayoutAttributeTop
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.songNameLabel
                                                                                   attribute:NSLayoutAttributeBottom
                                                                                  multiplier:1.0
                                                                                    constant:10];
    NSLayoutConstraint *buttonContainerWidthConstraints = [NSLayoutConstraint constraintWithItem:self.buttonContainer
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.albumArt
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                      multiplier:.75
                                                                                        constant:0];
    NSLayoutConstraint *buttonContainerHeightConstraints = [NSLayoutConstraint constraintWithItem:self.buttonContainer
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:self.view
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                       multiplier:1.0
                                                                                         constant:-10];
    
    [self.view addConstraint:buttonContainerXConstraints];
    [self.view addConstraint:buttonContainerYConstraints];
    [self.view addConstraint:buttonContainerWidthConstraints];
    [self.view addConstraint:buttonContainerHeightConstraints];
    [self.buttonContainer setBackgroundColor:[UIColor purpleColor]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)addConstraints:(NSArray *)constraints toView:(UIView *) view andClearConstraints:(BOOL) clear{
    //--- clear constraints if you need ---//
    if (clear) {
        [view removeConstraints:view.constraints];
    }
    
    //--- adds each array of layout constraints --//
    for (NSArray *loCst in constraints) {
        [view addConstraints:loCst];
    }
}

-(void)addNonFormattedConstraints:(NSArray*)constraints toView:(UIView* )view{
    for (NSLayoutConstraint *constraint in constraints) {
        [view addConstraint:constraint];
    }
}

- (void)changeAdmin:(PFObject *)currentAdmin {
    NSInteger randomUserFromUsersWhoAreNotAdmins=arc4random_uniform([self.usersArray count]-2);
    PFObject *newUserAdmin=self.usersWhoAreNotAdminsArray[randomUserFromUsersWhoAreNotAdmins];
    [newUserAdmin setObject:[NSNumber numberWithBool:YES] forKey:@"isAdmin"];
    [currentAdmin setObject:[NSNumber numberWithBool:NO] forKey:@"isAdmin"];
    [newUserAdmin saveInBackground];
    [currentAdmin saveInBackground];
    [self.view setNeedsDisplay];
    NSString *newAdminName=[NSString stringWithFormat:@"The new master is %@", [newUserAdmin objectForKey:@"name"]];
    RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"New master!" message:newAdminName];
    [modal show];
}

- (void)resetVotesCount {
    for (PFObject *currentUser in self.usersArray) {
        if (![[currentUser objectForKey:@"isAdmin"]isEqual:@0]) {
            NSInteger upvotes=[[currentUser objectForKey:@"receivedUpvotes"] integerValue];
            NSInteger downvotes=[[currentUser objectForKey:@"receivedDownvotes"] integerValue];
            [currentUser setValue:@0 forKey:@"receivedUpvotes"];
            [currentUser setValue:@0 forKey:@"receivedDownvotes"];
            [currentUser saveInBackground];
            if (upvotes<downvotes){
                [self changeAdmin:currentUser];
            }
        }
    }
}

//used to get the current song and set it to self.currentsong
- (IBAction)showCurrentDeviceInfo:(id)sender {
    __block CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.75;
    __block NSDictionary *blockDictionary = [[NSDictionary alloc] init];
    [self.currentDevice trackInfo:^(NSDictionary * returnData, NSError *error){
        if (!error) {
            blockDictionary = [NSDictionary dictionaryWithDictionary:returnData];
            self.currentSong = [NSMutableDictionary dictionaryWithDictionary:blockDictionary];
            [self.songNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.artistNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
            [self.albumArt.layer addAnimation:animation forKey:@"kCATransitionFade"];
            self.songNameLabel.text = self.currentSong[@"MetaDataTitle"];
            self.artistNameLabel.text = self.currentSong[@"MetaDataCreator"];
            NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
            [self.albumArt setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                self.albumArt.image = image;
                NSLog(@"Success");
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                [self.albumArt setImageWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
            }];
            [self.currentDevice status:^(NSDictionary *statusResult, NSError *error) {
                if ([statusResult[@"CurrentTransportState"] isEqual:@"PAUSED_PLAYBACK"] ) {
                    [self.playButton setImage:[UIImage imageNamed:@"playbutton2.jpeg"] forState:UIControlStateNormal];
                }else{
                    [self.playButton setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
                }
            }];
        }else{
            NSLog(@"There was an error getting the current track\n\nThe errors: %@", error.localizedDescription);
        }
    }];
}

- (IBAction)playTrack:(id)sender {
    //checks the current device status and plays/pauses the song depending on the status
    [self.currentDevice status:^(NSDictionary *statusResult, NSError *error) {
        if ([statusResult[@"CurrentTransportState"] isEqual:@"PAUSED_PLAYBACK"] ) {
            [self.currentDevice play:@"x-sonos-spotify:spotify:track:spotify%3Atrack%3A5Wa2HI33fErYRuAEHZJmf9?sid=12&flags=32" completion:^(NSDictionary *result, NSError *err) {
                [self.playButton setImage:[UIImage imageNamed:@"playbutton2.jpeg"] forState:UIControlStateSelected];
//                 setImage:[UIImage imageNamed:@"playbutton2.jpeg"] forState:UIControlStateNormal];
                NSLog(@"Playing");
            }];
        }else{
            [self.currentDevice pause:^(NSDictionary *result, NSError *err) {
                [self.playButton setImage:[UIImage imageNamed:@"pauseIcon"] forState:UIControlStateSelected];
//                 setImage:[UIImage imageNamed:@"pauseIcon.png"] forState:UIControlStateNormal];
                NSLog(@"Paused");
            }];
        }
    }];
}

- (IBAction)previousSong:(id)sender {
    [self.currentDevice previous:^(NSDictionary *dict, NSError *error) {
        [self resetVotesCount];
        PFQuery *query=[PFQuery queryWithClassName:@"Users"];
        NSArray *users=[query findObjects];
        for (PFObject *currentObject in users) {
            [currentObject setValue:@0 forKey:@"hasVoted"];
            [currentObject saveInBackground];
        }
        __block CATransition *animation = [CATransition animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = kCATransitionFade;
        animation.duration = 0.75;
        __block NSDictionary *blockDictionary = [[NSDictionary alloc] init];
        [self.currentDevice trackInfo:^(NSDictionary * returnData, NSError *error){
            if (!error) {
                blockDictionary = [NSDictionary dictionaryWithDictionary:returnData];
                self.currentSong = [NSMutableDictionary dictionaryWithDictionary:blockDictionary];
                [self.songNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
                [self.artistNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
                [self.albumArt.layer addAnimation:animation forKey:@"kCATransitionFade"];
                self.songNameLabel.text = self.currentSong[@"MetaDataTitle"];
                self.artistNameLabel.text = self.currentSong[@"MetaDataCreator"];
                NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
                [self.albumArt setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    self.albumArt.image = image;
                    NSLog(@"Success");
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    [self.albumArt setImageWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
                }];
            }else{
                NSLog(@"There was an error getting the current track\n\nThe errors: %@", error.localizedDescription);
            }
        }];
        NSLog(@"Previous Song");
    }];
}

- (IBAction)nextSong:(id)sender {
    [self.currentDevice next:^(NSDictionary *dict, NSError *error) {
        [self resetVotesCount];
        PFQuery *query=[PFQuery queryWithClassName:@"Users"];
        NSArray *users=[query findObjects];
        for (PFObject *currentObject in users) {
            [currentObject setValue:@0 forKey:@"hasVoted"];
            [currentObject saveInBackground];
        }
        __block CATransition *animation = [CATransition animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = kCATransitionFade;
        animation.duration = 0.75;
        __block NSDictionary *blockDictionary = [[NSDictionary alloc] init];
        [self.currentDevice trackInfo:^(NSDictionary * returnData, NSError *error){
            if (!error) {
                blockDictionary = [NSDictionary dictionaryWithDictionary:returnData];
                self.currentSong = [NSMutableDictionary dictionaryWithDictionary:blockDictionary];
                [self.songNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
                [self.artistNameLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
                [self.albumArt.layer addAnimation:animation forKey:@"kCATransitionFade"];
                self.songNameLabel.text = self.currentSong[@"MetaDataTitle"];
                self.artistNameLabel.text = self.currentSong[@"MetaDataCreator"];
                NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
                [self.albumArt setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    self.albumArt.image = image;
                    NSLog(@"Success");
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    [self.albumArt setImageWithURL:[NSURL URLWithString:self.currentSong[@"MetaDataAlbumArtURI"]]];
                }];
            }else{
                NSLog(@"There was an error getting the current track\n\nThe errors: %@", error.localizedDescription);
            }
        }];
        NSLog(@"Next Song");
    }];
}

- (IBAction)volumeSlider:(id)sender {
    [self.currentDevice setVolume:self.volumeSlider.value completion:^(NSDictionary *result, NSError *err) {
    }];
}

- (IBAction)voteUp:(id)sender {
    if ([[self.currentUserObject objectForKey:@"isAdmin"] isEqual:@0] && [[self.currentUserObject objectForKey:@"hasVoted"] isEqual:@0]) {
        [self.currentUserObject incrementKey:@"hasVoted"];
        [self.currentUserObject saveInBackground];
        for (PFObject *newUser in self.usersArray) {
            if (![[newUser objectForKey:@"isAdmin"]isEqual:@0]) {
                [newUser incrementKey:@"receivedUpvotes"];
                self.votesUpLabel.text=[NSString stringWithFormat:@"%@", [newUser objectForKey:@"receivedUpvotes"]];
                [self.view setNeedsDisplay];
                [newUser saveInBackground];
            }
        }
    }else{
        if ([[self.currentUserObject objectForKey:@"isAdmin"]isEqual:@1]) {
            RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"Invalid vote!" message:@"You can't vote yourself!"];
            [modal show];
        }else{
            RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"Invalid vote!" message:@"You already voted for this song!"];
            [modal show];
        }
    }
}

- (IBAction)voteDown:(id)sender {
    if ([[self.currentUserObject objectForKey:@"isAdmin"] isEqual:@0] && [[self.currentUserObject objectForKey:@"hasVoted"] isEqual:@0]) {
        [self.currentUserObject incrementKey:@"hasVoted"];
        [self.currentUserObject saveInBackground];
        for (PFObject *newUser in self.usersArray) {
            if (![[newUser objectForKey:@"isAdmin"]isEqual:@0]) {
                [newUser incrementKey:@"receivedDownvotes"];
                self.votesDownLabel.text=[NSString stringWithFormat:@"%@",[newUser objectForKey:@"receivedDownvotes"]];
                [self.view setNeedsDisplay];
                [newUser saveInBackground];
            }
        }
    }else{
        if ([[self.currentUserObject objectForKey:@"isAdmin"]isEqual:@1]) {
            RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"Invalid vote!" message:@"You can't vote yourself!"];
            [modal show];
        }else{
            RNBlurModalView *modal = [[RNBlurModalView alloc] initWithViewController:self title:@"Invalid vote!" message:@"You already voted for this song!"];
            [modal show];
        }
    }
}

@end
