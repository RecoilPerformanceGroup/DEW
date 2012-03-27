#pragma once

#import <ofxCocoaPlugins/Plugin.h>
#import "MSAFluid.h"

using namespace MSA;

@interface Fluids : ofPlugin {
    ofImage * img;
    
    FluidSolver * fluids;
    FluidDrawerGl * fluidsDrawer;
    
    Vec2f lastControlMouse;
}

@end


