//
//  SonosController.m
//  Sonos Controller
//
//  Created by Axel Möller on 16/11/13.
//  Copyright (c) 2013 Appreviation AB. All rights reserved.
//

#import "SonosController.h"
#import "AFNetworking.h"
#import "XMLReader.h"
#import "User.h"
#import <Spotify/Spotify.h>

@interface SonosController()
- (void)upnp:(NSString *)url soap_service:(NSString *)soap_service soap_action:(NSString *)soap_action soap_arguments:(NSString *)soap_arguments completion:(void (^)(NSDictionary *, NSError *))block;
@end

@implementation SonosController
@synthesize ip, port, owner;

- (id)initWithIP:(NSString *)ip_ {
    return [self initWithIP:ip_ port:1400 owner:[[PFObject alloc]init]];
}

- (id)initWithIP:(NSString *)ip_ port:(int)port_ owner:(PFObject *)owner_{
    self = [super init];
    if (self) {
        self.ip = ip_;
        self.port = port_;
        if ([[owner_ objectForKey:@"isAdmin"]isEqual:@1]) {
            self.owner = owner_;
        }
    }
    return self;
}

- (void)upnp:(NSString *)url soap_service:(NSString *)soap_service soap_action:(NSString *)soap_action soap_arguments:(NSString *)soap_arguments completion:(void (^)(NSDictionary *, NSError *))block {
    
    // Create Body data
    NSMutableString *post_xml = [[NSMutableString alloc] init];
    [post_xml appendString:@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>"];
    [post_xml appendString:@"<s:Body>"];
    [post_xml appendFormat:@"<u:%@ xmlns:u='%@'>", soap_action, soap_service];
    [post_xml appendString:soap_arguments];
    [post_xml appendFormat:@"</u:%@>", soap_action];
    [post_xml appendString:@"</s:Body>"];
    [post_xml appendString:@"</s:Envelope>"];
    
    // Create HTTP Request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d%@", self.ip, self.port, url]]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:15.0];
    
    // Set headers
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%@#%@", soap_service, soap_action] forHTTPHeaderField:@"SOAPACTION"];
    
    // Set Body
    [request setHTTPBody:[post_xml dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(block) {
            NSDictionary *responseXML = [XMLReader dictionaryForXMLData:responseObject error:nil];
            NSLog(@"response xml: %@", responseXML);
            block(responseXML, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(block) block(nil, error);
    }];
    
    [requestOperation start];
}

- (void)play:(NSString *)track completion:(void (^)(NSDictionary *, NSError *))block {
    if(track) {
        [self
         upnp:@"/MediaRenderer/AVTransport/Control"
         soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
         soap_action:@"SetAVTransportURI"
         soap_arguments:[NSString stringWithFormat:@"<InstanceID>0</InstanceID><CurrentURI>%@</CurrentURI><CurrentURIMetaData></CurrentURIMetaData>", track]
         completion:^(id responseObject, NSError *error) {
            [self play:nil completion:block];
        }];
    } else {
        [self
         upnp:@"/MediaRenderer/AVTransport/Control"
         soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
         soap_action:@"Play"
         soap_arguments:@"<InstanceID>0</InstanceID><Speed>1</Speed>"
         completion:block];
    }
}

- (void)play:(NSString *)track URIMetaData:(NSString *)URIMetaData completion:(void (^)(NSDictionary *reponse, NSError *error))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"SetAVTransportURI"
     soap_arguments:[NSString stringWithFormat:@"<InstanceID>0</InstanceID><CurrentURI>%@</CurrentURI><CurrentURIMetaData>%@</CurrentURIMetaData>", track, URIMetaData]
     completion:^(id responseObject, NSError *error) {
         [self play:nil completion:block];
     }];
}

- (void)playSpotifyTrack:(NSString *)track completion:(void (^)(NSDictionary *reponse, NSError *error))block {
    
    NSString *trackEncoded = [track stringByReplacingOccurrencesOfString:@":" withString:@"%%3a"];
    NSString *trackURI = [NSString stringWithFormat:@"x-sonos-spotify:%@?sid=12&amp;flags=32", trackEncoded];
    
    NSString *metaData = [NSString stringWithFormat:
                          @"<DIDL-Lite xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:r\"urn:schemas-rinconnetworks-com:metadata-1-0\" xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\"> \
                          <item id=\"10030020%@\" parentID=\"\" restricted=\"true\"> \
                          <upnp:class>object.item.audioItem.musicTrack</upnp:class> \
                          <desc id=\"cdudn\" nameSpace=\"urn:schemas-rinconnetworks-com:metadata-1-0/\">SA_RINCON2311_X_#Svc2311-0-Token</desc> \
                          </item> \
                          </DIDL-Lite>", trackEncoded];
    
    metaData = [[[metaData stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    
    
    [self play:trackURI URIMetaData:metaData completion:block];
}

- (void)pause:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"Pause"
     soap_arguments:@"<InstanceID>0</InstanceID><Speed>1</Speed>"
     completion:block];
}

- (void)next:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"Next"
     soap_arguments:@"<InstanceID>0</InstanceID><Speed>1</Speed>"
     completion:block];
}

