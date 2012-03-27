//
//  AppDelegate.m
//  DEW
//
//  Created by Admin on 26/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "Fluids.h"

@implementation AppDelegate

@synthesize window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ocp = [[ofxCocoaPlugins alloc] initWithAppDelegate:self];
    [ocp setNumberOutputviews:2];
    [ocp addHeader:@"Setup"];
    [ocp addPlugin:[[Keystoner alloc] initWithSurfaces:[NSArray arrayWithObjects:@"Floor", nil]] midiChannel:1];

    [ocp addHeader:@"DEW"];
    [ocp addPlugin:[[Fluids alloc] init] midiChannel:10];

    [ocp loadPlugins];

}

@end
