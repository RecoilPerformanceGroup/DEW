#pragma once

#import <ofxCocoaPlugins/Plugin.h>
#import "MSAFluid.h"

using namespace MSA;

@interface Fluids : ofPlugin {
    ofImage * img;
    
    FluidSolver * fluids;
    FluidDrawerGl * fluidsDrawer;
    
    Vec2f lastControlMouse;
    NSColorWell *controlMouseColor;
    NSButton *controlMouseColorEnabled;
    NSButton *controlMouseForceEnabled;
    NSSlider *controlMouseForce;
}
@property (assign) IBOutlet NSButton *controlMouseColorEnabled;
@property (assign) IBOutlet NSColorWell *controlMouseColor;
@property (assign) IBOutlet NSButton *controlMouseForceEnabled;
@property (assign) IBOutlet NSSlider *controlMouseForce;

@end