- (void)previous:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"Previous"
     soap_arguments:@"<InstanceID>0</InstanceID><Speed>1</Speed>"
     completion:block];
}

- (void)queue:(NSString *)track completion:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"AddURIToQueue"
     soap_arguments:[NSString stringWithFormat:@"<InstanceID>0</InstanceID><EnqueuedURI>%@</EnqueuedURI><EnqueuedURIMetaData></EnqueuedURIMetaData><DesiredFirstTrackNumberEnqueued>0</DesiredFirstTrackNumberEnqueued><EnqueueAsNext>1</EnqueueAsNext>", track]
     completion:block];
}

- (void)getVolume:(void (^)(NSInteger , NSError *))block {
    [self
     upnp:@"/MediaRenderer/RenderingControl/Control"
     soap_service:@"urn:schemas-upnp-org:service:RenderingControl:1"
     soap_action:@"GetVolume"
     soap_arguments:@"<InstanceID>0</InstanceID><Channel>Master</Channel>"
     completion:^(NSDictionary *responseXML, NSError *error) {
            NSString *value = responseXML[@"s:Envelope"][@"s:Body"][@"u:GetVolumeResponse"][@"CurrentVolume"][@"text"];
            if([value isEqualToString:@""])
                block(0, error);
            else
                block([value integerValue], nil);
    }];
}

- (void)setVolume:(NSInteger)volume completion:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/RenderingControl/Control"
     soap_service:@"urn:schemas-upnp-org:service:RenderingControl:1"
     soap_action:@"SetVolume"
     soap_arguments:[NSString stringWithFormat:@"<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>%ld</DesiredVolume>", (long)volume]
     completion:block];
}

- (void)getMute:(void (^)(NSNumber *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/RenderingControl/Control"
     soap_service:@"urn:schemas-upnp-org:service:RenderingControl:1"
     soap_action:@"GetMute"
     soap_arguments:@"<InstanceID>0</InstanceID><Channel>Master</Channel>"
     completion:^(NSDictionary *responseXML, NSError *error) {
         if(block) {
             if(error) block(nil, error);
             
             NSString *stateStr = responseXML[@"s:Envelope"][@"s:Body"][@"u:GetMuteResponse"][@"CurrentMute"][@"text"];
             BOOL state = [stateStr isEqualToString:@"1"] ? TRUE : FALSE;
             block([NSNumber numberWithBool:state], nil);
        }
     }];
}

- (void)setMute:(BOOL)mute completion:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/RenderingControl/Control"
     soap_service:@"urn:schemas-upnp-org:service:RenderingControl:1"
     soap_action:@"SetMute"
     soap_arguments:[NSString stringWithFormat:@"<InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>%d</DesiredMute>", mute]
     completion:block];
}

