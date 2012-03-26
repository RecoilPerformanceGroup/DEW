//
//  AppDelegate.h
//  DEW
//
//  Created by Admin on 26/03/12.

#import <ofxCocoaPlugins/ofxCocoaPlugins.h>
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    ofxCocoaPlugins *ocp;
    NSWindow * window;
}

@property (assign) IBOutlet NSWindow *window;

@end
