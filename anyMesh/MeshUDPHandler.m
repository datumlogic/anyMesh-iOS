//
//  MeshUDPHandler.m
//  anyMesh
//
//  Created by David Paul on 4/28/14.
//  Copyright (c) 2014 dpTools. All rights reserved.
//

#import "MeshUDPHandler.h"
#import "MeshDeviceInfo.h"
#import "AnyMesh.h"
#import "MeshTCPServer.h"
#import "MeshTCPClient.h"

@implementation MeshUDPHandler
    
-(id)initWithBroadcastMessage:(NSString*)msg onPort:(int)thePort
{
    if (self = [super init]) {
        
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        port = thePort;
        message = [msg dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        if (![udpSocket bindToPort:port error:&error])
        {
            NSLog(@"Error starting server (bind): %@", error);
            return nil;
        }
        if (![udpSocket beginReceiving:&error])
        {
            [udpSocket close];
            
            NSLog(@"Error starting server (recv): %@", error);
            return nil;
        }
    }
    return self;
}

-(void)startBroadcasting
{
    broadcastTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(broadcast) userInfo:nil repeats:TRUE];
    [broadcastTimer fire];
}
-(void)broadcast
{
    [udpSocket sendData:message toHost:@"255.255.255.255" port:port withTimeout:-1 tag:0];
}

#pragma mark UDP Server Delegate
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    MeshDeviceInfo *deviceInfo = [[MeshDeviceInfo alloc] init];
    deviceInfo.ipAddress = [[NSString alloc] initWithData:address encoding:NSUTF8StringEncoding];
    
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    deviceInfo.name = dataDict[KEY_NAME];
    deviceInfo.listensTo = dataDict[KEY_LISTENSTO];
    
    [[AnyMesh sharedInstance].tcpClient connectTo:deviceInfo];
}

@end