- (void)trackInfo:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"GetPositionInfo"
     soap_arguments:@"<InstanceID>0</InstanceID>"
     completion:^(NSDictionary *responseXML, NSError *error) {
         if(error) block(nil, error);
         
         // Create NSDictionary to return, clean up the data Sonos responds
         NSMutableDictionary *returnData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"RelTime"][@"text"], @"RelTime",
                                            responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"Track"][@"text"], @"Track",
                                            responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"TrackDuration"][@"text"], @"TrackDuration",
                                            responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"TrackURI"][@"text"], @"TrackURI",
                                            nil
                                            ];
         
         // Find metadata about streaming content
         if(responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"TrackMetaData"][@"text"] != nil) {
             NSDictionary *trackMetaData = [XMLReader dictionaryForXMLString:responseXML[@"s:Envelope"][@"s:Body"][@"u:GetPositionInfoResponse"][@"TrackMetaData"][@"text"] error:nil];
//             NSLog(@"Track metadata: %@", trackMetaData);
             
             // Figure out what kind of data is playing
             
             // Spotify:
             if([trackMetaData[@"DIDL-Lite"][@"item"][@"res"][@"protocolInfo"] isEqualToString:@"sonos.com-spotify:*:audio/x-spotify:*"]) {
                 
                 NSString *totalString=trackMetaData[@"DIDL-Lite"][@"item"][@"res"][@"text"];
                 NSString *newString=[[[totalString stringByReplacingOccurrencesOfString:@"x-sonos-spotify:" withString:@""] stringByReplacingOccurrencesOfString:@"%3a" withString:@":"]stringByReplacingOccurrencesOfString:@"?sid=12&flags=32" withString:@""];
                 NSString *trackURIString=[newString stringByReplacingOccurrencesOfString:@"spotify:track:" withString:@""];
                 
                 
                 //Set up the API Request
                 NSURLSession *session = [NSURLSession sharedSession];
                 NSString *URLString=[NSString stringWithFormat:@"https://api.spotify.com/v1/tracks/%@", trackURIString];
                 NSURL *spotifyGetURL = [NSURL URLWithString:URLString];
                 
                 NSURLSessionDataTask *get = [session dataTaskWithURL:spotifyGetURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                     
                     NSLog(@"Response: %@", response);
                     // Everytime we pull data from the API, we remove the data in Core data
                     
                     // Convert the JSON received from the API into an NSArray (of NSDictionaries)
                     NSDictionary *downloadedSongInfo = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                     
                     [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                         
                         [returnData addEntriesFromDictionary:@{@"MetaDataAlbumArtURI" : downloadedSongInfo[@"album"][@"images"][0][@"url"]}];
                        
                         block(returnData, error);
                    }];
                 }];
                 [returnData addEntriesFromDictionary:@{
                                                            @"MetaDataCreator" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:creator"][@"text"],
                                                            @"MetaDataTitle" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:title"][@"text"],
                                                            @"MetaDataAlbum" : trackMetaData[@"DIDL-Lite"][@"item"][@"upnp:album"][@"text"]
                                                            }];

                 [get resume];

             }
             
             // Pandora:
             if([trackMetaData[@"DIDL-Lite"][@"item"][@"res"][@"protocolInfo"] isEqualToString:@"pandora.com-pndrradio-http:*:audio/mpeg:*"]) {
                 [returnData addEntriesFromDictionary:@{
                                                        @"MetaDataCreator" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:creator"][@"text"],
                                                        @"MetaDataTitle" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:title"][@"text"],
                                                        @"MetaDataAlbum" : trackMetaData[@"DIDL-Lite"][@"item"][@"upnp:album"][@"text"],
                                                        @"MetaDataAlbumArtURI" : trackMetaData[@"DIDL-Lite"][@"item"][@"upnp:albumArtURI"][@"text"]
                                                        }];
             }

             
             // TuneIn Radio:
             if([trackMetaData[@"DIDL-Lite"][@"item"][@"res"][@"protocolInfo"] isEqualToString:@"aac:*:application/octet-stream:*"]) {
                 [returnData addEntriesFromDictionary:@{
                                                        @"MetaDataCreator" : @"",
                                                        @"MetaDataTitle" : trackMetaData[@"DIDL-Lite"][@"item"][@"r:streamContent"][@"text"],
                                                        @"MetaDataAlbum" : @"",
                                                        @"MetaDataAlbumArtURI" : @""
                                                        }];
             }
             
             // HTTP Streaming (?) SoundCloud returns this protocol for me
             if([trackMetaData[@"DIDL-Lite"][@"item"][@"res"][@"protocolInfo"] isEqualToString:@"sonos.com-http:*:audio/mpeg:*"]) {
                 [returnData addEntriesFromDictionary:@{
                                                        @"MetaDataCreator" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:creator"][@"text"],
                                                        @"MetaDataTitle" : trackMetaData[@"DIDL-Lite"][@"item"][@"dc:title"][@"text"],
                                                        @"MetaDataAlbum" : @"",
                                                        @"MetaDataAlbumArtURI" : trackMetaData[@"DIDL-Lite"][@"item"][@"upnp:albumArtURI"][@"text"]
                                                        }];
             }
         }
         
         if(block) block(returnData, nil);
     }];
}

- (void)mediaInfo:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"GetMediaInfo"
     soap_arguments:@"<InstanceID>0</InstanceID>"
     completion:block];
}

- (void)status:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaRenderer/AVTransport/Control"
     soap_service:@"urn:schemas-upnp-org:service:AVTransport:1"
     soap_action:@"GetTransportInfo"
     soap_arguments:@"<InstanceID>0</InstanceID>"
     completion:^(NSDictionary *responseXML, NSError *error) {
         if(block) {
             if(error) block(nil, error);
             NSDictionary *returnData = @{@"CurrentTransportState" : responseXML[@"s:Envelope"][@"s:Body"][@"u:GetTransportInfoResponse"][@"CurrentTransportState"][@"text"]};
             block(returnData, nil);
         }
     }];
}

- (void)browse:(void (^)(NSDictionary *, NSError *))block {
    [self
     upnp:@"/MediaServer/ContentDirectory/Control"
     soap_service:@"urn:schemas-upnp-org:service:ContentDirectory:1"
     soap_action:@"Browse"
     soap_arguments:@"<ObjectID>Q:0</ObjectID><BrowseFlag>BrowseDirectChildren</BrowseFlag><Filter>*</Filter><StartingIndex>0</StartingIndex><RequestedCount>0</RequestedCount><SortCriteria></SortCriteria>"
     completion:^(NSDictionary *responseXML, NSError *error) {
         if(block) {
             if(error) block(nil, error);
             NSMutableDictionary *returnData = [NSMutableDictionary dictionaryWithObjectsAndKeys:responseXML[@"s:Envelope"][@"s:Body"][@"u:BrowseResponse"][@"TotalMatches"][@"text"], @"TotalMatches", nil];
             
             NSDictionary *queue = [XMLReader dictionaryForXMLString:responseXML[@"s:Envelope"][@"s:Body"][@"u:BrowseResponse"][@"Result"][@"text"] error:nil];
             
             NSLog(@"Queue: %@", queue);
             
             NSMutableArray *queue_items = [NSMutableArray array];
             
             for(NSDictionary *queue_item in queue[@"DIDL-Lite"][@"item"]  ) {
                 // Spotify
                 if([queue_item[@"res"][@"protocolInfo"] isEqualToString:@"sonos.com-spotify:*:audio/x-spotify:*"]) {
                     NSDictionary *item = @{
                                            @"MetaDataCreator" : queue_item[@"dc:creator"][@"text"],
                                            @"MetaDataTitle" : queue_item[@"dc:title"][@"text"],
                                            @"MetaDataAlbum" : queue_item[@"upnp:album"][@"text"],
                                            @"MetaDataAlbumArtURI": queue_item[@"upnp:albumArtURI"][@"text"],
                                            @"MetaDataTrackURI": queue_item[@"res"][@"text"]};
                     [queue_items addObject:item];
                 }
                 
                 // HTTP Streaming (SoundCloud?)
                 if([queue_item[@"res"][@"protocolInfo"] isEqualToString:@"sonos.com-http:*:audio/mpeg:*"]) {
                     NSDictionary *item = @{
                                            @"MetaDataCreator" : queue_item[@"dc:creator"][@"text"],
                                            @"MetaDataTitle" : queue_item[@"dc:title"][@"text"],
                                            @"MetaDataAlbum" : @"",
                                            @"MetaDataAlbumArtURI" : queue_item[@"upnp:albumArtURI"][@"text"],
                                            @"MetaDataTrackURI" : queue_item[@"res"][@"text"]};
                     [queue_items addObject:item];
                 }
             }
             [returnData setObject:queue_items forKey:@"QueueItems"];
             block(returnData, nil);
         }
     }];
}

@end
